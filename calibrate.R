library(macpan2)
library(tidyverse)
library(zoo)
library(shellpipes)
startGraphics(width=8,height=4)

loadEnvironments()

## make a macpan2 dataset for calibration
dat <- (rdsRead("clean")
	|> select(date, newIc, newDc, cumIc = confirmed_cases, cumDc=confirmed_death)
	|> mutate(newIc = round(rollmean(newIc,k=7,fill=NA,align="right",na.rm=TRUE))
		, newDc = round(rollmean(newDc,k=7,fill=NA,align="right",na.rm=TRUE))
	)
	|> filter(date != correction_date) 
#	|> filter(!(between(date,as.Date("2026-07-23"),as.Date("2026-07-28")))) 
#	|> filter(date >= trimstart) 
)

print(dat, n=Inf)

firstdat <- data.frame(
	date = firstdate
	, newIc = 1
	, newDc = NA
)

calibdat <- (bind_rows(firstdat,dat)
	|> mutate(time = as.numeric(date - min(date))+1)
	|> filter(date <= trimend)  ## 
	|> select(-date)
	|> pivot_longer(-time,names_to = "matrix", values_to = "value")
	|> filter(!is.na(value))
)

print(calibdat, n=Inf)
## define priors

get_prior = function(trans) function(rng) {
  mp_norm(
    (trans(rng[1]) + trans(rng[2])) / 2
    , log((trans(rng[2]) - trans(rng[1])) / (2 * 1.96))
  )
}


print(get_prior(log)(prior_range[["beta_I"]]))

priors <- list(log_beta_I = get_prior(log)(prior_range[["beta_I"]])
	, log_beta_D = get_prior(log)(prior_range[["beta_D"]])
	, logit_mort = get_prior(qlogis)(prior_range[["mort"]])
	, logit_prop_Ic = get_prior(qlogis)(prior_range[["prop_Ic"]])
	, logit_prop_Dc = get_prior(qlogis)(prior_range[["prop_Dc"]])
)

newspec <- mp_tmb_update(rdsRead("prop_spec")
	, default = list(effS = effS
		, N = Npop
		)
)



calib <- mp_tmb_calibrator(spec = newspec |> mp_rk4()
	, data = calibdat
	, time = mp_sim_bounds(1, time_steps)
#	, traj = c("newIc","newDc")
#	, traj = c("newIc","newDc","cumDc","cumIc")
	, traj = list(newDc = mp_nbinom(disp = "disp_death")
#		, newIc = mp_nbinom(disp = "disp_cases")
	)
	, default = list(disp_death = 0.01
#		, disp_cases = 0.01
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
)

calibdat <- (calibdat
	|> mutate(date = firstdate + time)
)

gg <- (ggplot(data = (fitted_data ))
  + geom_line(aes(date, value))
  + geom_ribbon(aes(date, ymin = conf.low, ymax = conf.high)
    , alpha = 0.2
    , colour = "red"
  )
  + facet_wrap(~matrix,scale="free")
  + geom_point(data=calibdat,aes(date, value))
)

print(gg)


print(gg	
	+ coord_cartesian(xlim=c(as.Date("2026-05-01"),as.Date("2026-08-25"))
	)
)

rdsSave(calib)
