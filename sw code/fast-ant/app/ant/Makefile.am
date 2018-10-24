## Process this file with automake to produce Makefile.in


bin_PROGRAMS =  \
	ant

ant_SOURCES =  \
	main_ant.c \
	../../include/fast.h

ant_LDADD = -L../../lib/libant \
	-L../../lib/libua \
	-L../../lib/librule \
	-L../../lib/libreg  \
	-lant \
	-lua \
	-lrule \
	-lreg \
	-lpthread
	 
