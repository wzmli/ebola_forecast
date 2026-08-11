library(macpan2)
library(shellpipes)

loadEnvironments()

spec <- rdsRead()

print(spec)


prop_spec = mp_tmb_insert(spec
	, expression = list(newIc ~ prop_Ic*Incidence
		, cumIc ~ cumIc + newIc
		, newDc ~ prop_Dc * Death
		, cumDc ~ cumDc + newDc
		)
	, at =Inf
	, phase = "during"
)

rdsSave(prop_spec)

