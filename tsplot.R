library(ggplot2);theme_set(theme_bw())
library(shellpipes)

ggcases <- (ggplot(rdsRead())
	+ aes(date, cumcases)
	+ geom_point()
	+ geom_line()
	+ facet_wrap(~region, scale="free")
)

print(ggcases)

ggdeaths <- (ggplot(rdsRead())
	+ aes(date, cumdeaths)
	+ geom_point()
	+ geom_line()
	+ facet_wrap(~region, scale="free")
)

print(ggdeaths)
