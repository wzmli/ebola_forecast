library(tidyverse)
library(shellpipes)

dat <- (rdsRead()
	|> select(date
		, region = nom
		, cumcases = contains("cumulative_confirmed_cases")
		, cumdeaths = contains("cumulative_confirmed_deaths")
	)
	|> mutate(NULL
		, cumcases = as.numeric(cumcases)
		, cumdeaths = as.numeric(cumdeaths)
	)
)

print(dat)

rdsSave(dat)
