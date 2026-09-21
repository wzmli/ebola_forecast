library(shellpipes)

fitregion <- "Haut-Uele"

prior_range <- list(
	beta_I = c(0.05,0.08)
	, beta_D = c(0.05,0.08)
	, effS = c(0.0015,0.002)
#	, mort = c(0.05,0.15)
	, mort = c(0.45,0.5)
	, prop_Ic = c(0.3,0.5)
	, prop_Dc = c(0.5,0.7)
)

time_steps <- 500
firstdate <- as.Date("2026-07-01")
trimstart <- as.Date("2026-07-17")
trimend <- as.Date("2026-09-18")

plotstart <- as.Date("2026-05-15")
plotend <- trimend + 31


effS <- 0.0005
delta <- 0.5
Npop <- 2.5e6

correction_date <- as.Date("2026-07-22")


nudge <- 5
extra_nudge <- 20
extra_nudge <- 0

case_correction <- 369
case_correction <- 369 # + 800
case_correction <- 0 # + 800

death_correction <- 236
death_correction <- 236 # + 50
death_correction <- 0 # + 50

saveEnvironment()

