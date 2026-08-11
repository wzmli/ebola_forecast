## ============================================================
## SIR model with a piecewise time-varying beta, using macpan2's
## built-in time_var() engine function (no manual segmenting),
## plotted with ggplot2
## ============================================================

## --- 0. Setup -------------------------------------------------
## Install macpan2 if you don't already have it:
# install.packages(
#   "macpan2",
#   repos = c("https://canmod.r-universe.dev", "https://cloud.r-project.org")
# )
# install.packages(c("dplyr", "ggplot2"))

library(macpan2)
library(dplyr)
library(ggplot2)

state_labels <- c("S", "I", "R")
time_steps   <- 50
gamma        <- 0.2   # per-capita recovery rate (constant)

## --- 1. Piecewise beta schedule ---------------------------------
## beta_changepoints: time steps at which beta changes. MUST start
## at 0 (macpan2::time_var currently requires this -- see
## ?time_var / the "Piecewise Time Variation" vignette).
## beta_values: the value beta takes from each changepoint onward.
beta_changepoints <- c(0, 10, 25, 35)
beta_values       <- c(0.80, 0.15, 0.55, 0.10)

## --- 2. Build the SIR spec with a time_var()-driven beta ----------
## time_var(beta_values, beta_changepoints) looks at the current
## time step and returns the appropriate entry of beta_values --
## this replaces the need to re-simulate segment by segment.
piecewise_spec <- (
  mp_tmb_library("starter_models", "sir", package = "macpan2")
  |> mp_tmb_insert(
      phase = "during"
    , at = 1L               # update beta before anything else each iteration
    , expressions = list(beta ~ time_var(beta_values, beta_changepoints))
    , default = list(
        beta        = beta_values[1]  # placeholder; overwritten immediately
      , gamma       = gamma
      , beta_values = beta_values
      )
    , integers = list(beta_changepoints = beta_changepoints)
  )
)

print(piecewise_spec)

## --- 3. Simulate ---------------------------------------------------
piecewise_simulator <- mp_simulator(
  piecewise_spec,
  time_steps = time_steps,
  outputs = c(state_labels, "beta","infection")
)

sim_data <- mp_trajectory(piecewise_simulator)

gg <- (ggplot(sim_data, aes(time,value))
	+ geom_line()
	+ facet_wrap(~matrix,scale="free")
)

print(gg)

