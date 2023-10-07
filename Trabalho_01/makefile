all: saida entrada.txt
	./saida < entrada.txt

lex.yy.c: scan.lex
	lex scan.lex

saida: lex.yy.c 
	g++ -Wall -std=c++17 main.cc -o saida -lfl  
	
clean:
	rm saida lex.yy.c