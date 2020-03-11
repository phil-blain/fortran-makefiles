test: 
	@echo "******* TEST: initial compile ******* "
	$(MAKE) clean
	$(MAKE)
	@echo "" && sleep 1
	@echo "******* TEST: change mymodule implementation *******"
	@git apply impl.patch
	@$(MAKE)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	@$(MAKE)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	@$(MAKE)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	@$(MAKE)
	@echo "" && sleep 1
	@echo "******* TEST: change mymodule interface ******* "
	@git checkout -q mymodule.f90
	@git apply interface.patch
	@$(MAKE)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	@$(MAKE)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	@$(MAKE)
	@echo "" && sleep 1
	@echo "******* TEST: remake *******"
	@$(MAKE)
	@echo "" && sleep 1
	@echo "******* TEST: reset mymodule.f90 and make clean *******"
	@$(MAKE) clean
	@git checkout -q mymodule.f90
