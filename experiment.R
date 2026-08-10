# Time-varying-beta SIRD model of the 2026 Bundibugyo Ebola outbreak, macpan2
# Complete, self-contained: model spec -> calibration -> diagnostics -> plots

library(macpan2)
library(ggplot2)
library(dplyr)

## -----------------------------------------------------------------
## 1. MODEL SPEC
##    S -> I -> R (recovery)
##    I -> D (disease death)
##    beta is NOT a fixed scalar here -- it becomes a smooth,
##    continuously time-varying curve once passed through mp_rbf()
##    at the calibration step below. gamma/mu are held fixed from
##    external CFR + infectious-period evidence (see prior
##    messages) to avoid the beta/gamma identifiability problem.
## -----------------------------------------------------------------

sird_ebola = mp_tmb_model_spec(
  before = S ~ N - I - R - D,
  during = list(
    mp_per_capita_flow("S", "I", "beta * I / N", "infection"),
    mp_per_capita_flow("I", "R", "gamma", "recovery"),
    mp_per_capita_flow("I", "D", "mu", "death"),
    reported_cases ~ infection * report_prob   # observation-model link
  ),
  default = list(
    N           = 2e6,    # catchment population -- REPLACE with your real value
    I           = 717,    # currently isolated/hospitalised
    R           = 1406,   # recovered so far
    D           = 1751,   # cumulative deaths
    beta        = 0.342,  # starting value; will be overridden by the RBF curve
    gamma       = 0.112,  # fixed: (1-CFR)/infectious_period
    mu          = 0.088,  # fixed: CFR/infectious_period
    report_prob = 0.6     # starting guess for case-reporting fraction
  )
)

print(sird_ebola)

## -----------------------------------------------------------------
## 2. OBSERVED DATA
##    Long format, columns: matrix, time, value.
##    "reported_cases" = new confirmed cases per time-step (e.g. weekly)
##    "D"              = cumulative deaths at each time-step
##    Replace these two vectors with your real WHO/ECDC series.
## -----------------------------------------------------------------

observed_data = bind_rows(
  data.frame(matrix = "reported_cases", time = 1:20, value = weekly_new_cases_vector),
  data.frame(matrix = "D",              time = 1:20, value = cumulative_deaths_vector)
)

## -----------------------------------------------------------------
## 3. CALIBRATOR
##    - traj: negative-binomial observation error on both series
##      (accounts for overdispersion in real case/death counts --
##      see earlier discussion of Poisson vs. NB)
##    - tv = mp_rbf("beta", dimension = 4): replaces beta with a
##      smooth, continuous curve made of 4 radial basis functions.
##      No piecewise segments, so no discontinuity anywhere,
##      including wherever an intervention/break point occurred.
##      Raise "dimension" only if the fit clearly needs more bend;
##      higher dimension = more overfitting / convergence risk.
##    - par: gamma and mu are deliberately left OUT (held fixed)
## -----------------------------------------------------------------

sird_cal = mp_tmb_calibrator(
  spec = sird_ebola,
  data = observed_data,
  traj = list(
    reported_cases = mp_nbinom(disp = "disp_cases"),
    D              = mp_nbinom(disp = "disp_deaths")
  ),
  tv  = mp_rbf("beta", dimension = 4),
  par = c("I", "report_prob", "disp_cases", "disp_deaths"),
  default = list(disp_cases = 1, disp_deaths = 1)
)

## sanity check at starting values before optimizing
sird_cal |> mp_trajectory() |> filter(matrix %in% c("reported_cases", "D"))

## -----------------------------------------------------------------
## 4. FIT -- always check convergence == 0
## -----------------------------------------------------------------

fit = mp_optimize(sird_cal)
print(fit)
mp_tmb_coef(sird_cal, conf.int = TRUE)

## -----------------------------------------------------------------
## 5. DIAGNOSTICS AND PLOTS
## -----------------------------------------------------------------

## the fitted, smoothly time-varying beta(t) itself
beta_traj = mp_trajectory(sird_cal, outputs = "beta")

ggplot(beta_traj, aes(time, value)) +
  geom_line(linewidth = 1) +
  labs(x = "Day", y = expression(beta(t)),
       title = "Smoothly time-varying transmission rate (no discontinuities)") +
  theme_bw()

## fitted trajectories against observed data, with uncertainty
fitted_traj = mp_trajectory_sd(sird_cal, conf.int = TRUE) |>
  filter(matrix %in% c("reported_cases", "D"))

ggplot(observed_data) +
  geom_point(aes(time, value)) +
  geom_line(aes(time, value), data = fitted_traj, colour = "red") +
  geom_ribbon(aes(time, ymin = conf.low, ymax = conf.high),
              data = fitted_traj, fill = "red", alpha = 0.2) +
  facet_wrap(~matrix, scales = "free_y") +
  theme_bw() +
  labs(title = "SIRD fit with time-varying beta: 2026 Ebola outbreak")
