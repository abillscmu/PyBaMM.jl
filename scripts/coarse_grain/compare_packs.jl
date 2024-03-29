using PyBaMM
using BenchmarkTools

pybamm = PyBaMM.pybamm
pack = pyimport("pack")
pybamm2julia = PyBaMM.pybamm2julia
setup_circuit = PyBaMM.setup_circuit
parameter_values = pybamm.ParameterValues("Chen2020")
Np = 3
Ns = 3
curr = 15.0
p = nothing 
t = 0.0
functional = true
options = Dict("thermal" => "lumped")
model = pybamm.lithium_ion.DFN(name="DFN", options=options)
netlist = setup_circuit.setup_circuit(Np, Ns, I=curr)   
pybamm_pack = pack.Pack(
    model,
    netlist, 
    functional=functional,
    voltage_functional=true, 
    thermal=true,
    parameter_values=parameter_values
    )
pybamm_pack.build_pack()
timescale = pyconvert(Float64,pybamm_pack.timescale.evaluate())
cellconverter = pybamm2julia.JuliaConverter(cache_type = "symbolic", inplace=true)
cellconverter.convert_tree_to_intermediate(pybamm_pack.cell_model)
cell_str = cellconverter.build_julia_code()
cell_str = pyconvert(String, cell_str)
cell! = eval(Meta.parse(cell_str))

voltageconverter = pybamm2julia.JuliaConverter(cache_type = "symbolic", inplace=true)
voltageconverter.convert_tree_to_intermediate(pybamm_pack.voltage_func)
voltage_str = voltageconverter.build_julia_code()
voltage_str = pyconvert(String, voltage_str)
voltage_func = eval(Meta.parse(voltage_str))

myconverter = pybamm2julia.JuliaConverter(cache_type = "symbolic")
myconverter.convert_tree_to_intermediate(pybamm_pack.pack)
pack_str = myconverter.build_julia_code()

icconverter = pybamm2julia.JuliaConverter(override_psuedo = true)
icconverter.convert_tree_to_intermediate(pybamm_pack.ics)
ic_str = icconverter.build_julia_code()

u0 = eval(Meta.parse(pyconvert(String,ic_str)))
jl_vec = u0()

pack_str = pyconvert(String, pack_str)
jl_func = eval(Meta.parse(pack_str))

dy = similar(jl_vec)

jac_sparsity = float(Symbolics.jacobian_sparsity((du,u)->jl_func(du,u,p,t),dy,jl_vec))

cellconverter = pybamm2julia.JuliaConverter(cache_type = "dual", inplace=true)
cellconverter.convert_tree_to_intermediate(pybamm_pack.cell_model)
cell_str = cellconverter.build_julia_code()
cell_str = pyconvert(String, cell_str)
cell! = eval(Meta.parse(cell_str))

voltageconverter = pybamm2julia.JuliaConverter(cache_type = "dual", inplace=true)
voltageconverter.convert_tree_to_intermediate(pybamm_pack.voltage_func)
voltage_str = voltageconverter.build_julia_code()
voltage_str = pyconvert(String, voltage_str)
voltage_func = eval(Meta.parse(voltage_str))

myconverter = pybamm2julia.JuliaConverter(cache_type = "dual")
myconverter.convert_tree_to_intermediate(pybamm_pack.pack)
pack_str = myconverter.build_julia_code()

pack_voltage_index = Np + 1
pack_voltage = 1.0
jl_vec[1:Np] .=  curr
jl_vec[pack_voltage_index] = pack_voltage

pack_str = pyconvert(String, pack_str)
jl_func = eval(Meta.parse(pack_str))

#build mass matrix.
pack_eqs = falses(pyconvert(Int,pybamm_pack.len_pack_eqs))

cell_rhs = trues(pyconvert(Int,pybamm_pack.len_cell_rhs))
cell_algebraic = falses(pyconvert(Int,pybamm_pack.len_cell_algebraic))
cells = repeat(vcat(cell_rhs,cell_algebraic),pyconvert(Int, pybamm_pack.num_cells))
differential_vars = vcat(pack_eqs,cells)
mass_matrix = sparse(diagm(differential_vars))
func = ODEFunction(jl_func, mass_matrix=mass_matrix,jac_prototype=jac_sparsity)
prob = ODEProblem(func, jl_vec, (0.0, 3600/timescale), nothing)

dfn_sol = solve(prob, QNDF(linsolve=KLUFactorization(),concrete_jac=true))


model = pybamm.lithium_ion.SPMe(name="SPMe", options=options)
netlist = setup_circuit.setup_circuit(Np, Ns, I=curr)
parameter_values = pybamm.ParameterValues("Chen2020")

pybamm_pack = pack.Pack(
    model,
    netlist, 
    functional=functional,
    voltage_functional=true, 
    thermal=true,
    parameter_values=parameter_values
    )
pybamm_pack.build_pack()
timescale = pyconvert(Float64,pybamm_pack.timescale.evaluate())
cellconverter = pybamm2julia.JuliaConverter(cache_type = "symbolic", inplace=true)
cellconverter.convert_tree_to_intermediate(pybamm_pack.cell_model)
cell_str = cellconverter.build_julia_code()
cell_str = pyconvert(String, cell_str)
cell! = eval(Meta.parse(cell_str))

voltageconverter = pybamm2julia.JuliaConverter(cache_type = "symbolic", inplace=true)
voltageconverter.convert_tree_to_intermediate(pybamm_pack.voltage_func)
voltage_str = voltageconverter.build_julia_code()
voltage_str = pyconvert(String, voltage_str)
voltage_func = eval(Meta.parse(voltage_str))

myconverter = pybamm2julia.JuliaConverter(cache_type = "symbolic")
myconverter.convert_tree_to_intermediate(pybamm_pack.pack)
pack_str = myconverter.build_julia_code()

icconverter = pybamm2julia.JuliaConverter(override_psuedo = true)
icconverter.convert_tree_to_intermediate(pybamm_pack.ics)
ic_str = icconverter.build_julia_code()

u0 = eval(Meta.parse(pyconvert(String,ic_str)))
jl_vec = u0()

pack_str = pyconvert(String, pack_str)
jl_func = eval(Meta.parse(pack_str))

dy = similar(jl_vec)

jac_sparsity = float(Symbolics.jacobian_sparsity((du,u)->jl_func(du,u,p,t),dy,jl_vec))

cellconverter = pybamm2julia.JuliaConverter(cache_type = "dual", inplace=true)
cellconverter.convert_tree_to_intermediate(pybamm_pack.cell_model)
cell_str = cellconverter.build_julia_code()
cell_str = pyconvert(String, cell_str)
cell! = eval(Meta.parse(cell_str))

voltageconverter = pybamm2julia.JuliaConverter(cache_type = "dual", inplace=true)
voltageconverter.convert_tree_to_intermediate(pybamm_pack.voltage_func)
voltage_str = voltageconverter.build_julia_code()
voltage_str = pyconvert(String, voltage_str)
voltage_func = eval(Meta.parse(voltage_str))

myconverter = pybamm2julia.JuliaConverter(cache_type = "dual")
myconverter.convert_tree_to_intermediate(pybamm_pack.pack)
pack_str = myconverter.build_julia_code()

pack_voltage_index = Np + 1
pack_voltage = 1.0
jl_vec[1:Np] .=  curr
jl_vec[pack_voltage_index] = pack_voltage

pack_str = pyconvert(String, pack_str)
jl_func = eval(Meta.parse(pack_str))

#build mass matrix.
pack_eqs = falses(pyconvert(Int,pybamm_pack.len_pack_eqs))

cell_rhs = trues(pyconvert(Int,pybamm_pack.len_cell_rhs))
cell_algebraic = falses(pyconvert(Int,pybamm_pack.len_cell_algebraic))
cells = repeat(vcat(cell_rhs,cell_algebraic),pyconvert(Int, pybamm_pack.num_cells))
differential_vars = vcat(pack_eqs,cells)
mass_matrix = sparse(diagm(differential_vars))
func = ODEFunction(jl_func, mass_matrix=mass_matrix,jac_prototype=jac_sparsity)
prob = ODEProblem(func, jl_vec, (0.0, 3600/timescale), nothing)

spme_sol = solve(prob, QNDF(linsolve=KLUFactorization(),concrete_jac=true))


######

model = pybamm.lithium_ion.SPM(name="SPM", options=options)
netlist = setup_circuit.setup_circuit(Np, Ns, I=curr)
parameter_values = pybamm.ParameterValues("Chen2020")   
pybamm_pack = pack.Pack(
    model,
    netlist, 
    functional=functional,
    voltage_functional=true, 
    thermal=true,
    parameter_values=parameter_values
    )
pybamm_pack.build_pack()
timescale = pyconvert(Float64,pybamm_pack.timescale.evaluate())
cellconverter = pybamm2julia.JuliaConverter(cache_type = "symbolic", inplace=true)
cellconverter.convert_tree_to_intermediate(pybamm_pack.cell_model)
cell_str = cellconverter.build_julia_code()
cell_str = pyconvert(String, cell_str)
cell! = eval(Meta.parse(cell_str))

voltageconverter = pybamm2julia.JuliaConverter(cache_type = "symbolic", inplace=true)
voltageconverter.convert_tree_to_intermediate(pybamm_pack.voltage_func)
voltage_str = voltageconverter.build_julia_code()
voltage_str = pyconvert(String, voltage_str)
voltage_func = eval(Meta.parse(voltage_str))

myconverter = pybamm2julia.JuliaConverter(cache_type = "symbolic")
myconverter.convert_tree_to_intermediate(pybamm_pack.pack)
pack_str = myconverter.build_julia_code()

icconverter = pybamm2julia.JuliaConverter(override_psuedo = true)
icconverter.convert_tree_to_intermediate(pybamm_pack.ics)
ic_str = icconverter.build_julia_code()

u0 = eval(Meta.parse(pyconvert(String,ic_str)))
jl_vec = u0()

pack_str = pyconvert(String, pack_str)
jl_func = eval(Meta.parse(pack_str))

dy = similar(jl_vec)

jac_sparsity = float(Symbolics.jacobian_sparsity((du,u)->jl_func(du,u,p,t),dy,jl_vec))

cellconverter = pybamm2julia.JuliaConverter(cache_type = "dual", inplace=true)
cellconverter.convert_tree_to_intermediate(pybamm_pack.cell_model)
cell_str = cellconverter.build_julia_code()
cell_str = pyconvert(String, cell_str)
cell! = eval(Meta.parse(cell_str))

voltageconverter = pybamm2julia.JuliaConverter(cache_type = "dual", inplace=true)
voltageconverter.convert_tree_to_intermediate(pybamm_pack.voltage_func)
voltage_str = voltageconverter.build_julia_code()
voltage_str = pyconvert(String, voltage_str)
voltage_func = eval(Meta.parse(voltage_str))

myconverter = pybamm2julia.JuliaConverter(cache_type = "dual")
myconverter.convert_tree_to_intermediate(pybamm_pack.pack)
pack_str = myconverter.build_julia_code()

pack_voltage_index = Np + 1
pack_voltage = 1.0
jl_vec[1:Np] .=  curr
jl_vec[pack_voltage_index] = pack_voltage

pack_str = pyconvert(String, pack_str)
jl_func = eval(Meta.parse(pack_str))

#build mass matrix.
pack_eqs = falses(pyconvert(Int,pybamm_pack.len_pack_eqs))

cell_rhs = trues(pyconvert(Int,pybamm_pack.len_cell_rhs))
cell_algebraic = falses(pyconvert(Int,pybamm_pack.len_cell_algebraic))
cells = repeat(vcat(cell_rhs,cell_algebraic),pyconvert(Int, pybamm_pack.num_cells))
differential_vars = vcat(pack_eqs,cells)
mass_matrix = sparse(diagm(differential_vars))
func = ODEFunction(jl_func, mass_matrix=mass_matrix,jac_prototype=jac_sparsity)
prob = ODEProblem(func, jl_vec, (0.0, 3600/timescale), nothing)

spm_sol = solve(prob, QNDF(linsolve=KLUFactorization(),concrete_jac=true))



