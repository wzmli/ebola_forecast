library(shellpipes)

fitregion <- "Nord-Kivu"

prior_range <- list(
	beta_I = c(0.15,0.2)
	, beta_D = c(0.2,0.3)
	, effS = c(0.0015,0.002)
#	, mort = c(0.05,0.15)
	, mort = c(0.45,0.5)
	, prop_Ic = c(0.5,0.6)
	, prop_Dc = c(0.5,0.7)
)

time_steps <- 700
firstdate <- as.Date("2026-08-10")
trimstart <- as.Date("2026-08-10")
trimend <- as.Date("2026-10-25")

plotstart <- as.Date("2026-05-15")
plotend <- trimend + 31


effS <- 0.01
delta <- 0.5
Npop <- 3e5
I0 <- 1
correction_date <- as.Date("2026-07-22")


nudge <- 11
extra_nudge <- 0
extra_nudge <- 10

case_correction <- 0

death_correction <- 0

saveEnvironment()

