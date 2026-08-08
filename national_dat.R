library(readr)
library(dplyr)
library(shellpipes)

deaths <- read_csv("https://raw.githubusercontent.com/INRB-UMIE/BDBV2026-Data/refs/heads/main/data/insp_sitrep/processed/insp_sitrep__national_cumulative_confirmed_deaths__daily.csv")

cases <- read_csv("https://raw.githubusercontent.com/INRB-UMIE/BDBV2026-Data/refs/heads/main/data/insp_sitrep/processed/insp_sitrep__national_cumulative_confirmed_cases__daily.csv")

dat <- (cases
	|> left_join(deaths)
)

print(tail(dat))

rdsSave(dat)

