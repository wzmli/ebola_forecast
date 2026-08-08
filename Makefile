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

national_dat.Rout: national_dat.R
	$(pipeR)

regional_dat.Rout: regional_dat.R
	$(pipeR)

Sources += regions.csv

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
