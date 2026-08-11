## ============================================================
## Does a reporting-delay convolution smooth out the kink from a
## piecewise time-varying beta? Build "reports" as infection
## convolved with a gamma-density delay kernel, and compare.
## ============================================================

## --- 0. Setup -------------------------------------------------
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
gamma_rec    <- 0.2   # recovery rate (named gamma_rec to avoid clashing
                       # with the delay kernel's gamma DISTRIBUTION below)

## --- 1. Piecewise beta schedule (same as before) ------------------
beta_changepoints <- c(0, 10, 25, 35)
beta_values       <- c(0.80, 0.15, 0.55, 0.10)

## --- 2. Build a gamma-density reporting-delay kernel -----------------
## Handled by mp_tmb_insert_reports() itself -- no need to build the
## kernel by hand. We just supply the delay distribution's mean/cv and
## a reporting probability.
delay_mean  <- 5     # average number of steps between infection and report
delay_cv    <- 0.5   # spread of the delay distribution
report_prob <- 1     # set < 1 for under-reporting; 1 = report every case

## --- 3. Build the SIR spec: piecewise beta + convolved reports --------
piecewise_spec <- (
  mp_tmb_library("starter_models", "sir", package = "macpan2")
  |> mp_tmb_insert(
      phase = "during"
    , at =1L
    , expressions = list(beta ~ time_var(beta_values, beta_changepoints))
    , default = list(
        beta        = beta_values[1]
      , gamma       = gamma_rec
      , beta_values = beta_values
      )
    , integers = list(beta_changepoints = beta_changepoints)
  )
  |> mp_tmb_insert_reports(
      incidence_name = "infection"  # the flow to convolve/report on
    , mean_delay     = delay_mean
    , cv_delay       = delay_cv
    , report_prob    = report_prob
    , reports_name   = "reports"
  )
)

## Sanity check: confirm "reports" now shows up as a during-phase
## expression, after infection is computed, and that a delay-kernel
## matrix has been added to defaults. If mp_tmb_insert_reports() uses
## different argument names in your installed version, this print will
## make that obvious via an error above rather than a silent wrong model.
print(piecewise_spec)

## --- 4. Simulate ------------------------------------------------------
piecewise_simulator <- mp_simulator(
  piecewise_spec,
  time_steps = time_steps,
  outputs = c(state_labels, "infection", "reports", "beta")
)

sim_data <- mp_trajectory(piecewise_simulator)

## --- 5. Tidy up for plotting --------------------------------------------
infection_traj <- sim_data |> filter(matrix == "infection")
reports_traj   <- sim_data |> filter(matrix == "reports")
beta_traj      <- sim_data |> filter(matrix == "beta")

compare_traj <- bind_rows(
  infection_traj |> mutate(series = "infection (raw incidence)"),
  reports_traj   |> mutate(series = "reports (after convolution)")
)

## --- 6. Plot: raw infection vs convolved reports, plus the kernel -------
p_compare <- ggplot(compare_traj, aes(time, value, colour = series)) +
  geom_line(linewidth = 0.9) +
  geom_vline(xintercept = beta_changepoints[-1],
             linetype = "dashed", colour = "grey50", linewidth = 0.4) +
  scale_colour_manual(values = c(
    "infection (raw incidence)"   = "#d95f02",
    "reports (after convolution)" = "#1b9e77"
  )) +
  labs(title = "Does a reporting-delay convolution smooth the piecewise-beta kink?",
       x = NULL, y = "Count", colour = NULL) +
  theme_bw() +
  theme(legend.position = "top")

p_beta <- ggplot(beta_traj, aes(time, value)) +
  geom_step(colour = "black", linewidth = 0.8) +
  geom_vline(xintercept = beta_changepoints[-1],
             linetype = "dashed", colour = "grey50", linewidth = 0.4) +
  labs(x = "Time step", y = expression(beta[t])) +
  theme_bw()

if (requireNamespace("patchwork", quietly = TRUE)) {
  library(patchwork)
  print((p_compare / p_beta) + plot_layout(heights = c(3, 1)))
} else {
  print(p_compare)
  print(p_beta)
}
