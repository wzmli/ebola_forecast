library(readr)
library(dplyr)
library(shellpipes)

regions <- csvRead()
regional_dat <- rdsRead()

dat <- (regional_dat
	|> rename(region = nom)
	|> left_join(regions)
)

print(tail(dat),width=Inf)

rdsSave(dat)

