
CC = gcc
CFLAGS = -Wall -g 

myprog: a.o
	$(CC) $(CFLAGS) -o $@ $^
a.o: a.c
	$(CC) $(CFLAGS) -c -o $@ $<
stats_function.o: stats_function.c
	$(CC) $(CFLAGS) -c -o $@ $<
	
.PHONY : clean
clean :
	rm a.o stats_function.o

