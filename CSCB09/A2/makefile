CC = gcc
CFLAGS = -Wall -g -Werror

myprog: A2.o
	$(CC) $(CFLAGS) -o $@ $^
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<
clean:
	rm *.o
.PHONY: clean