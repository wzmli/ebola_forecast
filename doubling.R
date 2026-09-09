library(tidyverse);theme_set(theme_bw())
library(zoo)
library(cowplot)
library(shellpipes)
startGraphics(width=4,height=3)

loadEnvironments()

dat <- (rdsRead()
	|> filter(region == fitregion)
)

phydat <- data.frame(date = as.Date(c("2026-06-23","2026-08-09","2026-08-16"))
	, med = c(11.5, 23.4, 24.7)
	, lwr = c(7, 18.8, 20.1)
	, upr = c(17, 28.6, 30)
)

fitdat <- (dat
	|> filter(date > as.Date("2026-05-15"))
#	|> filter(date < as.Date("2026-07-11"))
	|> transmute(time = as.numeric(date - min(date))
		, cinc = cumIc
		, date
	)
)

print(fitdat)

mod <- (loess(time ~ cinc, data=fitdat, span=0.5))

print(summary(mod))

newdat <- (fitdat
	|> transmute(cinc = cinc/2)
)

pp <- predict(mod,newdata=newdat,se=TRUE)

print(pp)

fitdat$difftime <- pp$fit
fitdat$difftime.se <- pp$se.fit

newdat2 <- (fitdat
	|> mutate(dt = time - difftime
		, dt.lwr = time - difftime - 1.96*difftime.se
		, dt.upr = time - difftime + 1.96*difftime.se
	)
)

print(newdat2,n=Inf)

gg <- (ggplot(newdat2, aes(date))
	+ geom_line(aes(y=dt))
	+ geom_ribbon(aes(ymin=dt.lwr,ymax=dt.upr),alpha=0.2)
	+ geom_pointrange(data=phydat,aes(x=date,y=med,ymin=lwr,ymax=upr))
	+ xlim(c(as.Date("2026-06-01"),trimend + 5))
	+ ylim(c(0,NA))
	+ ylab("Doubling Time (days)")
	+ xlab("Date")
)

print(gg)


