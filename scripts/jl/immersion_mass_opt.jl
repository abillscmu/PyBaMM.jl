using PyBaMM
using ProgressMeter
using Statistics
using LinearSolve
using LinearSolveCUDA

pybamm = PyBaMM.pybamm
pack = PyBaMM.pack
pybamm2julia = PyBaMM.pybamm2julia
setup_circuit = PyBaMM.setup_circuit
setup_thermal_graph = PyBaMM.setup_thermal_graph

Np = 5
Ns = 5
λ = 100
curr = 160
t = 0.0
functional = true
voltage_functional = true

options = pydict(Dict("thermal" => "lumped"))


parameter_values = pybamm.ParameterValues("Marquis2019")

#make it an 18650
parameter_values["Electrode height [m]"] = 5.8e-2
parameter_values["Electrode width [m]"] = 61.5e-2*2
parameter_values["Ambient temperature [K]"] = 305.
parameter_values["Initial temperature [K]"] = 305.


experiment = pybamm.Experiment(["Discharge at $(28*Np*Ns) W for 75 sec", "Discharge at $(8*Np*Ns) W for 800 sec", "Discharge at $(28*Np*Ns) W for 105 sec", "Rest for 300 sec"]) #2C


options = pydict(Dict("thermal" => "lumped"))
model = pybamm.lithium_ion.SPMe(name="DFN", options=options)
#parameter_values = model.default_parameter_values

netlist = setup_circuit.setup_circuit(Np, Ns, I=curr)  
circuit_graph = setup_circuit.process_netlist_from_liionpack(netlist) 

#Cooling System Parameters
h_cell = 0.065 #18650
a = 1.25
D_cell = 0.018
W_pack = Np*a*D_cell
H_pack = h_cell
L_pack = D_cell*a*Ns
A_inlet = W_pack*H_pack
COP = 1.0
ṁ = 0.01
Δx = a*D_cell

coolant = "Novec 7500" 

#Coolant Properties
ρ = PyBaMM.coolant_properties[coolant]["Density [kg.m3]"]
cₚ = PyBaMM.coolant_properties[coolant]["Specific heat capacity [J.kg.K]"]
μ = PyBaMM.coolant_properties[coolant]["Dynamic viscosity [Pa-s]"]
κₜ = PyBaMM.coolant_properties[coolant]["Thermal conductivity [W.m-K]"]


#Fluids numbers 
u_mean = ṁ/(A_inlet*ρ)
u_max = ((a - 1)/a)*u_mean
Dₕ = D_cell
Re = ρ*u_max*Dₕ/μ
println("reynolds number is $Re")
Pr_f = cₚ*μ/κₜ

Nu = PyBaMM.nusselt_mixed(false, 1, Re, Pr_f, Pr_f)
h = Nu*κₜ/Dₕ

#Peclet Number
α = κₜ/(ρ*cₚ)
Pe = Δx*(ṁ/(ρ*A_inlet))/α


thermal_pipe = setup_thermal_graph.ForcedConvectionGraph(circuit_graph, mdot=ṁ, cp=cₚ, T_i=305., h=h, A_cooling=A_inlet, rho=ρ, deltax = Δx, A=pyconvert(Float64, model.default_parameter_values["Cell cooling surface area [m2]"]))
thermal_pipe_graph = thermal_pipe.thermal_graph

if Re >= 2000
    error("turbulent flow not supported")
else
    fd = 84/Re
end


pybamm_pack = pack.Pack(
    model, 
    circuit_graph, 
    functional=functional, 
    thermals=thermal_pipe, 
    voltage_functional=voltage_functional, 
    operating_mode = experiment, 
    parameter_values=parameter_values,
    initial_soc = 1.0
)

println("compiling pack...")
pybamm_pack.build_pack()
println("finished compiling pack...")

if voltage_functional
    voltageconverter = pybamm2julia.JuliaConverter(cache_type = "symbolic", inplace=true)
    voltageconverter.convert_tree_to_intermediate(pybamm_pack.voltage_func)
    voltage_str = voltageconverter.build_julia_code()
    voltage_str = pyconvert(String, voltage_str)
    voltage_func = eval(Meta.parse(voltage_str))
else
    voltage_str = ""
end


timescale = 1
cellconverter = pybamm2julia.JuliaConverter(cache_type = "symbolic", inplace=true)
cellconverter.convert_tree_to_intermediate(pybamm_pack.cell_model)
cell_str = cellconverter.build_julia_code()
cell_str = pyconvert(String, cell_str)
cell! = eval(Meta.parse(cell_str))



myconverter = pybamm2julia.JuliaConverter(cache_type = "symbolic", override_psuedo=true)
myconverter.convert_tree_to_intermediate(pybamm_pack.pack)
pack_str = myconverter.build_julia_code()

forcing_function = pybamm_pack.forcing_functions[0]
forcing_converter = pybamm2julia.JuliaConverter(cache_type = "symbolic")
forcing_converter.convert_tree_to_intermediate(forcing_function)
forcing_str = forcing_converter.build_julia_code()
forcing_str = pyconvert(String,forcing_str)

forcing_function = eval(Meta.parse(forcing_str))

icconverter = pybamm2julia.JuliaConverter(override_psuedo = true)
icconverter.convert_tree_to_intermediate(pybamm_pack.ics)
ic_str = icconverter.build_julia_code()

u0 = eval(Meta.parse(pyconvert(String,ic_str)))
jl_vec = u0()

pack_str = pyconvert(String, pack_str)
jl_func = eval(Meta.parse(pack_str))

dy = similar(jl_vec)

println("building jacobian sparsity...")
jac_sparsity = float(Symbolics.jacobian_sparsity((du,u)->jl_func(du,u,nothing,t),dy,jl_vec))
println("done building jacobian sparsity...")


if voltage_functional
    voltageconverter = pybamm2julia.JuliaConverter(cache_type = "dual", inplace=true)
    voltageconverter.convert_tree_to_intermediate(pybamm_pack.voltage_func)
    voltage_str = voltageconverter.build_julia_code()
    voltage_str = pyconvert(String, voltage_str)
    voltage_func = eval(Meta.parse(voltage_str))
else
    voltage_str = ""
end

cellconverter = pybamm2julia.JuliaConverter(cache_type = "dual", inplace=true)
cellconverter.convert_tree_to_intermediate(pybamm_pack.cell_model)
cell_str = cellconverter.build_julia_code()
cell_str = pyconvert(String, cell_str)
cell! = eval(Meta.parse(cell_str))

myconverter = pybamm2julia.JuliaConverter(cache_type = "dual", override_psuedo=true)
myconverter.convert_tree_to_intermediate(pybamm_pack.pack)
pack_str = myconverter.build_julia_code()

forcing_function = pybamm_pack.forcing_functions[0]
forcing_converter = pybamm2julia.JuliaConverter(cache_type = "dual")
forcing_converter.convert_tree_to_intermediate(forcing_function)
forcing_str = forcing_converter.build_julia_code()
forcing_str = pyconvert(String,forcing_str)

forcing_function = eval(Meta.parse(forcing_str))

pack_voltage_index = Np + 1
pack_voltage = 1.0
jl_vec[1:Np] .=  curr./Np
jl_vec[pack_voltage_index] = 4 * Ns

pack_str = pyconvert(String, pack_str)
jl_func = eval(Meta.parse(pack_str))

#build mass matrix.
pack_eqs = falses(pyconvert(Int,pybamm_pack.len_pack_eqs))

cell_rhs = trues(pyconvert(Int,pybamm_pack.len_cell_rhs))
cell_algebraic = falses(pyconvert(Int,pybamm_pack.len_cell_algebraic))
cells = repeat(vcat(cell_rhs,cell_algebraic),pyconvert(Int, pybamm_pack.num_cells))
thermals = trues(pyconvert(Int,pybamm_pack.len_thermal_eqs))
differential_vars = vcat(pack_eqs, cells, thermals)
mass_matrix = sparse(diagm(differential_vars))




println("building function")
func = ODEFunction(jl_func, mass_matrix=mass_matrix, jac_prototype=jac_sparsity)
prob = ODEProblem(func, jl_vec, (0.0, 1080.0), nothing)
println("problem done")

println("initializing")
integrator = init(prob, QNDF(linsolve=KLUFactorization(), concrete_jac=true), save_everystep = true, dtmax = 1.0)
println("done initializing, cycling...")
@showprogress "cycling..." for i in 1:length(experiment.operating_conditions)
    forcing_function = pybamm_pack.forcing_functions[i-1]
    termination_function = pybamm_pack.termination_functions[i-1]

    forcing_converter = pybamm2julia.JuliaConverter(cache_type = "dual")
    forcing_converter.convert_tree_to_intermediate(forcing_function)
    forcing_str = forcing_converter.build_julia_code()
    forcing_str = pyconvert(String,forcing_str)

    forcing_function = eval(Meta.parse(forcing_str))
    
    termination_converter = pybamm2julia.JuliaConverter(cache_type = "dual")
    termination_converter.convert_tree_to_intermediate(termination_function)
    termination_str = termination_converter.build_julia_code()
    termination_str = pyconvert(String, termination_str)

    termination_function = eval(Meta.parse(termination_str))

    done = false
    start_t = integrator.t
    while !done
        step!(integrator)
        done = any((Base.@invokelatest termination_function(integrator.u, (integrator.t - start_t))).<0)
    end
    savevalues!(integrator)
end


Eu = PyBaMM.euler_inline(Re, a)
Δp = Eu*0.5*ρ*u_max*u_max*Ns
P_pump = Δp * ṁ
T_in = 298.0
T_out = sol[end][end]
P_fridge = ṁ*cₚ*(T_out - T_in)/COP


figure(1)
clf()
plot(integrator.sol.t, integrator.sol[end-4:end, :]')
xlabel("Time [s]")
ylabel("Fluid temperature [K]")
legend(["Row 1", "Row 2", "Row 3", "Row 4", "Row 5"])
savefig("immersion.pdf")