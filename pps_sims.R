library(macpan2)
library(bbmle)
library(tidyverse)
library(ggplot2);theme_set(theme_bw())
library(shellpipes)
rpcall("aug_10.pps_sims.Rout pps_sims.R aug_10.pps.rda")

loadEnvironments()

print(theta_samp)

simpps <- function(x){
	mp_trajectory_par(cal
	, list(log_beta_I=theta_samp[x,1]
		, log_beta_I = theta_samp[x,2]
		, log_beta_I = theta_samp[x,3]
		, log_beta_D = theta_samp[x,"log_beta_D"]
		, logit_mort = theta_samp[x,"logit_mort"]
		, logit_prop_Ic = theta_samp[x,"logit_prop_Ic"]
		, logit_prop_Dc = theta_samp[x,"logit_prop_Dc"]
		)
	)
}

simdf <- (lapply(1:nrow(theta_samp),simpps) 
	|> bind_rows(.id="iter")
	|> mutate(type = pipeStar())
)

print(head(simdf))

rdsSave(simdf)

gg <- (ggplot(filter(simdf,iter<20),aes(time,value,group=iter))
	+ geom_line(alpha=0.1)
	+ facet_wrap(~matrix,scale="free")
)

print(gg)

