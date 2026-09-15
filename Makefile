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

Sources += $(wildcard *.R) README.md

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

clean.Rout: clean.R read.rds ebola_2026/pt_sitrep.csv
	$(pipeR)


## Distributing the backlog of the data jump from July 22 for the national data

correction.Rout: correction.R clean.rds
	$(pipeR)

# sept_14.doubling.Rout: doubling.R IT_sept_14.priors.R
%.doubling.Rout: doubling.R clean.rds IT_%.priors.rda
	$(pipeR)

######################################################################
## macpan national forecast 

flows.Rout: flows.R
	$(pipeR)

spec.Rout: spec.R flows.rda
	$(pipeR)

prop_spec.Rout: prop_spec.R spec.rds flows.rda
	$(pipeR)

impmakerR += priors

# aug_17.priors.Rout: aug_17.priors.R
%.priors.Rout: %.priors.R 
	$(pipeR)

impmakerR += calibrate

# IT_sept_14.calibrate.Rout: calibrate.R IT_sept_14.priors.R
# NK_sept_14.calibrate.Rout: calibrate.R NK_sept_14.priors.R
# HU_sept_14.calibrate.Rout: calibrate.R HU_sept_14.priors.R
# aug_24.calibrate.Rout: calibrate.R aug_24.priors.R
%.calibrate.Rout: calibrate.R prop_spec.rds flows.rda clean.rds %.priors.rda
	$(pipeR)

impmakerR += pps

# aug_31.pps.Rout: pps.R
%.pps.Rout: pps.R %.calibrate.rds
	$(pipeR)

impmakerR += pps_sims

# IT_sept_14.pps_sims.Rout: pps_sims.R
# NK_sept_14.pps_sims.Rout: pps_sims.R
# HU_sept_14.pps_sims.Rout: pps_sims.R
%.pps_sims.Rout: pps_sims.R %.pps.rda
	$(pipeR)

impmakerR += pps_plot

# IT_sept_9.pps_plot.Rout: pps_plot.R IT_sept_9.priors.R
# sept_9.pps_plot.Rout: pps_plot.R sept_2.priors.R
%.pps_plot.Rout: pps_plot.R %.pps_sims.rds clean.rds %.priors.rda
	$(pipeR)

impmakerR += comboplot

# IT_sept_14.comboplot.Rout: comboplot.R IT_sept_14.priors.R
# NK_sept_14.comboplot.Rout: comboplot.R NK_sept_14.priors.R
# HU_sept_14.comboplot.Rout: comboplot.R HU_sept_14.priors.R
impmakerR += pt_comboplot.old

# sept_9.comboplot.Rout: comboplot.R sept_9.priors.R
%.comboplot.Rout: comboplot.R %.pps_plot.rds %.priors.rda
	$(pipeR)

# sept_14.comboplot.old.Rout: comboplot.R
%.comboplot.old.Rout: comboplot.R %.pps_plot.rds %.priors.rda
	$(pipeR)


impmakerR += pt_comboplot
# sept_14.pt_comboplot.Rout: pt_comboplot.R NK_sept_14.priors.R
%.pt_comboplot.Rout: pt_comboplot.R IT_%.comboplot.rds HU_%.comboplot.rds NK_%.comboplot.rds IT_%.priors.rda
	$(pipeR)

impmakerR += pt_comboplot.old

# sept_9.pt_comboplot.old.Rout: pt_comboplot.R
%.pt_comboplot.old.Rout: pt_comboplot.R IT_%.comboplot.rds HU_%.comboplot.rds NK_%.comboplot.rds %.priors.rda
	$(pipeR)


impmakerR += comboplot2
# sept_14.comboplot2.Rout: comboplot2.R IT_sept_14.priors.R
%.comboplot2.Rout: comboplot2.R %.pt_comboplot.rds IT_%.priors.rda
	$(pipeR)

impmakeR += comboplot2.old

# sept_9.comboplot2.old.Rout: comboplot2.R
%.comboplot2.old.Rout: comboplot2.R %.pt_comboplot.rds %.priors.rda
	$(pipeR)

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
