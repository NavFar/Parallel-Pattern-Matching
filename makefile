CC = g++
CFLAGS = -O3 -pipe -fomit-frame-pointer -funroll-all-loops -s
libDir = ./EasyBMP/
####################################################################
# _   _             _     _ 																			 #
#| \ | | __ ___   _(_) __| |																			 #
#|  \| |/ _` \ \ / / |/ _` |																			 #
#| |\  | (_| |\ V /| | (_| |																			 #
#|_| \_|\__,_| \_/ |_|\__,_|																			 #
#																																   #
# _____               _                               _            #
#|  ___|_ _ _ __ __ _| |__  _ __ ___   __ _ _ __   __| |           #
#| |_ / _` | '__/ _` | '_ \| '_ ` _ \ / _` | '_ \ / _` |           #
#|  _| (_| | | | (_| | | | | | | | | | (_| | | | | (_| |           #
#|_|  \__,_|_|  \__,_|_| |_|_| |_| |_|\__,_|_| |_|\__,_|           #
####################################################################
# .PHONY:EasyBMP serial
all: parallel serial
parallel:	EasyBMP.o parallel.cu
	nvcc $(libDir)EasyBMP.o parallel.cu -o parallel
serial: EasyBMP.o serial.cpp
	$(CC) $(CFLAGS) $(libDir)EasyBMP.o serial.cpp -o serial
EasyBMP.o: $(libDir)EasyBMP.cpp
	$(CC) $(CFLAGS) -c $(libDir)EasyBMP.cpp -o $(libDir)EasyBMP.o
libClean:
	rm -rf $(libDir)*.o
clean:
	rm -rf *.o
	rm -rf serial
	rm -rf parallel
