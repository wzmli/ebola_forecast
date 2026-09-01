library(readr)
library(dplyr)
library(tidyr)
library(ggplot2);theme_set(theme_bw())
library(shellpipes)

dat <- rdsRead()

incdat <- (dat
	|> transmute(NULL
		, date
		, newIc = diff(c(0,confirmed_cases))
		, newDc = diff(c(0,confirmed_death))
		, region = "DRC"
		, cumIc = confirmed_cases
		, cumDc = confirmed_death
	)
	|> filter(date > as.Date("2026-05-15"))
)

ptdat <- (csvRead()
	|> rename(region = province)
	|> arrange(region,date)
	|> group_by(region)
	|> transmute(NULL
		, date
		, region
		, newIc = diff(c(0,cases))
		, newDc = diff(c(0,deaths))
		, cumIc = cases
		, cumDc = deaths
	)
)

incdat <- (bind_rows(incdat,ptdat))

rdsSave(incdat)
