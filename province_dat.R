library(readr)
library(dplyr)
library(shellpipes)

regions <- csvRead()
regional_dat <- rdsRead()

dat <- (regional_dat
	|> rename(region = nom)
	|> left_join(regions)
	|> select(date, region, province, everything())
)	
print(dat, width=Inf, n=Inf)

dat2 <- (dat
	|> group_by(province,date)
	|> summarise(NULL
		, cumcases = sum(as.numeric(cumulative_confirmed_cases),na.rm=TRUE)
		, cumdeaths = sum(as.numeric(cumulative_confirmed_deaths),na.rm=TRUE)
	)
)

print(tail(dat2),width=Inf)
print(dat2,width=Inf,n=Inf)

rdsSave(dat2)

