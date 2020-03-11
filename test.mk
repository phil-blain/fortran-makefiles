# get the name of the makefile that was invoked on the command line
makefile=$(firstword $(MAKEFILE_LIST))

test: 
	@echo "******* TEST: initial compile ******* "
	$(MAKE) clean
	$(MAKE) -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: change mymodule implementation *******"
	@git apply impl.patch
	$(MAKE) -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: change mymodule interface ******* "
	@git checkout -q mymodule.f90
	@git apply interface.patch
	$(MAKE) -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	$(MAKE) -f $(makefile)
	@echo "" && sleep 1
	@echo "******* TEST: reset mymodule.f90 and make clean *******"
	@$(MAKE) clean
	@git checkout -q mymodule.f90
