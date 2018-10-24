## Process this file with automake to produce Makefile.in


bin_PROGRAMS =  \
	l2switch

l2switch_SOURCES =  \
	main_l2switch.c \
	../../include/fast.h

l2switch_LDADD = -L../../lib/libua \
	-L../../lib/librule \
	-L../../lib/libreg  \
	-lua \
	-lrule \
	-lreg \
	-lpthread
	 
