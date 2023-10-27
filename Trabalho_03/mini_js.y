%{
#include <iostream>
#include <string>
#include <vector>
#include <map>

using namespace std;

void yyerror(const char *);
void print( vector<string> s );

int linha = 1, coluna = 1; 

struct Atributos {
//   string v;
    vector<string> c; // Código
    int linha = 0, coluna = 0;
    void clear() {
        c.clear();
        linha = 0;
        coluna = 0;
    }
};

// Tipo dos atributos: YYSTYPE é o tipo usado para os atributos.
#define YYSTYPE Atributos

extern "C" int yylex();
int yyparse();

vector<string> concatena( vector<string> a, vector<string> b ) {
    a.insert( a.end(), b.begin(), b.end() );
    return a;
}

vector<string> operator+( vector<string> a, vector<string> b ) {
    return concatena( a, b );
}

vector<string> operator+( vector<string> a, string b ) {
    a.push_back( b );
    return a;
}

vector<string> operator+( string a, vector<string> b ) {
    return vector<string>{ a } + b;
}



%}

%token ID IF ELSE LET VAR CONST PRINT FOR WHILE
%token CONST_INT CONST_DOUBLE CONST_STRING
%token AND OR ME_IG MA_IG DIF IGUAL
%token MAIS_IGUAL MENOS_IGUAL MAIS_MAIS

%right '='
%nonassoc '<' '>'
%left '+' '-'
%left '*' '/' '%'

%left '['
%left '.'

%%

S : CMDs { print(  $1.c  ); print( vector<string> {"."}); }
  ;

CMDs : CMDs CMD  { $$.c = $1.c + $2.c; }
     |           { $$.clear(); }
     ;

CMD : CMD_LET ';'
    | E ';' { $$.c = $1.c + "^"; }
    ;

CMD_LET : LET LET_VARs { $$.c = $2.c; }
        ;

LET_VARs : LET_VAR ',' LET_VARs { $$.c = $1.c + $3.c; } 
     |     LET_VAR
     ;

LET_VAR : ID  
            { $$.c = $1.c + "&"; }
        | ID '=' E
            { $$.c = $1.c + "&" + $1.c + $3.c + "=" + "^"; }
        | ID '=' '{' '}'
            { $$.c = $1.c + "&" + $1.c + "{}" + "=" + "^"; }
        | ID '=' '[' ']'
            { $$.c = $1.c + "&" + $1.c + "[]" + "=" + "^"; }
    ;

LVALUE : ID 
       ;

E : LVALUE '=' E 
        {  $$.c = $1.c + $3.c + "="; }
  | E '<' E     { $$.c = $1.c + $3.c + $2.c; }
  | E '>' E     { $$.c = $1.c + $3.c + $2.c; }
  | E '+' E     { $$.c = $1.c + $3.c + $2.c; }
  | E '-' E     { $$.c = $1.c + $3.c + $2.c; }
  | E '*' E     { $$.c = $1.c + $3.c + $2.c; }
  | E '/' E     { $$.c = $1.c + $3.c + $2.c; }
  | E '%' E     { $$.c = $1.c + $3.c + $2.c; }
  | '(' E ')'   { $$.c = $2.c; }
  | LVALUE MAIS_IGUAL E 
        { $$.c = $1.c + $1.c + "@" + $3.c + "+" + "=" ; }
  | CONST_INT
  | CONST_DOUBLE
  | CONST_STRING
  | LVALUE 
    { $$.c = $1.c + "@"; } 
 ;


%%

#include "lex.yy.c"

void yyerror( const char* st ) {
   puts( st ); 
   printf( "Proximo a: %s\n", yytext );
   exit( 0 );
}

void print( vector<string> codigo ) {
    for( string s : codigo )
        cout << s << " ";
    cout << endl;  
}

int main( int argc, char* argv[] ) {
  yyparse();
  return 0;
}
