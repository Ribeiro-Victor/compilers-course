%{
#include <iostream>
#include <string>
#include <vector>
#include <map>

using namespace std;

void yyerror(const char *);
void print( string s );

int linha = 1, coluna = 1; 

struct Atributos {
  string v;
  int linha = 0, coluna = 0;
};

// Tipo dos atributos: YYSTYPE é o tipo usado para os atributos.
#define YYSTYPE Atributos

extern "C" int yylex();
int yyparse();
%}

%token ID IF ELSE LET VAR CONST PRINT FOR WHILE
%token CONST_INT CONST_DOUBLE CSTRING
%token AND OR ME_IG MA_IG DIF IGUAL
%token MAIS_IGUAL MENOS_IGUAL MAIS_MAIS

%right '='
%nonassoc '<' '>'
%left '+' '-'
%left '*' '/' '%'

%left '['
%left '.'

%%

S   : LET ID { print( $2.v ); } '=' CONST_INT { print( $5.v ); print( "=" ); } ';' 
    ;

%%

#include "lex.yy.c"

void yyerror( const char* st ) {
   puts( st ); 
   printf( "Proximo a: %s\n", yytext );
   exit( 0 );
}

void print( string s ) {
  cout << s << " ";
}

int main( int argc, char* argv[] ) {
  yyparse();
  return 0;
}
