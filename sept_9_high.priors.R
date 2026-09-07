library(shellpipes)

fitregion <- "DRC"

prior_range <- list(
	beta_I = c(0.05,0.8)
	, beta_D = c(0.05,0.1)
	, effS = c(0.0015,0.002)
#	, mort = c(0.05,0.15)
	, mort = c(0.5,0.55)
	, prop_Ic = c(0.303,0.36)
	, prop_Dc = c(0.5,0.7)
)



time_steps <- 300
firstdate <- as.Date("2025-12-01")
trimstart <- as.Date("2026-06-15")
trimend <- as.Date("2026-09-05")

plotstart <- as.Date("2026-05-15")
plotend <- trimend + 31


effS <- 0.0018
effS <- 0.0009
Npop <- 115.5e6
delta <- 0.5

correction_date <- as.Date("2026-07-22")


nudge <- 9
extra_nudge <- 3
#extra_nudge <- 0
#extra_nudge <- 0 - nudge

case_correction <- 369
case_correction <- 369 # + 850

death_correction <- 236 # + 200 

saveEnvironment()

