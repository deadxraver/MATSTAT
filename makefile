ASM=nasm
COMP_FLAGS=-felf64
DEB_FLAGS=-g -F dwarf

main:	main.o
	ld -o lab1 main.o

debug:	deb.o
	ld -o lab1-deb deb.o

deb.o:	lab1.asm
	nasm $(COMP_FLAGS) $(DEB_FLAGS) -o deb.o lab1.asm

main.o:	lab1.asm
	nasm $(COMP_FLAGS) -o main.o lab1.asm

test:
	make
	python3 test.py

.PHONY: clean
clean:
	rm -f *.o
	rm -f lab1-deb
