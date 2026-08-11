## ============================================================
## SIR model with a time-varying, piecewise-constant beta
## simulated in macpan2, plotted with ggplot2
## ============================================================

## --- 0. Setup -------------------------------------------------
## Install macpan2 if you don't already have it:
# install.packages(
#   "macpan2",
#   repos = c("https://canmod.r-universe.dev", "https://cloud.r-project.org")
# )
# install.packages(c("dplyr", "tidyr", "ggplot2", "patchwork"))

library(macpan2)
library(dplyr)
library(tidyr)
library(ggplot2)
library(patchwork)   # for stacking the beta panel under the SIR panel

## --- 1. Base SIR model spec ------------------------------------
## This pulls the standard SIR model that ships with macpan2:
##   before:  S ~ N - I - R
##   during:  infection ~ S * (beta * I / N); S -> I
##            recovery  ~ gamma * I;          I -> R
sir_spec <- mp_tmb_library("starter_models", "sir", package = "macpan2")

## --- 2. Define the piecewise-constant beta schedule -------------
## Each row is one "regime": how many time steps it lasts, and the
## value of beta during that regime. Edit these freely.
segments <- tibble::tibble(
  segment  = 1:4,
  duration = c(20, 20, 15, 15),     # time steps in each regime
  beta     = c(0.45, 0.12, 0.30, 0.08)
)

## Fixed parameters shared across all segments
gamma <- 0.10
N0    <- 1000
I0    <- 5
R0    <- 0

## --- 3. Simulate segment-by-segment, carrying state forward -----
## We re-simulate a short window with mp_simulator() for each
## regime, using mp_tmb_insert() to set that regime's beta and the
## initial conditions (which are the previous regime's endpoint).
state    <- list(I = I0, R = R0)   # S is computed from N - I - R
t_offset <- 0
traj_list <- vector("list", nrow(segments))

for (i in seq_len(nrow(segments))) {

  seg <- segments[i, ]

  spec_i <- mp_tmb_insert(
    sir_spec,
    default = list(
      N     = N0,
      I     = state$I,
      R     = state$R,
      beta  = seg$beta,
      gamma = gamma
    )
  )

  sim_i <- mp_simulator(
    spec_i,
    time_steps = seg$duration,
    outputs = c("S", "I", "R", "infection")
  )

  out_i <- mp_trajectory(sim_i) |>
    mutate(
      time    = time + t_offset,
      beta    = seg$beta,
      segment = seg$segment
    )

  ## carry the last time point's S/I/R forward as next segment's start
  last_vals <- out_i |> filter(time == max(time))
  state <- list(
    I = last_vals$value[last_vals$matrix == "I"],
    R = last_vals$value[last_vals$matrix == "R"]
  )

  t_offset  <- t_offset + seg$duration
  traj_list[[i]] <- out_i
}

traj <- bind_rows(traj_list)

## --- 4. Tidy up for plotting -------------------------------------
sir_long <- traj |>
  filter(matrix %in% c("S", "I", "R")) |>
  mutate(
    compartment = factor(matrix, levels = c("S", "I", "R"),
                          labels = c("Susceptible", "Infected", "Recovered"))
  )

beta_step <- traj |>
  distinct(time, beta)

## --- 5. Plot with ggplot2 -----------------------------------------
p_sir <- ggplot(sir_long, aes(time, value, colour = compartment)) +
  geom_line(linewidth = 1) +
  geom_vline(xintercept = cumsum(segments$duration)[-nrow(segments)],
             linetype = "dashed", colour = "grey50", linewidth = 0.4) +
  scale_colour_manual(values = c(Susceptible = "#1b9e77",
                                  Infected    = "#d95f02",
                                  Recovered   = "#7570b3")) +
  labs(title = "SIR simulation with time-varying (piecewise) beta",
       x = NULL, y = "People", colour = NULL) +
  theme_bw() +
  theme(legend.position = "top")

p_beta <- ggplot(beta_step, aes(time, beta)) +
  geom_step(colour = "black", linewidth = 0.8) +
  geom_vline(xintercept = cumsum(segments$duration)[-nrow(segments)],
             linetype = "dashed", colour = "grey50", linewidth = 0.4) +
  labs(x = "Time step", y = expression(beta[t])) +
  theme_bw()

(p_sir / p_beta) + plot_layout(heights = c(3, 1))
