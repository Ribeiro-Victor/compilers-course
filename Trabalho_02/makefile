mpl: tradutor entrada.txt 
	./mpl.out < ./tradutor.out < entrada.txt

all: tradutor entrada.txt
	./tradutor.out < entrada.txt

lex.yy.c: tradutor.l
	lex tradutor.l

tradutor: lex.yy.c 
	g++ lex.yy.c -o tradutor.out -ll  
	
clean:
	rm tradutor.out lex.yy.c