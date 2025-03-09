main:	main.o
	ld -o lab1 main.o

main.o:	lab1.asm
	nasm -felf64 -o main.o lab1.asm

test:
	make
	python3 test.py

.PHONY: clean
clean:
	rm -f *.o

