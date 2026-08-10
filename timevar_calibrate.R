library(macpan2)
library(tidyverse);theme_set(theme_bw())
library(shellpipes)

loadEnvironments()
spec <- rdsRead("prop_spec")

beta_I_changepoints <- c(1,2,150)
beta_I_values <- c(0.3, 0.2, 0.2)

expr <- list(beta_I ~ time_var(beta_I_values, beta_I_changepoints))

newspec <- (spec
	|> mp_tmb_insert(phase = "during"
		, at = 1
		, expressions = expr
		, default = list(beta_I_values = beta_I_values)
		, integers = list(beta_I_changepoints = beta_I_changepoints)
	)
)

## make a macpan2 dataset for calibration
dat <- (rdsRead("clean")
	|> select(date, newIc, newDc, cumIc = confirmed_cases, cumDc=confirmed_death)
)

firstdat <- data.frame(
	date = firstdate
	, newIc = NA
	, newDc = NA
)

calibdat <- (bind_rows(firstdat,dat)
	|> mutate(time = as.numeric(date - min(date))+1)
	|> filter(date <= trimend)  ## 
	|> select(-date)
#	|> pivot_longer(-c(date,time),names_to = "matrix", values_to = "value")
	|> pivot_longer(-c(time),names_to = "matrix", values_to = "value")
	|> filter(!is.na(value))
)



## define priors

get_prior = function(trans) function(rng) {
  mp_norm(
    (trans(rng[1]) + trans(rng[2])) / 2
    , log((trans(rng[2]) - trans(rng[1])) / (2 * 1.96))
  )
}


print(get_prior(log)(prior_range[["beta_I"]]))

priors <- list(
	log_beta_I_values = mp_norm(0.2,log(1))
	, log_beta_D = get_prior(log)(prior_range[["beta_D"]])
	, logit_mort = get_prior(qlogis)(prior_range[["mort"]])
	, logit_prop_Ic = get_prior(qlogis)(prior_range[["prop_Ic"]])
	, logit_prop_Dc = get_prior(qlogis)(prior_range[["prop_Dc"]])
)


calib <- mp_tmb_calibrator(spec = newspec # |> mp_rk4()
	, data = calibdat
	, time = mp_sim_bounds(1, time_steps)
	, traj = list(newIc = mp_nbinom(disp = "disp_cases")
		, newDc = mp_nbinom(disp = "disp_death")
	)
	, default = list(disp_cases = 0.001
		, disp_death = 0.001
	)
	, par = priors
	, outputs = c("newIc","newDc","Incidence","cumIc","cumDc","cumIncidence")
)

cal_opt = mp_optimize(calib)

## Check optimized fit

print(cal_opt)

cal_est <- mp_tmb_coef(calib, conf.int=TRUE)

print(cal_est)

## Plots

fitted_data = (mp_trajectory_sd(calib, conf.int = TRUE)
	|> mutate(date = time + firstdate)
#	|> filter(date > as.Date("2026-05-15"))
	|> filter(date < as.Date("2026-10-15"))
)


calibdat <- (calibdat
	|> mutate(date = firstdate + time)
)

interceptdat <- (fitted_data
	|> filter(time %in% beta_I_changepoints)
)

gg <- (ggplot(data = (fitted_data ))
  + geom_line(aes(date, value))
  + geom_ribbon(aes(date, ymin = conf.low, ymax = conf.high)
    , alpha = 0.2
    , colour = "red"
  )
  + geom_vline(data=interceptdat,aes(xintercept = date))
  + facet_wrap(~matrix,scale="free")
  + geom_point(data=calibdat,aes(date, value))
)

print(gg)


print(gg	
	+ coord_cartesian(xlim=c(as.Date("2026-05-01"),as.Date("2026-10-25"))
#		, ylim = c(0,5000)
	)
)

rdsSave(calib)
