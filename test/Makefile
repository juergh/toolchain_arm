hello: hello.o
	$(CC) -o hello hello.o
	@file hello
	@$(READELF) -d hello | grep NEEDED

clean:
	-rm -f hello hello.o *~
