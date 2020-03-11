# get the name of the makefile that was invoked on the command line
makefile=$(firstword $(MAKEFILE_LIST))

$(makefile) : ;

test.mk : ;

test: 
	@echo "******* TEST: reset mymodule.f90 and make clean *******"
	@$(MAKE) --no-print-directory -f $(makefile) clean
	@git checkout -q mymodule.f90
	@echo "" &
	@echo "******* TEST: initial compile ******* "
	$(MAKE) --no-print-directory -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: change mymodule implementation *******"
	@git apply impl.patch
	$(MAKE) --no-print-directory -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) --no-print-directory -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) --no-print-directory -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) --no-print-directory -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: change mymodule interface ******* "
	@git checkout -q mymodule.f90
	@git apply interface.patch
	$(MAKE) --no-print-directory -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) --no-print-directory -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) --no-print-directory -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) --no-print-directory -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: change mymodule interface, make myprogram.o ******* "
	@git checkout -q mymodule.f90
	@git apply interface.patch
	$(MAKE) --no-print-directory -f $(makefile) myprogram.o
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) --no-print-directory -f $(makefile) myprogram.o
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) --no-print-directory -f $(makefile) myprogram.o
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) --no-print-directory -f $(makefile) myprogram.o
	@echo "" && sleep 1
	@echo "******* TEST: reset mymodule.f90 and make clean *******"
	@$(MAKE) --no-print-directory -f $(makefile) clean
	@git checkout -q mymodule.f90
