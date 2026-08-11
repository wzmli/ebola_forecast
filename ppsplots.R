library(macpan2)
library(bbmle)
library(tidyverse)
library(ggplot2);theme_set(theme_bw())
library(zoo)
library(ggh4x)
library(shellpipes)
startGraphics(width=6,height=4)

loadEnvironments()

nudge <- 4
# nudge <- 6
extra_nudge <- 2

if(pipeStar() == "low"){
extra_nudge <- 2
}

if(pipeStar() == "base"){
extra_nudge <- 2
}

simdf <- (rdsRead("sims")
	|> mutate(date = firstdate + time - 1 + nudge)
	|> mutate(date = ifelse(matrix %in% c("newDc","cumDc"), date + extra_nudge, date))
)


#dat <- (rdsRead("correction")
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

simdf$value <- pmax(rnorm(mean=simdf$value,sd=10,n=length(simdf$value)),0)

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
	+ xlim(as.Date(c("2026-05-01","2026-07-31")))
)

print(simdf2 |> filter(date == as.Date("2026-08-15")))


simdf3 <- (simdf2
	|> mutate(report_type = matrix
		, report_type = ifelse(report_type == "newIc", "Daily new cases", report_type)
		, report_type = ifelse(report_type == "newDc", "Daily new death", report_type)
		, report_type = ifelse(report_type == "cumIc", "Cumulative cases", report_type)
		, report_type = ifelse(report_type == "cumDc", "Cumulative death", report_type)
		, reporting = pipeStar()
	)
	|> filter(date <= as.Date("2026-09-02"))
	|> filter(report_type %in% c("Cumulative cases","Cumulative death","Daily new cases", "Daily new death"))
)


gg3 <- (ggplot(simdf3, aes(date,med))
	+ geom_line()
	+ geom_ribbon(aes(ymin=lwr,ymax=upr),alpha=0.2)
	+ facet_wrap(~report_type,scale="free")
	+ geom_point(data=filter(dat,date<=fitdate),aes(date,value),color="black",size=0.8)
	+ geom_point(data=filter(dat,date>fitdate),aes(date,value),color="red",size=0.8)
#	+ xlim(as.Date(c("2026-06-01","2026-07-31")))
	+ xlim(as.Date(c("2026-05-15","2026-08-03")))
	+ xlim(as.Date(c("2026-05-15","2026-08-15")))
	+ theme(legend.position="bottom")
	+  facetted_pos_scales(y = list(
      	scale_y_continuous(limits = c(0, 5500))# facet 1
			, scale_y_continuous(limits = c(0, 2700))  # facet 2
      	, scale_y_continuous(limits = c(0, 90))  # facet 3
      	, scale_y_continuous(limits = c(0, 60))  # facet 4
    )
	 )
)

print(gg3)

outdat <- (simdf2
	|> filter(matrix %in% c("newIc","Incidence","cumIc"))
	|> filter(date < as.Date("2026-08-30"))
	|> select(date,matrix,med)
	|> pivot_wider(names_from=matrix,values_from=med)
	|> mutate(date = as.Date(date))
)

print(outdat,n=Inf)
csvSave(outdat)
rdsSave(simdf3)

