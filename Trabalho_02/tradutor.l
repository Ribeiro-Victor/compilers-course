%{
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <map>

using namespace std;

int token;
string lexema;

void casa( int );
void A();
void E();
void T();
void E_linha();
void T_linha();
void F();
void S();
void U();

enum { tk_id = 256, tk_cte_int, tk_cte_real, tk_print, tk_string};

map<int,string> nome_tokens = {
  { tk_id, "nome de identificador" },
  { tk_cte_int, "constante inteira"},
  { tk_cte_real, "constante real"},
  { tk_print, "função print"},
  { tk_string, "string"}
};

%}

WS	      [ \n\t]
DIGITO	  [0-9]
LETRA	    [A-Za-z_]

NUM_INT	  {DIGITO}+
NUM_REAL  {DIGITO}+"."{DIGITO}+
ID	      {LETRA}({LETRA}|{DIGITO})*
STRING    ["](([^"]|\\\")*(\"\")?([^"]|\\\")*)["]

%%

{WS}  		    { }
{NUM_INT} 		{ lexema = yytext;  return tk_cte_int; }
{NUM_REAL} 		{ lexema = yytext;  return tk_cte_real; }
"print"       { lexema = yytext;  return tk_print;}
{STRING}      { lexema = yytext;  return tk_string; }
{ID}		      { lexema = yytext;  return tk_id; }

.		          { return yytext[0]; }

%%

int next_token() {
  return yylex();
}

string nome_token( int token ) {
  if( nome_tokens.find( token ) != nome_tokens.end() )
    return nome_tokens[token];
  else {
    string r;
    
    r = token;
    return r;
  }
}

void print(string text){
  cout << text << " ";
}

void casa( int esperado ) {
  if( token == esperado ){
    token = next_token();
  }
  else {
      cout << "Esperado " << nome_token( esperado ) 
	   << " , encontrado: " << nome_token( token ) << endl;
    exit( 1 );
  }
}

void S(){
  switch (token){
      case tk_id: A(); casa( ';' ); S(); break;
      case tk_print: casa( tk_print ); E(); print( "print #"); break;
  }
}

void A() {
// Guardamos o lexema pois a função 'casa' altera o seu valor.
  string temp = lexema; 
  casa( tk_id );
  print( temp );
  casa( '=' );
  E();
  print( "= ^" );
}

void E() {
  T();
  E_linha();
}

void E_linha() {
  switch( token ) {
    case '+' : casa( '+' ); T(); print( "+" ); E_linha(); break;
    case '-' : casa( '-' ); T(); print( "-" ); E_linha(); break;
  }
}

void T() {
  U();
  T_linha();
}

void U(){
  switch( token ) {
    case '+' : casa( '+' ); U(); break;
    case '-' : print( "0" ); casa( '-' ); U(  ); print( "-" ); break;
    default: F();
  }
}

void T_linha() {
  switch( token ) {
    case '*' : casa( '*' ); U(); print( "*"); T_linha(); break;
    case '/' : casa( '/' ); U(); print( "/"); T_linha(); break;
  }
}

void F() {
  switch( token ) {
    case tk_id : {
      string temp = lexema;
      casa( tk_id ); print( temp + " @" ); 
    } 
    break;
    
    case tk_cte_int : {
      string temp = lexema;
      casa( tk_cte_int ); print( temp ); 
    }
    break;
    
    case tk_cte_real:{
      string temp = lexema;
      casa( tk_cte_real  ); print( temp ); 
    }
    break;

    case '(': 
      casa( '(' ); E(); casa( ')' ); 
    break;
    
    case tk_string:{
      string temp = lexema;
      casa( tk_string ); print( temp );
    }
    break;    
    default:
      print( "ERRO: Operando esperado, encontrado " + lexema );
  }
}


int main() {
  token = next_token();
  S();
  /*if( token == 0 )
    cout << "Sintaxe ok!" << endl;
  else
    cout << "Caracteres encontrados após o final do programa" << endl;*/
  
  return 0;
}
