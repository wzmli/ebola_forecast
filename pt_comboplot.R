library(tidyverse)
library(ggplot2);theme_set(theme_bw())
library(zoo)
library(ggh4x)
library(shellpipes)
startGraphics(width=8,height=6)

loadEnvironments()


combodat <- (bind_rows(rdsReadList())
	|> mutate(scenario = ifelse(grepl("high",scenario),"high","base"))
	|> filter(scenario == "base")
)


forecastdat <- (combodat
	|> filter(report_type %in% c("Daily new cases","Daily new death"))
	|> mutate(region = factor(region,levels=c("Ituri","Nord-Kivu","Haut-Uele")))
)

print(forecastdat)


dat <- (readRDS("clean.rds")
	|> select(date, newIc, newDc, region)
	|> filter(region %in% c("Ituri","Nord-Kivu","Haut-Uele"))
	|> pivot_longer(-c(date,region),names_to="matrix",values_to = "value")
	|> mutate(report_type = matrix
		, report_type = ifelse(report_type == "newIc", "Daily new cases", report_type)
		, report_type = ifelse(report_type == "newDc", "Daily new death", report_type)
	)
	|> mutate(value = ifelse((report_type %in% c("Daily new cases","Daily new death")) & (date == correction_date), NA, value)
	)
	|> group_by(report_type)
	|> mutate(MA = rollmean(value,k=7,fill=NA, align = "right",na.rm=TRUE))
	|> mutate(region = factor(region,levels=c("Ituri","Nord-Kivu","Haut-Uele")))
)


gg3 <- (ggplot(forecastdat, aes(date,med))
	+ geom_line(aes(color=scenario))
	+ geom_ribbon(aes(ymin=lwr,ymax=upr,fill=scenario),alpha=0.2)
	+ facet_wrap(region~report_type,scale="free",nrow=3)
	+ geom_line(data=dat,aes(date,MA),color="black",linewidth=0.8)
	+ geom_point(data=filter(dat,date>= trimend),aes(date,value),color="red",size=0.8)
	+ geom_point(data=filter(dat,date<= trimend),aes(date,value),color="black",size=0.8)
	+ theme(legend.position="none")
#	+  facetted_pos_scales(y = list(
#      	scale_y_continuous(limits = c(0, 15000))# facet 1
#			, scale_y_continuous(limits = c(0, 10000))  # facet 2
#      	, scale_y_continuous(limits = c(0, 200))  # facet 3
#      	, scale_y_continuous(limits = c(0, 150))  # facet 4
#    )
#	 )
	+ xlim(c(plotstart, plotend))
	+ xlab("Date")
	+ ylab("")
)

print(gg3 + xlim(c(plotstart, plotend)))
print(gg3 + xlim(c(plotstart, plotend + 180)))

rdsSave(combodat)
