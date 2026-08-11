## This is ebola_forecast

## This section is for Dushoff-style vim-setup and vim targeting
## You can delete it if you don't want it
current: target
-include target.mk
Ignore = target.mk

vim_session:
	bash -ic "vmt"

## -include makestuff/perl.def

######################################################################

Sources += $(wildcard *.R)

## Data from INSP github.

update_data: 
	touch national_dat.R regional_dat.R

national_dat.Rout: national_dat.R
	$(pipeR)

regional_dat.Rout: regional_dat.R
	$(pipeR)

Sources += regions.csv


## DD will provide province ts.
province_dat.Rout: province_dat.R regional_dat.rds regions.csv
	$(pipeR)

impmakerR += cleants

# national.cleants.Rout: cleants.R
# regional.cleants.Rout: cleants.R
%.cleants.Rout: cleants.R %_dat.rds
	$(pipeR)

impmakerR += tsplot
# national.tsplot.Rout: tsplot.R
# regional.tsplot.Rout: tsplot.R

%.tsplot.Rout: tsplot.R %.cleants.rds
	$(pipeR)


######################################################################

alldirs += ebola_2026
ebola_2026/%: | ebola_2026 ;
Ignore  += $(alldirs)

ebola_2026: 
	ln ../$@ || git clone https://github.com/wzmli/ebola_2026

######################################################################
## Getting national data from MLi's data repo

update: | ebola_2026
	cd ebola_2026 && $(MAKE) pull

read.Rout: ebola_2026/read.R ebola_2026/drc_sitrep.csv
	$(pipeR)

clean.Rout: clean.R read.rds
	$(pipeR)


## Distributing the backlog of the data jump from July 22 for the national data

correction.Rout: correction.R clean.rds
	$(pipeR)

doubling.Rout: doubling.R correction.rds
	$(pipeR)

######################################################################
## macpan national forecast 

flows.Rout: flows.R
	$(pipeR)

spec.Rout: spec.R flows.rda
	$(pipeR)

prop_spec.Rout: prop_spec.R spec.rds flows.rda
	$(pipeR)

aug_10.priors.Rout: aug_10.priors.R 
	$(pipeR)

impmakerR += calibrate

# aug_10.calibrate.Rout: calibrate.R aug_10.priors.R
%.calibrate.Rout: calibrate.R prop_spec.rds flows.rda clean.rds %.priors.rda
	$(pipeR)

impmakerR += timevar_calibrate

# aug_10.timevar_calibrate.Rout: timevar_calibrate.R aug_10.priors.R
%.timevar_calibrate.Rout: timevar_calibrate.R prop_spec.rds flows.rda clean.rds %.priors.rda
	$(pipeR)


impmakerR += pps

# aug_10.pps.Rout: pps.R
%.pps.Rout: pps.R %.calibrate.rds
	$(pipeR)

impmakerR += timevar_pps

# aug_10.timevar_pps.Rout: pps.R
%.timevar_pps.Rout: pps.R %.timevar_calibrate.rds
	$(pipeR)


impmakerR += timevar_pps_sims

# aug_10.timevar_pps_sims.Rout: pps_sims.R
%.timevar_pps_sims.Rout: pps_sims.R %.timevar_pps.rda
	$(pipeR)



impmakerR += timevar_ppsplot

# aug_10.timevar_pps_plot.Rout: pps_plot.R aug_10.priors.R
%.timevar_pps_plot.Rout: pps_plot.R %.timevar_pps_sims.rds clean.rds %.priors.rda
	$(pipeR)



### Makestuff

Sources += Makefile

Ignore += makestuff
msrepo = https://github.com/dushoff

## ln -s ../makestuff . ## Do this first if you want a linked makestuff
Makefile: makestuff/00.stamp
makestuff/%.stamp: | makestuff
	- $(RM) makestuff/*.stamp
	cd makestuff && $(MAKE) pull
	touch $@
makestuff:
	git clone --depth 1 $(msrepo)/makestuff

-include makestuff/os.mk

-include makestuff/pipeR.mk

-include makestuff/git.mk
-include makestuff/visual.mk
