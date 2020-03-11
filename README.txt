
Il y a plusieurs choses qu'on veut faire:
A. génération automatique des dépendances
B. Utiliser les fonctionnalités de génération des dépendances du compilateur si possible
C. Si on change l'implémentation d'une fonction /subrotuine dans un module, ne recompiler que ce module et relinker.
D. 2 pass compile

A. idéalement le compilateur a une foncitonnalité pour faire que ça, et ça fonctionne from scratch. avec gfortran ce n'est pas le cas, il lui faut les .mod.
C'est possible d'utiiser la fait que make se restart pour créer tous les fichiers de dépendances jusqu'au feuilles de l'arbre, mais irréaliste pour un gros programme.
Donc dans ce cas il faut un outil séparé pour le faire (ex. makdep de CICE, makedepf08, makedepf90..)

B. une fois qu'on a généré les dépendances une première fois, il serait bien d'utiliser les fonctionnalités du compilateur par la suite afin d'éviter de toujorus invoquer un outil séparé (c'est à cause de ça que j'avais choisi l'implémentation avec les .di (initial dependencies) et les .d (générées en même temps que la compilation)

C. -> il faut que le compilateur de modifie pas le timestamp du .mod si l'interface ne change pas. (gfortran agit comme ça)



--- PISTES DE SOLUTIONS POUR A. ---
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

avec make 4.1
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

6. Exemple de Joost
->fonctionne correctement !! 
-> la seule chose est que la "fake rule" est exécutée si on change l'implémentation, make et remake (donc on ne voit pas "nothing to do for 'all'"





Références:
https://gcc.gnu.org/bugzilla/show_bug.cgi?id=47495
https://www.cmcrossroads.com/article/rules-multiple-outputs-gnu-make
https://www.gnu.org/software/automake/manual/html_node/Multiple-Outputs.html
https://www.gnu.org/software/make/manual/html_node/Pattern-Intro.html#Pattern-Intro (last par)
https://www.gnu.org/software/make/manual/html_node/Multiple-Targets.html#Multiple-Targets (grouped targets new with make 4.3)