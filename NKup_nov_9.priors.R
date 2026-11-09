library(shellpipes)

fitregion <- "Nord-Kivu"

prior_range <- list(
	beta_I = c(0.03,0.05)
	, beta_D = c(0.03,0.8)
	, effS = c(0.0015,0.002)
#	, mort = c(0.05,0.15)
	, mort = c(0.45,0.5)
	, prop_Ic = c(0.5,0.6)
	, prop_Dc = c(0.5,0.7)
)

time_steps <- 700
firstdate <- as.Date("2026-08-18")
trimstart <- as.Date("2026-08-18")
#firstdate <- as.Date("2026-09-10")
#trimstart <- as.Date("2026-09-10")



trimend <- as.Date("2026-11-07")

plotstart <- as.Date("2026-05-15")
plotend <- trimend + 61


effS <- 0.008
#effS <- 0.01
delta <- 0.5
Npop <- 6e5
I0 <- 1
I0 <- 10
correction_date <- as.Date("2026-07-22")


nudge <- 12
extra_nudge <- 0
extra_nudge <- 0

case_correction <- 0

death_correction <- 0

saveEnvironment()

