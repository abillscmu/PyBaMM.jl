using PyBaMM
using ProgressMeter
using Statistics
using Turing

#pybamm all lower case is the python module pybamm
pybamm = PyBaMM.pybamm
#pybamm2julia is the python module we will use to convert from pybamm to julia (duh)
pybamm2julia = PyBaMM.pybamm2julia


model = pybamm.lithium_ion.SPMe(name="DFN")
parameter_values = pybamm.ParameterValues("Chen2020")

#Define Pybamm Parameters
eps_p = pybamm.InputParameter("eps_p")
eps_n = pybamm.InputParameter("eps_n")
Q_Li = pybamm.InputParameter("Q_Li")

#these are psuedo
c0_n = pybamm2julia.PsuedoInputParameter("c0_n")
c0_p = pybamm2julia.PsuedoInputParameter("c0_p")

#Get default values
param = pybamm.LithiumIonParameters()
eps_p_init = pyconvert(Float64, parameter_values["Positive electrode active material volume fraction"])
eps_n_init = pyconvert(Float64, parameter_values["Negative electrode active material volume fraction"])
Q_Li_init = pyconvert(Float64, parameter_values.evaluate(param.Q_Li_particles_init))


parameter_values.update(
    PyDict(Dict(
        "Positive electrode active material volume fraction" => eps_p,
        "Negative electrode active material volume fraction" => eps_n,
        "Initial concentration in negative electrode [mol.m-3]" => c0_n,
        "Initial concentration in positive electrode [mol.m-3]" => c0_p,
    ))
)
sim = pybamm.Simulation(model, parameter_values=parameter_values)

inputs = OrderedDict{String,Float64}(
    "eps_p" => eps_p_init,
    "eps_n" => eps_n_init,
    "Q_Li" => Q_Li_init
)

input_parameter_order = [k for k in keys(inputs)]

# Build Simulation
sim.build()

####################################### Get Initial Conditions #######################################
#### Electrode SOH stuff
#get param object and OCV's
param = pybamm.LithiumIonParameters()
Un = param.n.prim.U
Up = param.p.prim.U

#begin building SOH model
esoh_model = pybamm.BaseModel()

#build equation for 100% soc
V_min = parameter_values.evaluate(param.voltage_low_cut)
V_max = parameter_values.evaluate(param.voltage_high_cut)
Q_n = parameter_values.process_symbol(param.n.Q_init)
Q_p = parameter_values.process_symbol(param.p.Q_init)

x_100 = pybamm.StateVector(pyslice(0,1))
y_100 = (Q_Li - x_100 * Q_n) / Q_p
Un_100 = Un(x_100, T_ref)
Up_100 = Up(y_100, T_ref)
esoh_model.algebraic[x_100] = Up_100 - Un_100 - V_max

#build equation for 0 soc
x_0 = pybamm.StateVector(pyslice(1,2))
Q = Q_n * (x_100 - x_0)
y_0 = y_100 + Q / Q_p
Un_0 = Un(x_0, T_ref)
Up_0 = Up(y_0, T_ref)
esoh_model.algebraic[x_0] = Up_0 - Un_0 - V_min

#build equation for soc
V_init = 4.2
soc = pybamm.StateVector(pyslice(2,3))
x = x_0 + soc * (x_100 - x_0)
y = y_0 - soc * (y_0 - y_100)
esoh_model.algebraic[soc] = Up(y, T_ref) - Un(x, T_ref) - V_init

#process model
parameter_values.process_model(esoh_model)
rhs = pybamm.numpy_concatenation(esoh_model.algebraic[x_100], esoh_model.algebraic[x_0], esoh_model.algebraic[soc])

#build julia function for the nonlinear problem
sv = pybamm.StateVector(pyslice(0,2))
initial_conc = pybamm2julia.PybammJuliaFunction([sv, eps_p, eps_n, Q_Li], rhs, "initial_conc_func", true)
initial_conc_converter = pybamm2julia.JuliaConverter(cache_type="dual", input_parameter_order=input_parameter_order)
initial_conc_converter.convert_tree_to_intermediate(initial_conc)
initial_conc_str = pyconvert(String, initial_conc_converter.build_julia_code())
initial_conc_func = runtime_eval(Meta.parse(initial_conc_str))

#### Electrode SOH stuff
#Using above, get initial concentrations
c0_p_expr = y*parameter_values["Maximum concentration in positive electrode [mol.m-3]"]
c0_n_expr = x*parameter_values["Maximum concentration in negative electrode [mol.m-3]"]

c0 = pybamm.numpy_concatenation(c0_p_expr, c0_n_expr)
c0_pbj = pybamm2julia.PybammJuliaFunction([sv, eps_p, eps_n, Q_Li], c0, "get_initial_concentrations", false)
c0_converter = pybamm2julia.JuliaConverter(cache_type = "dual", input_parameter_order = input_parameter_order)
c0_converter.convert_tree_to_intermediate(c0_pbj)
c0_str = c0_converter.build_julia_code()
#INPUTS: SOLUTION FROM NLP and p
#OUTPUTS: [c0_p, c0_n]
get_initial_concentrations = runtime_eval(Meta.parse(pyconvert(String, c0_str)))


#Function to get ics once we have c0_p and c0_n
ics = pybamm2julia.PybammJuliaFunction([eps_p, eps_n, c0_p, c0_n], sim.built_model.concatenated_initial_conditions, "ics", false)
ics_converter = pybamm2julia.JuliaConverter(input_parameter_order = input_parameter_order, preallocate=false)
ics_converter.convert_tree_to_intermediate(ics)
ics_str = ics_converter.build_julia_code()
#INPUTS: p, c0_p, c0_n
#OUTPUTS: u0
ics_func = runtime_eval(Meta.parse(pyconvert(String,ics_str)))

#### Now get the actual simulation
# Cell Model
cellconverter = pybamm2julia.JuliaConverter(cache_type = "dual", inplace=true, input_parameter_order=input_parameter_order)
cellconverter.convert_tree_to_intermediate(sim.built_model.concatenated_rhs)
cell_str = cellconverter.build_julia_code(funcname="wooo")
cell_str = pyconvert(String, cell_str)
cell! = eval(Meta.parse(cell_str))

# get_voltage
get_voltage = pybamm2julia.PybammJuliaFunction([sv, eps_n, eps_p], sim.built_model.variables["Terminal voltage [V]"], "get_voltage", false)
var_converter = pybamm2julia.JuliaConverter(inplace=false, input_parameter_order=input_parameter_order, cache_type="dual")
var_converter.convert_tree_to_intermediate(get_voltage)
var_str = var_converter.build_julia_code()
get_voltage = runtime_eval(Meta.parse(pyconvert(String,var_str)))




##### TEST SOLVE #####
p = [eps_p_init, eps_n_init, Q_Li_init]
test_vals = [0.9106121196114546, 0.026347301451411866, 1.0]

nlp = NonlinearProblem(initial_conc_func, test_vals, p=p)
sol = solve(nlp, NewtonRaphson())

c0s = get_initial_concentrations(sol.u, p)

c0_p = c0s[1]
c0_n = c0s[2]

ics = ics_func(p, c0_p, c0_n)

prob = ODEProblem(cell!, ics, (0., 100.), p)
sol = solve(prob, QNDF())

for i in 1:length(sol.t)
    voltage[i] = get_voltage(sol.u[i], p)[1]
end

