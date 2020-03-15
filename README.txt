
Il y a plusieurs choses qu'on veut faire:
A. génération automatique des dépendances
B. Utiliser les fonctionnalités de génération des dépendances du compilateur si possible
C. Si on change l'implémentation d'une fonction /subroutine dans un module, ne recompiler que ce module et relinker.
D. 2 pass compile
E. fonctionne en parallèle
F. out-of-tree build

A. idéalement le compilateur a une foncitonnalité pour faire que ça, et ça fonctionne from scratch. avec gfortran/ifort ce n'est pas le cas, il lui faut les .mod.
C'est possible d'utiiser la fait que make se restart pour créer tous les fichiers de dépendances jusqu'au feuilles de l'arbre, mais irréaliste pour un gros programme.
Donc dans ce cas il faut un outil séparé pour le faire (ex. makdep de CICE, makedepf08, makedepf90..)

B. une fois qu'on a généré les dépendances une première fois, il serait bien d'utiliser les fonctionnalités du compilateur par la suite afin d'éviter de toujours invoquer un outil séparé (c'est à cause de ça que j'avais choisi l'implémentation avec les .di (initial dependencies) et les .d (générées en même temps que la compilation)
par contre si on veut que le makefile soit général, ça peut être plus compliqué

C. -> il faut que le compilateur de modifie pas le timestamp du .mod si l'interface ne change pas. (gfortran agit comme ça)
(ou -> utiliser des submodules)



--- PISTES DE SOLUTIONS POUR C. ---
1. Exemple de Thomas
https://gcc.gnu.org/bugzilla/show_bug.cgi?id=47495
voir /Users/Philippe/Code/ftn-autodep/thomas-test

- c'est parce qu'il n'utilise pas de pattern rule, donc il définit 2 règles (une pour le .mod et une pour le .o)

- changer l'implémentation:
-> c'est la règle pour le .mod qui est triggerée

- remake
-> la règle pour le .mod est toujours réévalué, puis le link
car le .mod reste plus vieux que le .f90
(et la règle pour le .mod ne modifie pas le .mod, ce qui va à l'encontre de la règle numéro 2 de Paul)
=> INNACEPTABLE

2. exemple de Thomas, changer l'ordre des dépendances de myprogram 
- changer l'implémentation:
-> c'est la règle pour le .o qui est triggerée

- remake
->  il y a un 2-cycle dans la recompilation
=> INNACEPTABLE

3. Exemple de Tobias
https://gcc.gnu.org/bugzilla/show_bug.cgi?id=47495#c1

-> voir Makefile.tobias

-> ça fonctionne pour changer impl + changer interface

-> ça ne recompile pas myprogram.o si on fait "make myprogram.o" et que interface de mymodule a changé (ce qui est erroné)


-> c'est probablement ce qu'il veut dire pas :
" and for the same reason doing a "make myprogram.o" will fail.  (Assuming that mymodule.f90 has a change, which is required by myprogram.)" 

=> INNACEPTABLE (moins grave, mais quand même, on ne veut pas que le Makefile soit capable de créer un build erroné)

4. Exemple de Tobias, changer l'ordre des dépendances de myprogram 
(Makefile.tobias.2)

- changer implémentation
->fonctionne

- changer interface
-> NE RECOMPILE PAS MYPROGRAM (donc build probablement erroné)
-> parce que mymodule.mod ne dépend pas de mymodule.f90

=> INNACEPTABLE 

-> si on recompile alors là il recompile myprogram car mymodule.mod est nouveau (créé dans la 1er make)

=> INNACEPTABLE QUAND MÊME ! (on veut pas avoir à faire make 2 fois)

- changer interface, puis make myprogram.o
-> ne recompile pas myprogram.o (erroné)

5. le même exemple avec une pattern rule à multiple output (%.o %.mod : %.F90)
voir Makefile.pattern

- changer implémentation
-> fonctionne ok (recompile mymodule + relink)

remake
-> RECOMPILE mymodule (seulement)
=> BOGUE (avec make -d:
   Finished prerequisites of target file `myprogram'.
   Prerequisite `mymodule.o' is newer than target `myprogram'.
   Prerequisite `myprogram.o' is older than target `myprogram'.
  No need to remake target `myprogram'.
remake
-> recompile mymodule + relink
=> CYCLE (avev make 3.81)

avec make 4.2.1
-> toujours recompile .mod+relink
(donc ce "bogue" a été réglé)
-> parce que à chaque fois le module reste plus vieux que la source,
donc la règle pour crééer le module est triggerée,
ce qui créé un nouvel objet et donc trigger la règle pour le link

- changer interface
-> ok (recompile mymodule + myprogram, relink)

- changer interface, make myprogram.o
-> ok : recompile mymodule et myprogram

remake :
ok (ne recompile pas )

5.5 NOTE: ajouter "touch $@" à la fin de la règle de compilation fait en sorte que on perd l'avantage du fait que le module ne change pas, donc myprogram est recompilé. cela brise aussi le cycle (mais il faut 2 make pour obtenir "nothing to be done")
voir Makefile.pattern_grouped_touch


6. Exemple de Joost (pattern rule + fake mod rule)
->fonctionne correctement !! 
-> la seule chose est que la "fake rule" est exécutée si on change l'implémentation, make et remake (donc on ne voit pas "nothing to do for 'all'")
-> si on a un compilateur moins intelligent qui modifie toujours le timestamp du .mod, le build est aussi correct mais il va re compiler myprogram.o même si l'interface seulement a changé (même comportement que avec les dépendances sur les .o) => testé en ajoutant touch $*.mod à la fin de la règle de compilation
-> NOTE: Comme indiqué par Matthew West, si on delete le .mod et qu'on recompile, le compilateur va dire qu'il ne trouve pas le module, et make va errorer. 
on peut contrer cettte situation dans la règle pour le .mod en vérifiant si le .mod existe (il devrait toujours exister puisqu'il a été généré auparavant par la règle de compilation), puis si n'existe pas en supprimant le .o et réexutant make :D
test -f $@ || rm $< && $(MAKE) --no-print-directory -f $(makefile) $<

7. Pattern rule, no rule for *.mod
~~ make 3.81 ~~

changer impl:
OK
remake:
OK

changer interf:
OK
remake:
OK

changer interf, make myprogram.o:
-> ne recompile pas myprogram.o 
=> ERRONÉ

~~ make 4.2.1, 4.2, 4.1, 4.0, 3.82 ~~

-> ERREUR ( à la compilation initiale il essaie de compiler myprogram.o alors que mymodule.mod n'existe pas encore !!, car il dit qu'il a remade mymodule.mod mais il n'a rien fait ?!)
-> car il n'y a pas de règle pour les .mod

~~ make 4.3 ~~
=> même comportement que make 3.81 (ouf!)

->mais from scratch, "make myprogram.o" a la même ERREUR

=> même ERREUR en parallèle (from sractch)

-> INNACEPTABLE
=> il cherche une règle pour les .mod, n'en trouve pas et donc il pense qu'il a updaté le target, et donc il continue avec la compilation de myprogram.o


8. 2 stages

-> il faut changer les dépendances pour les fichiers qui ne sont pas des modules, sinon en parallèle ça ne fonctionne pas car la passe 1 n'a pas d'informations sur les 
dépendances
ex. dépendance de myprogram.d générée par gfortran:
==> myprogram.d <==
myprogram.o: myprogram.F90 mymodule.mod

==> myprogram.dmod <==
myprogram.o myprogram.mod: myprogram.F90 mymodule.mod

-> on rajoute myprogram.mod comme target

NOTE:-> ceci s'applique si on n'a pas de façon a priori de déterminer quels fichiers sont des modules et quels n'en sont pas. si c'est possible de le faire, alors la règle pour les non-modules doit être 
%.o : %.f90
plutôt que 
%.o : %.f90 %.mod

et la règle pour les modules 
%.mod : %.f90
ne doit s'appliquer que pour les fichiers source qui sont des modules
-> exemple dans Makefile.busby
-> dans ce cas on n'a pas besoin du "test -f && touch"
NOTE2: in Busby the dependency for prog are on the *object* files of the modules aa and bb, and there is no dependency on the modules


-- Règle des modules --
si on met  `touch $@`, on perd l'avantage que gfortran ne touche pas le module si seulement l'implémentation change. (donc recompilation de myprogram si on change l'interface ou l'implémentation de mymododule, mais remake est ok)

si on met `test -f $@ || touch $@`, ça fait en sorte que si on change l'implémentation + remake il va toujours triggeré la règle pour mymodule.mod (car le .mod reste plus vieux que le .F90) (même comportement que Makefile.joost)

par contre si on change l'interface, ça fait en sorte que il va regénérer le "module" pour myprogram (inneficace), et ensuite si on remake il va toujours regénérer myprogram.mod car mymodule.mod est newer, mais comme myprogram.mod existe déjà , le test -f fait en sorte qu'il n'est pas touché

si on ne met pas de touch, la règle pour créer myprogram.mod est toujours trigerrée, puis la règle pour compiler myprogram.o puisque make pense que il a regénéré le .mod

NOTE:
si le source tree est séparé d'une façon que les modules/submodules sont différentiables des autres fichiers sources (ex. programmes, sous-routines, etc) alors il pourrait être intéressant de faire une règle différente pour les programmes/sous-routines, ou on fait seulement "touch $*.mod" et non syntax-only (pour plus d'efficacité) (voir ci-dessus)

=> le 2pass build ne semble pas si avantageux pour les build incrémentaux
=> donc il faudrait des dépendances différentes en fonction du type de build, et être capable de les choisir dynamiquement...
=> le plus simple semble que l'outil puisse crééer les deux dans des fichiers séparés (ex .d et .d2p ou similaire)

NOTE: Le truc utilisé par Busby (créé un symlink pour retrouver la source dans l'étape de compilation) n'est pas nécessaire, il suffit d'écrire la pattern rule pour la compilation avec le fichier source comme premier prerequisite, et ça fonctionne avec ou sans VPATH.
-> try mkdir build, cd build, make -f ../Makefile.2pass-vpath test

NOTE: la régle de compilation %.o : %.f90 %.mod
peut être simplement %.o : %.f90 (comme dans c2pk) si les dépendances comprennent un règle %.o : %.mod pour chaque fichier source (voir dependencies/*.dmod2)
-> permet de ne pas avoir à changer la régle de compilation en fonction de si on fait un 2-pass build ou non

9. Alberto Otero de la Roza 's approach (2 stages + makedepf08 + anchor files)
NOTES on Alberto Otero de la Roza's makedepf08 and Makefile
-- makedepf08 --
- as written, it needs a recent version of /usr/bin/env that understand -S (~2018 for GNU env)
- as written, it needs GNU awk (because of the --traditional flag)
-> if I remove --traditional and use the default system awk (mawk on ubuntu 17),
it fails : 
mawk  -f makedepf08.awk *.f* */*.{f,F}*
mawk: cannot open one/  include "one_addone.inc" (No such file or directory)
-> on Mac, --traditional is not recognized and so the script simply exits (with success!) and does nothing
-> on Mac, without --traditional it works correctly (though different order of dependencies)
-> on Mac, awk is nawk (BWK awk) ("one-true-awk" on GitHub)
-- Makefile -- 
-> as written, need to remove --traditional on mac
-> find -regextype assumes GNU find (this is not essential since it is just used to create the list of source files.
-> for some reason make 3.82, 4.2.1, 4.2, 4.3 fail with 
gfortran   -c -J .mod -o four.o four.f90 four.F90
gfortran: fatal error: cannot specify -o with -c, -S or -E with multiple files
this might be related to the filesystem case-insensitivity ?..
-> if I rename all files to .F90 it still happens
-> it comes from the source argument to the compile command:
$(wildcard $(addprefix $*.,$(FORTEXT)))
if I replace that with $< and add %.F90 to the prerequisiste it works.

it really is related to the case-insensitivity: try in terminal
ls a.F90 a.f90, it returns both (!) even if there is only one file named a.F90


-> just as the 2 pass approach above, this approach causes recompilation of myprogram if only the implementation of mymodule is changed, because of the "touch $@" command for the anchor files
-> if I remove the touch command it seems to work but might not in parallel with bigger programs


Références:
https://gcc.gnu.org/bugzilla/show_bug.cgi?id=47495
https://www.cmcrossroads.com/article/rules-multiple-outputs-gnu-make
https://www.gnu.org/software/automake/manual/html_node/Multiple-Outputs.html
https://www.gnu.org/software/make/manual/html_node/Pattern-Intro.html#Pattern-Intro (last par)
https://www.gnu.org/software/make/manual/html_node/Multiple-Targets.html#Multiple-Targets (grouped targets new with make 4.3)
http://lagrange.mechse.illinois.edu/f90_mod_deps/ (même solution que Joost)
https://github.com/cp2k/cp2k/blob/master/Makefile
https://aoterodelaroza.github.io/devnotes/modern-fortran-makefiles/
