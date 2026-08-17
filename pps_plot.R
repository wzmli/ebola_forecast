library(macpan2)
library(bbmle)
library(tidyverse)
library(ggplot2);theme_set(theme_bw())
library(zoo)
library(ggh4x)
library(shellpipes)
startGraphics(width=6,height=4)

loadEnvironments()


simdf <- (rdsRead("sims")
	|> mutate(date = firstdate + time - 1 + nudge)
	|> mutate(date = ifelse(matrix %in% c("newDc","cumDc"), date + extra_nudge, date))
)


dat <- (rdsRead("clean")
	|> select(date, newIc, newDc, cumIc = confirmed_cases, cumDc = confirmed_death)
	|> pivot_longer(-date,names_to="matrix",values_to = "value")
	|> mutate(report_type = matrix
		, report_type = ifelse(report_type == "newIc", "Daily new cases", report_type)
		, report_type = ifelse(report_type == "newDc", "Daily new death", report_type)
		, report_type = ifelse(report_type == "cumIc", "Cumulative cases", report_type)
		, report_type = ifelse(report_type == "cumDc", "Cumulative death", report_type)
	)
)

print(dat,n=Inf)

print(head(simdf))

#gg <- (ggplot(simdf,aes(date,value))
gg <- (ggplot(filter(simdf,iter<20),aes(date,value))
	+ geom_line(alpha=0.1,aes(group=iter))
	+ facet_wrap(~matrix,scale="free")
	+ geom_point(data=dat,aes(date,value),color="red")
)

print(gg)

newcumInc <- (simdf
	|> select(date,matrix,value,iter)
	|> filter(matrix == "newIc")
	|> filter(date > as.Date("2026-04-15"))
	|> arrange(iter,date)
	|> group_by(iter)
	|> mutate(cumval = cumsum(value))
	|> ungroup()
	|> transmute(date
		,matrix = "cumIc"
		,iter
		,value=cumval
	)
)

simdf2 <- (simdf
#	|> filter(matrix != "cumIc")
#	|> bind_rows(newcumInc)
	|> group_by(date,matrix)
	|> summarise(NULL
		, med = quantile(value,prob=0.5)
		, lwr = quantile(value,prob=0.025)
		, upr = quantile(value,prob=0.975)
	)
)

gg2 <-(ggplot(simdf2, aes(date,med))
	+ geom_line()
	+ geom_ribbon(aes(ymin=lwr,ymax=upr),alpha=0.2)
	+ facet_wrap(~matrix,scale="free")
	+ geom_point(data=dat,aes(date,value),color="red")
)

print(gg2)
print(gg2
	+ xlim(as.Date(c("2026-05-01","2026-09-31")))
)

print(simdf2 |> filter(date == as.Date("2026-08-09")))


simdf3 <- (simdf2
	|> mutate(report_type = matrix
		, report_type = ifelse(report_type == "newIc", "Daily new cases", report_type)
		, report_type = ifelse(report_type == "newDc", "Daily new death", report_type)
		, report_type = ifelse(report_type == "cumIc", "Cumulative cases", report_type)
		, report_type = ifelse(report_type == "cumDc", "Cumulative death", report_type)
		, reporting = pipeStar()
	)
	|> ungroup()
	|> rowwise()
	|> mutate(NULL
		, date = as.Date(date)
		, med = ifelse((matrix == "cumIc") & (date>=correction_date), med + case_correction, med)
		, lwr = ifelse((matrix == "cumIc") & (date>correction_date), lwr + case_correction, lwr)
		, upr = ifelse((matrix == "cumIc") & (date>=correction_date), upr + case_correction, upr)
	)
	|> mutate(NULL
		, date = as.Date(date)
		, med = ifelse((matrix == "cumDc") & (date>=correction_date), med + death_correction, med)
		, lwr = ifelse((matrix == "cumDc") & (date>correction_date), lwr + death_correction, lwr)
		, upr = ifelse((matrix == "cumDc") & (date>=correction_date), upr + death_correction, upr)
	)
	|> filter(report_type %in% c("Cumulative cases","Cumulative death","Daily new cases", "Daily new death"))
	|> mutate(scenario = pipeStar())
)

print(simdf3)

gg3 <- (ggplot(simdf3, aes(date,med))
	+ geom_line()
	+ geom_ribbon(aes(ymin=lwr,ymax=upr),alpha=0.2)
	+ facet_wrap(~report_type,scale="free")
	+ geom_point(data=filter(dat,date<=trimend),aes(date,value),color="black",size=0.8)
	+ geom_point(data=filter(dat,date>trimend),aes(date,value),color="red",size=0.8)
	+ xlim(as.Date(c("2026-05-15","2026-10-15")))
	+ theme(legend.position="bottom")
)

print(gg3)
print(simdf3 |> filter(date == trimend))
print(simdf3 |> filter(date == as.Date("2026-08-31")))

outdat <- (simdf3
	|> filter(matrix %in% c("newIc","Incidence","cumIc"))
	|> filter(date <= as.Date("2026-09-01"))
	|> select(date,matrix,med)
	|> pivot_wider(names_from=matrix,values_from=med)
	|> mutate(date = as.Date(date))
)

print(outdat,n=Inf)
csvSave(outdat)
rdsSave(simdf3)

