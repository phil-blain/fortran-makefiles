all:myprogram

mymodule.o mymodule.mod: mymodule.f90
	@echo "=====compiling $@ (newer: $?)"
	gfortran -c mymodule.f90
myprogram.o: myprogram.f90 mymodule.mod
	@echo "=====compiling $@ (newer: $?)"
	gfortran -c myprogram.f90
# myprogram: myprogram.o mymodule.o # Thomas exemple
myprogram: mymodule.o myprogram.o # order matters, in this case we have a 2-cycle of recompilation if we touch mymodule.f90
	@echo "=====linking $@ (newer: $?)"
	gfortran -o myprogram myprogram.o mymodule.o
.PHONY:clean all
clean:
	rm -f *.mod *.o myprogram

.SUFFIXES:
Makefile: ;

%.f90 : ;

