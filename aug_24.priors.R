library(shellpipes)

prior_range <- list(
	beta_I = c(0.2,0.3)
	, beta_D = c(0.2,0.3)
	, effS = c(0.0015,0.002)
	, mort = c(0.4,0.5)
	, prop_Ic = c(0.303,0.36)
	, prop_Dc = c(0.4,0.5)
)

time_steps <- 300
firstdate <- as.Date("2025-12-01")
trimstart <- as.Date("2026-06-15")
trimend <- as.Date("2026-08-22")

plotstart <- as.Date("2026-05-15")
plotend <- trimend + 31


effS <- 0.002
Npop <- 115.5e6
Npop <- 25.5e6

correction_date <- as.Date("2026-07-22")


nudge <- 6
extra_nudge <- 3

case_correction <- 369
case_correction <- 369 + 800

death_correction <- 236
death_correction <- 236 + 50

saveEnvironment()

