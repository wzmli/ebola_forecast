library(shellpipes)

prior_range <- list(
	beta_I = c(0.25,0.3)
	, beta_D = c(0.25,0.3)
	, effS = c(0.0015,0.002)
	, mort = c(0.35,0.4)
	, prop_Ic = c(0.303,0.36)
	, prop_Dc = c(0.4,0.5)
)

saveVars(prior_range)
