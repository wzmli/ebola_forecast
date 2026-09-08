library(tidyverse)
library(ggplot2);theme_set(theme_bw())
library(zoo)
library(ggh4x)
library(shellpipes)
startGraphics(width=6,height=6)

loadEnvironments()

pt <- (rdsRead(paste0(pipeStar(),".pt_comboplot.rds"))
	|> filter(scenario == "base")
	|> group_by(date, report_type)
	|> summarise(med = sum(med)
		, lwr = sum(lwr)
		, upr = sum(upr)
		, scenario = "zz"
		, region = "zz"
		)
	|> ungroup()
)

forecastdat <- (rdsRead(paste0(pipeStar(),".comboplot.rds"))
	|> bind_rows(pt)
)


dat <- (readRDS("clean.rds")
	|> filter(region == fitregion)
	|> select(date, newIc, newDc, cumIc, cumDc)
	|> pivot_longer(-date,names_to="matrix",values_to = "value")
	|> mutate(report_type = matrix
		, report_type = ifelse(report_type == "newIc", "Daily new cases", report_type)
		, report_type = ifelse(report_type == "newDc", "Daily new death", report_type)
		, report_type = ifelse(report_type == "cumIc", "Cumulative cases", report_type)
		, report_type = ifelse(report_type == "cumDc", "Cumulative death", report_type)
	)
	|> mutate(value = ifelse((report_type %in% c("Daily new cases","Daily new death")) & (date == correction_date), NA, value)
	)
	|> group_by(report_type)
	|> mutate(MA = rollmean(value,k=7,fill=NA, align = "right",na.rm=TRUE))
)


gg3 <- (ggplot(forecastdat, aes(date,med))
	+ geom_line(aes(color=scenario))
	+ geom_ribbon(aes(ymin=lwr,ymax=upr,fill=scenario),alpha=0.2)
	+ facet_wrap(~report_type,scale="free")
	+ scale_color_manual(values=c("#F8766D", "#00BFC4","#619CFF"))
	+ scale_fill_manual(values=c("#F8766D", "#00BFC4","#619CFF"))
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
print(gg3 + xlim(c(plotstart, plotend + 30)))

