liquid_glycol_dict = Dict(
    "Density [kg.m3]" => 1115.,
    "Specific heat capacity [J.kg.K]" => 0.895,
    "Dynamic viscosity [Pa-s]" => 1.61e-2,
    "Thermal conductivity [W.m-K]" => 0.254,
)

novec_7000_dict = Dict(
    "Density [kg.m3]" => 1400,
    "Specific heat capacity [J.kg.K]" => 1300,
    "Dynamic viscosity [Pa-s]" => 0.00045,
    "Thermal conductivity [W.m-k]" => 0.075
)

novec_7100_dict = Dict(
    "Density [kg.m3]" => 1510,
    "Specific heat capacity [J.kg.K]" => 1183,
    "Dynamic viscosity [Pa-s]" => 0.00058,
    "Thermal conductivity [W.m-k]" => 0.069,
)

novec_7200_dict = Dict(
    "Density [kg.m3]" => 1430.,
    "Specific heat capacity" => 1214.172,
    "Dynamic viscosity [Pa-s]" => 0.00061,
    "Thermal conductivity [W.m-K]" => 0.0616
)

novec_7300_dict = Dict(
    "Density [kg.m3]" => 1660,
    "Specific heat capacity [J.kg.K]" => 1140,
    "Dynamic viscosity [Pa-s]" => 0.0018,
    "Thermal conductivity [W.m-k]" => 0.063,
)

novec_7500_dict = Dict(
    "Density [kg.m3]" => 1614.,
    "Specific heat capacity [J.kg.K]" => 1135.,
    "Dynamic viscosity [Pa-s]" => .00124,
    "Thermal conductivity [W.m-K]" => 0.065
)

novec_7600_dict = Dict(
    "Density [kg.m3]" => 1540,
    "Specific heat capacity [J.kg.K]" => 1319,
    "Dynamic viscosity [Pa-s]" => 0.00165,
    "Thermal conductivity [W.m-k]" => 0.071,
)

shell_e5_tm_410_dict = Dict(
    "Density [kg.m3]" => 802,
    "Specific heat capacity [J.kg.K]" => 2100,
    "Dynamic viscosity [Pa-s]" => 0.0105062,
    "Thermal conductivity [W.m-k]" => 0.143,
)

shell_sl_3326_dict = Dict(
    "Density [kg.m3]" => 782,
    "Specific heat capacity [J.kg.K]" => 2200,
    "Dynamic viscosity [Pa-s]" => 0.0043792,
    "Thermal conductivity [W.m-k]" => 0.145,
)

synfluid_pao_2_dict = Dict(
    "Density [kg.m3]" => 798,
    "Specific heat capacity [J.kg.K]" => 2203,
    "Dynamic viscosity [Pa-s]" => 0.00401394,
    "Thermal conductivity [W.m-k]" => 0.141,
)

synfluid_pao_4_dict = Dict(
    "Density [kg.m3]" => 819,
    "Specific heat capacity [J.kg.K]" => 2143,
    "Dynamic viscosity [Pa-s]" => 0.01374282,
    "Thermal conductivity [W.m-k]" => 0.15,
)

synfluid_pao_6_dict = Dict(
    "Density [kg.m3]" => 828,
    "Specific heat capacity [J.kg.K]" => 2028,
    "Dynamic viscosity [Pa-s]" => 0.02557692,
    "Thermal conductivity [W.m-k]" => 0.155,
)

mineral_oil_dict = Dict(
    "Density [kg.m3]" => 924.1,
    "Specific heat capacity [J.kg.K]" => 1900.,
    "Dynamic viscosity [Pa-s]" => 0.0517496,
    "Thermal conductivity [W.m-k]" => 0.13,
)

cargill_naturecool_2000_dict = Dict(
    "Density [kg.m3]" => 920.6,
    "Specific heat capacity [J.kg.K]" => 2308,
    "Dynamic viscosity [Pa-s]" => 0.0174914,
    "Thermal conductivity [W.m-k]" => 0.1644,
)

dow_syltherm_800_dict = Dict(
    "Density [kg.m3]" => 910,
    "Specific heat capacity [J.kg.K]" => 1600,
    "Dynamic viscosity [Pa-s]" => 0.006,
    "Thermal conductivity [W.m-k]" => 0.135,
)

dow_syltherm_hf_dict = Dict(
    "Density [kg.m3]" => 875,
    "Specific heat capacity [J.kg.K]" => 1625,
    "Dynamic viscosity [Pa-s]" => 0.0015,
    "Thermal conductivity [W.m-k]" => 0.105,
)

dow_syltherm_xlt_dict = Dict(
    "Density [kg.m3]" => 850,
    "Specific heat capacity [J.kg.K]" => 1800,
    "Dynamic viscosity [Pa-s]" => 0.0015,
    "Thermal conductivity [W.m-k]" => 0.11,
)

ef_ampcool_110_dict = Dict(
    "Density [kg.m3]" => 820,
    "Specific heat capacity [J.kg.K]" => 2212,
    "Dynamic viscosity [Pa-s]" => 0.0066502,
    "Thermal conductivity [W.m-k]" => 0.1359,
)

ef_ampcool_120_dict = Dict(
    "Density [kg.m3]" => 820,
    "Specific heat capacity [J.kg.K]" => 2206,
    "Dynamic viscosity [Pa-s]" => 0.01312,
    "Thermal conductivity [W.m-k]" => 0.1459,
)

ef_ampcool_130_dict = Dict(
    "Density [kg.m3]" => 820,
    "Specific heat capacity [J.kg.K]" => 2203,
    "Dynamic viscosity [Pa-s]" => 0.02952,
    "Thermal conductivity [W.m-k]" => 0.1508,
)

ef_ampcool_140_dict = Dict(
    "Density [kg.m3]" => 840,
    "Specific heat capacity [J.kg.K]" => 2191,
    "Dynamic viscosity [Pa-s]" => 0.05628,
    "Thermal conductivity [W.m-k]" => 0.1584,
)


water_dict = Dict(
    "Density [kg.m3]" => 997,
    "Specific heat capacity [J.kg.K]" => 4182,
    "Dynamic viscosity [Pa-s]" => 8.9e-4,
    "Thermal conductivity [W.m-K]" => 0.598
)
coolant_properties = Dict(
    "Novec 7000" => novec_7000_dict,
    "Novec 7100" => novec_7100_dict,
    "Novec 7200" => novec_7200_dict,
    "Novec 7300" => novec_7300_dict,
    "Novec 7500" => novec_7500_dict,
    "Novec 7600" => novec_7600_dict,
    "Shell E5 TM 410" => shell_e5_tm_410_dict,
    "Shell SL 3326" => shell_sl_3326_dict,
    "Synfluid PAO 2" => synfluid_pao_2_dict,
    "Synfluid PAO 4" => synfluid_pao_4_dict,
    "Synfluid PAO 6" => synfluid_pao_6_dict,
    "Mineral Oil" => mineral_oil_dict,
    "Cargill NatureCool 2000" => cargill_naturecool_2000_dict,
    "Dow SYLTHERM 800" => dow_syltherm_800_dict,
    "Dow SYLTHERM HF" => dow_syltherm_hf_dict,
    "Dow SYLTHERM XLT" => dow_syltherm_xlt_dict,
    "Engineered Fluids AmpCool 110" => ef_ampcool_110_dict,
    "Engineered Fluids AmpCool 120" => ef_ampcool_120_dict,
    "Engineered Fluids AmpCool 130" => ef_ampcool_130_dict,
    "Engineered Fluids AmpCool 140" => ef_ampcool_140_dict,
    "Liquid glycol" => liquid_glycol_dict,
    "Water" => water_dict
)