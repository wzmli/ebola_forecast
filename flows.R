library(macpan2)
library(shellpipes)
loadEnvironments()


flow = list(
	mp_per_capita_flow("S","E","beta_I * I / N","Incidence_I")
	, mp_per_capita_flow("S","E","beta_D * Dunsafe / N","Incidence_D")
	, mp_per_capita_flow("E","I","alpha","Progression")
	, mp_per_capita_flow("I","R","(1-mort)*gamma","Recovery")
	, mp_per_capita_flow("I","Dsafe","(mort)*(1-unsafe)/delta","Death_safe")
	, mp_per_capita_flow("I","Dunsafe","mort*unsafe/delta","Death_unsafe")
	, mp_per_capita_flow("Dunsafe","B","phi","Burial")
	, Incidence ~ Incidence_I + Incidence_D
	, cumIncidence ~ cumIncidence + Incidence
	, Death ~ Death_safe + Death_unsafe
)

default = list(beta_I = 0.4
	, beta_D = 0.5
	, alpha = 0.1
	, gamma = 0.1
	, delta = 5 ## death delay
	, phi = 0.1
	, unsafe = 0.3
	, mort = 0.4
	, effS = 0.005
	, N = 25.5e6
	, I = 1
	, E = 1
	, R = 0
	, Dunsafe = 0
	, Dsafe = 0
	, B = 0
	, cumIs = 0
	, cumIc = 0
	, prop_Is = 0.5
	, prop_Ic = 0.1
	, prop_Ds = 0.2
	, prop_Dc = 0.2
	, cumDs = 0
	, cumDc = 0
	, cumIncidence = 0
)	

initialize_state = list(N ~ effS*N
	, S ~ N - E - I - R - Dsafe - Dunsafe - B)

saveVars(flow, default, initialize_state)
