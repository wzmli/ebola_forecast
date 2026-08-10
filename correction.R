library(tidyverse);theme_set(theme_bw())
library(shellpipes)

startGraphics(width=8,height=5)

correction_date <- as.Date("2026-07-22")

dat <- (rdsRead()
	|> transmute(NULL
		, date
		, cumulative_cases = confirmed_cases
		, cumulative_death = confirmed_death
		, new_cases = newIc
		, new_death = newDc
		, fillnewIc = ifelse(is.na(new_cases),0,new_cases)
		, fillnewDc = ifelse(is.na(new_death),0,new_death)
	)
)

distribute_cases <- (dat 
	|> filter(date == correction_date)
	|> pull(new_cases)
)

print(distribute_cases)

distribute_death <- (dat 
	|> filter(date == correction_date)
	|> pull(new_death)
)

print(distribute_death)

dat2 <- (dat
	|> mutate(new_cases = ifelse(date == correction_date, NA, round(new_cases))
		, new_death = ifelse(date == correction_date, NA, round(new_death))
	)
	|> select(-c(fillnewIc,fillnewDc))
)


olddat <- (dat
	|> filter(date < correction_date)
	|> mutate(NULL
		, propI = new_cases/sum(fillnewIc)
		, propI = ifelse(is.na(propI),0,propI)
		, cnew_cases = round(fillnewIc + propI*distribute_cases)
		, propD = new_death/sum(fillnewDc)
		, propD = ifelse(is.na(propD),0,propD)
		, cnew_death = round(fillnewDc + propD*distribute_death)
		, death_adjust = propD*distribute_death
	)
	|> transmute(NULL
		, date
		, cumulative_cases = cumsum(cnew_cases)
		, cumulative_death = cumsum(cnew_death)
		, new_cases = cnew_cases
		, new_death = cnew_death
#		, propD
#		, D = sum(death_adjust)
	)
)


print(olddat,n=Inf)

olddat2 <- (dat
	|> filter(date < correction_date)
	|> filter(date >= as.Date("2026-07-01"))
	|> mutate(NULL
		, propI = new_cases/sum(fillnewIc)
		, propI = ifelse(is.na(propI),0,propI)
		, cnew_cases = round(fillnewIc + propI*distribute_cases)
		, propD = new_death/sum(fillnewDc)
		, propD = ifelse(is.na(propD),0,propD)
		, cnew_death = round(fillnewDc + propD*distribute_death)
	)
	|> bind_rows(filter(dat,between(date, min(date), as.Date("2026-06-30"))))
	|> arrange(date)
	|> transmute(NULL
		, date
		, cnew_cases = ifelse(is.na(cnew_cases),fillnewIc,cnew_cases)
		, cnew_death = ifelse(is.na(cnew_death),fillnewDc,cnew_death)
		, cumulative_cases = cumsum(cnew_cases)
		, cumulative_death = cumsum(cnew_death)
		, new_cases = cnew_cases
		, new_death = cnew_death
	)
	|> select(-c(cnew_cases,cnew_death))
)

print(olddat2,n=Inf)

gg <- (ggplot(data=pivot_longer(dat2, -date, names_to = "type",values_to = "value"), aes(date,value))
	+ geom_point(data=pivot_longer(olddat2, -date, names_to = "type",values_to = "value"), aes(date,value),color="green", size=1)
	+ geom_point(size=1)
	+ geom_point(data=pivot_longer(olddat, -date, names_to = "type",values_to = "value"), aes(date,value),color="red",size=1)
	+ facet_wrap(~type, scale="free")
)

print(gg)

mergedat <- (dat
	|> filter(date >= correction_date)
	|> bind_rows(olddat)
	|> arrange(date)
	|> transmute(date
		, confirmed_cases = cumulative_cases
		, confirmed_death = cumulative_death
		, newIc = diff(c(NA,confirmed_cases))
		, newDc = diff(c(NA,confirmed_death))
	)
)

print(mergedat, n=Inf)

rdsSave(mergedat)
