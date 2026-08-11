library(shellpipes)

prior_range <- list(
	beta_I = c(0.1,0.4)
	, beta_D = c(0.1,0.4)
	, effS = c(0.0015,0.002)
	, mort = c(0.35,0.4)
	, prop_Ic = c(0.303,0.36)
	, prop_Dc = c(0.4,0.5)
)



time_steps <- 300
firstdate <- as.Date("2025-12-01")
trimstart <- as.Date("2026-06-15")
trimend <- as.Date("2026-08-09")

effS <- 0.003

correction_date <- as.Date("2026-07-22")


nudge <- 9
extra_nudge <- 5

case_correction <- 369

death_correction <- 236

saveEnvironment()

