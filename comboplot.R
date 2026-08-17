library(tidyverse)
library(ggplot2);theme_set(theme_bw())
library(zoo)
library(ggh4x)
library(shellpipes)
startGraphics(width=6,height=4)

loadEnvironments()

forecastdat <- bind_rows(rdsReadList())
print(forecastdat)

dat <- (readRDS("clean.rds")
	|> select(date, newIc, newDc, cumIc = confirmed_cases, cumDc = confirmed_death)
	|> pivot_longer(-date,names_to="matrix",values_to = "value")
	|> mutate(report_type = matrix
		, report_type = ifelse(report_type == "newIc", "Daily new cases", report_type)
		, report_type = ifelse(report_type == "newDc", "Daily new death", report_type)
		, report_type = ifelse(report_type == "cumIc", "Cumulative cases", report_type)
		, report_type = ifelse(report_type == "cumDc", "Cumulative death", report_type)
	)
	|> mutate(value = ifelse((report_type %in% c("Daily new cases","Daily new death")) & (date == as.Date("2026-07-22")), NA, value)
	)
	|> group_by(report_type)
	|> mutate(MA = rollmean(value,k=7,fill=NA, align = "right",na.rm=TRUE))
)

print(tail(dat,10))

gg3 <- (ggplot(forecastdat, aes(date,med))
	+ geom_line(aes(color=scenario))
	+ geom_ribbon(aes(ymin=lwr,ymax=upr,fill=scenario),alpha=0.2)
	+ facet_wrap(~report_type,scale="free")
	+ geom_line(data=dat,aes(date,MA),color="black",size=0.8)
	+ geom_point(data=filter(dat,date<= trimend),aes(date,value),color="black",size=0.8)
	+ geom_point(data=filter(dat,date> trimend),aes(date,value),color="red",size=0.8)
	+ xlim(c(plotstart, plotend))
	+ theme(legend.position="none")
	+  facetted_pos_scales(y = list(
      	scale_y_continuous(limits = c(0, 15000))# facet 1
			, scale_y_continuous(limits = c(0, 10000))  # facet 2
      	, scale_y_continuous(limits = c(0, 200))  # facet 3
      	, scale_y_continuous(limits = c(0, 150))  # facet 4
    )
	 )
	+ xlab("Date")
	+ ylab("")
)

print(gg3)

