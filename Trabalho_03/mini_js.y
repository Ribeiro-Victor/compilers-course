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

vector<string> resolve_enderecos( vector<string> entrada ) {
    map<string,int> label;
    vector<string> saida;
    for( int i = 0; i < entrada.size(); i++ ) 
        if( entrada[i][0] == ':' ) 
            label[entrada[i].substr(1)] = saida.size();
        else
        saida.push_back( entrada[i] );
    
    for( int i = 0; i < saida.size(); i++ ) 
        if( label.count( saida[i] ) > 0 )
            saida[i] = to_string(label[saida[i]]);
        
    return saida;
}

string gera_label( string prefixo ) {
    static int n = 0;
    return prefixo + "_" + to_string( ++n ) + ":";
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

S : CMDs {  print( resolve_enderecos( $1.c + "." ) );  }
  ;

CMDs : CMDs CMD  { $$.c = $1.c + $2.c; }
     |           { $$.clear(); }
     ;

CMD : CMD_LET ';'
    | CMD_IF
    | CMD_IF_ELSE
    | CMD_FOR
    | CMD_WHILE
    | PRINT E ';'   { $$.c = $2.c + "print" + "#"; }
    | E ';'         { $$.c = $1.c + "^"; }
    | '{' CMDs '}'  { $$.c = $2.c; }
    | ';'           { $$.clear(); }
    ;

CMD_IF : IF '(' E ')' CMD
            {   string lbl_true = gera_label( "lbl_true" );
                string lbl_fim_if = gera_label( "lbl_fim_if" );
                string definicao_lbl_true = ":" + lbl_true;
                string definicao_lbl_fim_if = ":" + lbl_fim_if;

                $$.c = $3.c + 
                    lbl_true + "?" +
                    lbl_fim_if + "#" +
                    definicao_lbl_true + $5.c +
                    definicao_lbl_fim_if;
            }

CMD_IF_ELSE : IF '(' E ')' CMD ELSE CMD
                {   string lbl_true = gera_label( "lbl_true" );
                    string lbl_fim_if = gera_label( "lbl_fim_if" );
                    string definicao_lbl_true = ":" + lbl_true;
                    string definicao_lbl_fim_if = ":" + lbl_fim_if;
                                
                    $$.c = $3.c +                    // Codigo da expressão
                        lbl_true + "?" +             // Código do IF
                        $7.c + lbl_fim_if + "#" +    // Código do False
                        definicao_lbl_true + $5.c +  // Código do True
                        definicao_lbl_fim_if         // Fim do IF
                        ;
                }
            ;

CMD_FOR : FOR '(' PRIM_E ';' E ';' E ')' CMD 
        { string lbl_fim_for = gera_label( "fim_for" );
          string lbl_condicao_for = gera_label( "condicao_for" );
          string lbl_comando_for = gera_label( "comando_for" );
          string definicao_lbl_fim_for = ":" + lbl_fim_for;
          string definicao_lbl_condicao_for = ":" + lbl_condicao_for;
          string definicao_lbl_comando_for = ":" + lbl_comando_for;
          
          $$.c = $3.c + definicao_lbl_condicao_for +
                 $5.c + lbl_comando_for + "?" + lbl_fim_for + "#" +
                 definicao_lbl_comando_for + $9.c + 
                 $7.c + "^" + lbl_condicao_for + "#" +
                 definicao_lbl_fim_for;
        }
        ;

CMD_WHILE : WHILE '(' E ')' CMD
            {   string lbl_fim_while = gera_label( "fim_while" );
                string lbl_condicao_while = gera_label( "condicao_while" );
                string lbl_comando_while = gera_label( "comando_while" );
                string definicao_lbl_fim_while = ":" + lbl_fim_while;
                string definicao_lbl_condicao_while = ":" + lbl_condicao_while;
                string definicao_lbl_comando_while = ":" + lbl_comando_while;
                
                $$.c =  definicao_lbl_condicao_while +
                        $3.c + lbl_comando_while + "?" + lbl_fim_while + "#" +
                        definicao_lbl_comando_while + $5.c + 
                        lbl_condicao_while + "#" +
                        definicao_lbl_fim_while;
            }
          ;

PRIM_E : CMD_LET 
       | E  
         { $$.c = $1.c + "^"; }
       ;

CMD_LET : LET LET_VARs { $$.c = $2.c; }
        ;

LET_VARs : LET_VAR ',' LET_VARs { $$.c = $1.c + $3.c; } 
         | LET_VAR
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

LVALUEPROP : E '[' E ']'    { $$.c = $1.c + $3.c; }
           | E '.' ID       { $$.c = $1.c + $3.c; }
           ;

E :   LVALUE '=' E 
        {  $$.c = $1.c + $3.c + "="; }
    | LVALUEPROP '=' E 
        {  $$.c = $1.c + $3.c + "[=]"; }
    | E '<' E       { $$.c = $1.c + $3.c + $2.c; }
    | E '>' E       { $$.c = $1.c + $3.c + $2.c; }
    | E '+' E       { $$.c = $1.c + $3.c + $2.c; }
    | E '-' E       { $$.c = $1.c + $3.c + $2.c; }
    | E '*' E       { $$.c = $1.c + $3.c + $2.c; }
    | E '/' E       { $$.c = $1.c + $3.c + $2.c; }
    | E '%' E       { $$.c = $1.c + $3.c + $2.c; }
    | E IGUAL E     { $$.c = $1.c + $3.c + $2.c; }
    | '(' E ')'     { $$.c = $2.c; }
    | '[' ']'       { $$.c = vector<string>{"[]"}; }
    | LVALUE MAIS_MAIS
            { $$.c = $1.c + "@" + $1.c + $1.c + "@" + "1" + "+" + "=" + "^"; }
    | LVALUE MAIS_IGUAL E 
            { $$.c = $1.c + $1.c + "@" + $3.c + "+" + "=" ; }
    | LVALUEPROP MAIS_IGUAL E 
            { $$.c = $1.c + $1.c + "[@]" + $3.c + "+" + "[=]" ; }
    | CONST_INT
    | CONST_DOUBLE
    | CONST_STRING
    | '-' CONST_INT     { $$.c = "0" + $2.c + $1.c; }
    | '-' CONST_DOUBLE  { $$.c = "0" + $2.c + $1.c; }
    | LVALUE 
        { $$.c = $1.c + "@"; }
    | LVALUEPROP 
        { $$.c = $1.c + "[@]"; } 
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
