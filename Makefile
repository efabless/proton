1:
	\rm -f ./3RDBIN/._po*
	\rm -f ./3RDBIN/plan*
	\rm -f ./3RDBIN/eeRouter
	\rm -f ./3RDBIN/mpl
	svn update
	cp -rf /vol2/placer_release/mpl ./3RDBIN/mpl
	cp -rf /vol2/placer_release/plan_1 ./3RDBIN/plan_1
	cp -rf ../plan_5/plan_5 ./3RDBIN/plan_5
	cp ../plan_6/plan_6 ./3RDBIN/plan_6
	./UTILS/make_tool
	#export EQATOR_HOME=`pwd` ; cd ../placer ; cvs update -d ; make clean ; make
	#export EQATOR_HOME=`pwd` ; cd ../plan_3 ; cvs update -d ; make clean ; make
	#export EQATOR_HOME=`pwd` ; cd ../plan_4 ; cvs update -d ; make clean ; make
	export EQATOR_HOME=`pwd` ; cd ../hRoute ; svn update ; make clean ; make exe ; cp eeRouter ../proton/3RDBIN/ ; cp ._po* ../proton/3RDBIN/
	\rm -rf mpl ;ln -s ./3RDBIN/mpl .
	\rm -rf plan_1 ;ln -s ./3RDBIN/plan_1 .
	#\rm -rf plan_2 ;ln -s ./3RDBIN/plan_2 .
	#\rm -rf plan_3 ;ln -s ./3RDBIN/plan_3 .
	#\rm -rf plan_4 ;ln -s ./3RDBIN/plan_4 .
	\rm -rf plan_5 ;ln -s ./3RDBIN/plan_5 .
	\rm -rf plan_6 ;ln -s ./3RDBIN/plan_6 .
	\rm -rf placerGui ;ln -s ./3RDBIN/placerGui .
	\rm -rf eeRouter ;ln -s ./3RDBIN/eeRouter .
	\rm -rf gr1 ;ln -s ./3RDBIN/gr1 .
	chmod +x plan_1 eeRouter mpl ./3RDBIN/plan_1 ./3RDBIN/eeRouter ./3RDBIN/mpl
	\rm -rf eqator.log* ; cd ~/ ; \rm -rf eqator.log*
