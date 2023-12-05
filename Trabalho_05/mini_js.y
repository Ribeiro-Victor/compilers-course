%{
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <map>

using namespace std;

void yyerror(const char *);
void print( vector<string> s );

int linha = 1, coluna = 1;
int count_params = 0;
int dentro_da_funcao = 0;

struct Atributos {
    vector<string> c; // Código
    int linha = 0, coluna = 0;
    int contador = 0; // Só para argumentos e parâmetros
    vector<string> valor_default;
    void clear() {
        c.clear();
        linha = 0;
        coluna = 0;
        contador = 0;
        valor_default.clear();
    }
};

enum TipoDecl { Let = 1, Const, Var };
map<TipoDecl, string> nomeTipoDecl = { 
  { Let, "let" }, 
  { Const, "const" }, 
  { Var, "var" }
};

struct Simbolo {
    TipoDecl tipo;
    int linha;
    int coluna;
};

vector< map< string, Simbolo > > ts = { map< string, Simbolo >{} }; // Tabela de símbolos 
vector<string> funcoes;

vector<string> declara_var( TipoDecl tipo, string nome, int linha, int coluna );
void checa_simbolo( string nome, bool modificavel );

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

vector<string> operator+=( vector<string>& a, string b ) {
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

void checa_retorno(){
  if(dentro_da_funcao == 0){
    cerr << "Erro: Não é permitido 'return' fora de funções." << endl;
    exit( 1 );
  }
}

%}

%token ID IF ELSE LET VAR CONST PRINT FOR WHILE SETA PARENTESES_FUNCAO SETA_CHAVES
%token CONST_INT CONST_DOUBLE CONST_STRING
%token AND OR ME_IG MA_IG DIF IGUAL FUNCTION RETURN ASM
%token MAIS_IGUAL MENOS_IGUAL MAIS_MAIS MENOS_MENOS TRUE FALSE

%right '=' SETA

%nonassoc '<' '>' ME_IG MA_IG DIF IGUAL AND OR
%nonassoc MAIS_IGUAL MENOS_IGUAL MAIS_MAIS MENOS_MENOS

%left '+' '-'
%left '*' '/' '%'
%right '[' '('
%left '.'

%%

S : CMDs {  print( resolve_enderecos( $1.c + "." + funcoes ) );  }
  ;

CMDs : CMDs CMD  { $$.c = $1.c + $2.c; }
     |           { $$.clear(); }
     ;

CMD : CMD_LET   ';'
    | CMD_VAR   ';'
    | CMD_CONST ';'
    | CMD_IF
    | CMD_IF_ELSE
    | CMD_FOR
    | CMD_WHILE
    | CMD_FUNC
    | RETURN E ';'  { checa_retorno(); $$.c = $2.c + "'&retorno'" + "@" + "~"; }
    | RETURN OBJ ';'{ checa_retorno(); $$.c = $2.c + "'&retorno'" + "@" + "~"; }
    | E ASM ';' 	{ $$.c = $1.c + $2.c + "^"; }
    /* | PRINT E ';'   { $$.c = $2.c + "print" + "#"; } */
    | E ';'         { $$.c = $1.c + "^"; }
    | '{' EMPILHA_TS CMDs '}'  
        {   ts.pop_back();
            $$.c = "<{" + $3.c + "}>"; 
        }
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
       | CMD_VAR
       | CMD_CONST
       | E  { $$.c = $1.c + "^"; }
       ;

EMPILHA_TS : { ts.push_back( map< string, Simbolo >{} ); } 
           ;
    
CMD_FUNC : FUNCTION ID { declara_var( Var, $2.c[0], $2.linha, $2.coluna ); dentro_da_funcao += 1; } 
             '(' EMPILHA_TS LISTA_PARAMs ')' '{' CMDs '}'
           { 
             string lbl_endereco_funcao = gera_label( "func_" + $2.c[0] );
             string definicao_lbl_endereco_funcao = ":" + lbl_endereco_funcao;
             
             $$.c = $2.c + "&" + $2.c + "{}"  + "=" + "'&funcao'" +
                    lbl_endereco_funcao + "[=]" + "^";
             funcoes = funcoes + definicao_lbl_endereco_funcao + $6.c + $9.c +
                       "undefined" + "@" + "'&retorno'" + "@"+ "~";
             ts.pop_back();
             dentro_da_funcao -= 1; 
           }
         ;

FUNC_ANONIMA: FUNCTION '(' EMPILHA_TS { dentro_da_funcao += 1; } LISTA_PARAMs ')' '{' CMDs '}'
              {
                string lbl_endereco_funcao = gera_label( "func_anonima" );
                string definicao_lbl_endereco_funcao = ":" + lbl_endereco_funcao;

                $$.c = vector<string>{"{}"} + "'&funcao'" + lbl_endereco_funcao + "[<=]";
                funcoes = funcoes + definicao_lbl_endereco_funcao + $5.c + $8.c +
                       "undefined" + "@" + "'&retorno'" + "@"+ "~";
                ts.pop_back();
                dentro_da_funcao -= 1; 
              }
            ;
         
LISTA_PARAMs : PARAMs
           | EMPILHA_TS { $$.clear(); }
           ;
           
PARAMs: PARAMs ',' PARAM
        {   // a & a arguments @ 0 [@] = ^
            declara_var( Let, $3.c[0], $3.linha, $3.coluna );

            $$.c = $1.c + $3.c + "&" + $3.c + "arguments" + "@" + to_string( $1.contador )
                + "[@]" + "=" + "^";  
                
            if( $3.valor_default.size() > 0 ) {
                // Gerar código para testar valor default.
                string lbl_true = gera_label( "lbl_true" );
                string lbl_fim_if = gera_label( "lbl_fim_if" );
                string definicao_lbl_true = ":" + lbl_true;
                string definicao_lbl_fim_if = ":" + lbl_fim_if;
                            
                $$.c = $$.c + 
                    $3.c + "@" + "undefined" + "@" + "==" +     // Codigo da expressão
                    lbl_true + "?" +                            // Código do IF
                    lbl_fim_if + "#" +                          // Código do False
                    definicao_lbl_true + $3.c + $3.valor_default + "=" + "^" + // Código do True
                    definicao_lbl_fim_if;         // Fim do IF
            }
            $$.contador = $1.contador + $3.contador; 
        }
    | PARAM 
        {
            ts.push_back( map< string, Simbolo >{} ); 
            declara_var( Let, $1.c[0], $1.linha, $1.coluna );
            
            $$.c = $1.c + "&" + $1.c + "arguments" + "@" + "0" + "[@]" + "=" + "^";
            if( $1.valor_default.size() > 0 ) {
                string lbl_true = gera_label( "lbl_true" );
                string lbl_fim_if = gera_label( "lbl_fim_if" );
                string definicao_lbl_true = ":" + lbl_true;
                string definicao_lbl_fim_if = ":" + lbl_fim_if;
                            
                $$.c = $$.c + 
                    $1.c + "@" + "undefined" + "@" + "==" +     // Codigo da expressão
                    lbl_true + "?" +                            // Código do IF
                    lbl_fim_if + "#" +                          // Código do False
                    definicao_lbl_true + $1.c + $1.valor_default + "=" + "^" + // Código do True
                    definicao_lbl_fim_if;         // Fim do IF
            }
            $$.contador = $1.contador; 
        }
     ;
     
PARAM : ID
        {   $$.c = $1.c;      
            $$.contador = 1;
            $$.valor_default.clear();  }
      | ID '=' E
        { 
            $$.c = $1.c;
            $$.contador = 1;
            $$.valor_default = $3.c;         
        }
      ;


CAMPOs  : CAMPO ',' CAMPOs
            { $$.c = $1.c + "[<=]" + $3.c; }
        | CAMPO
            { $$.c = $1.c + "[<=]"; }
        ;

CAMPO   : ID ':' E
            { $$.c = $1.c + $3.c; }
        | ID ':' OBJ
            { $$.c = $1.c + $3.c; }
        ;

OBJ : '{' CAMPOs '}'
        { $$.c = vector<string>{"{}"} + $2.c; }
    | '{' '}'
        { $$.c = vector<string>{"{}"}; }
    ;

CMD_LET : LET LET_VARs { $$.c = $2.c; }
        ;

LET_VARs : LET_VAR ',' LET_VARs { $$.c = $1.c + $3.c; } 
         | LET_VAR
         ;

LET_VAR : ID  
            { $$.c = declara_var( Let, $1.c[0], $1.linha, $1.coluna ); }
        | ID '=' E
            { $$.c = declara_var( Let, $1.c[0], $1.linha, $1.coluna ) + 
                     $1.c + $3.c + "=" + "^"; }
        | ID '=' OBJ
            { $$.c = declara_var( Let, $1.c[0], $1.linha, $1.coluna ) +
                     $1.c + $3.c + "=" + "^"; }
        ;

CMD_VAR : VAR VAR_VARs { $$.c = $2.c; }
        ;

VAR_VARs : VAR_VAR ',' VAR_VARs { $$.c = $1.c + $3.c; } 
         | VAR_VAR
         ;

VAR_VAR : ID  
            { $$.c = declara_var( Var, $1.c[0], $1.linha, $1.coluna ); }
        | ID '=' E
            { $$.c = declara_var( Var, $1.c[0], $1.linha, $1.coluna ) + 
                     $1.c + $3.c + "=" + "^"; }
        | ID '=' OBJ
            { $$.c = declara_var( Var, $1.c[0], $1.linha, $1.coluna ) +
                     $1.c + $3.c + "=" + "^"; }
        ;

CMD_CONST   : CONST CONST_VARs { $$.c = $2.c; }
            ;

CONST_VARs  : CONST_VAR ',' CONST_VARs { $$.c = $1.c + $3.c; } 
            | CONST_VAR
            ;

CONST_VAR   : 
            | ID '=' E
                { $$.c = declara_var( Const, $1.c[0], $1.linha, $1.coluna ) + 
                        $1.c + $3.c + "=" + "^"; }
            | ID '=' OBJ
            { $$.c = declara_var( Const, $1.c[0], $1.linha, $1.coluna ) +
                     $1.c + $3.c + "=" + "^"; }
            ;


/* LVALUE : ID 
       ; */

LVALUEPROP : E '[' E ']'    { $$.c = $1.c + $3.c; }
           | E '.' ID       { $$.c = $1.c + $3.c; }
           ;

E :   ID '=' E 
        { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $3.c + "="; }
    | ID '=' OBJ
        { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $3.c + "="; }
    | LVALUEPROP '=' E 
        {  $$.c = $1.c + $3.c + "[=]"; }
    | LVALUEPROP '=' OBJ
        {  $$.c = $1.c + $3.c + "[=]"; }
    | E '<' E       { $$.c = $1.c + $3.c + $2.c; }
    | E '>' E       { $$.c = $1.c + $3.c + $2.c; }
    | E '+' E       { $$.c = $1.c + $3.c + $2.c; }
    | E '-' E       { $$.c = $1.c + $3.c + $2.c; }
    | E '*' E       { $$.c = $1.c + $3.c + $2.c; }
    | E '/' E       { $$.c = $1.c + $3.c + $2.c; }
    | E '%' E       { $$.c = $1.c + $3.c + $2.c; }
    | E IGUAL E     { $$.c = $1.c + $3.c + $2.c; }
    | E ME_IG E     { $$.c = $1.c + $3.c + $2.c; }
    | E MA_IG E     { $$.c = $1.c + $3.c + $2.c; }
    | E DIF E       { $$.c = $1.c + $3.c + $2.c; }
    | E AND E       { $$.c = $1.c + $3.c + $2.c; }
    | E OR E        { $$.c = $1.c + $3.c + $2.c; }
    | TRUE          { $$.c = $1.c; }
    | FALSE         { $$.c = $1.c; }
    | '(' E ')'     { $$.c = $2.c; }
    | ID MAIS_MAIS
            { $$.c = $1.c + "@" + $1.c + $1.c + "@" + "1" + "+" + "=" + "^"; }
    | ID MENOS_MENOS
            { $$.c = $1.c + "@" + $1.c + $1.c + "@" + "1" + "-" + "=" + "^"; }
    | ID MAIS_IGUAL E 
            { $$.c = $1.c + $1.c + "@" + $3.c + "+" + "=" ; }
    | ID MENOS_IGUAL E 
            { $$.c = $1.c + $1.c + "@" + $3.c + "-" + "=" ; } 
    | LVALUEPROP MAIS_MAIS
            { $$.c = $1.c + "[@]" + $1.c + $1.c + "[@]" + "1" + "+" + "[=]" + "^"; }
    | LVALUEPROP MENOS_MENOS
            { $$.c = $1.c + "[@]" + $1.c + $1.c + "[@]" + "1" + "-" + "[=]" + "^"; }
    | LVALUEPROP MAIS_IGUAL E 
            { $$.c = $1.c + $1.c + "[@]" + $3.c + "+" + "[=]" ; }
    | LVALUEPROP MENOS_IGUAL E 
            { $$.c = $1.c + $1.c + "[@]" + $3.c + "-" + "[=]" ; }
    /* | LVALUE 
        { $$.c = $1.c + "@"; } */
    | LVALUEPROP 
        { $$.c = $1.c + "[@]"; }
    | E '(' LISTA_ARGs ')'
        { $$.c = $3.c + to_string( $3.contador ) + $1.c + "$"; }
    | '[' ELEMENTOS_ARRAY ']'
        { $$.c = vector<string>{"[]"} + $2.c; }
    | FUNC_ANONIMA
        { $$.c = $1.c; }
    | ID EMPILHA_TS { declara_var( Let, $1.c[0], $1.linha, $1.coluna ); dentro_da_funcao += 1;} SETA E 
        { 
            string lbl_endereco_funcao = gera_label( "func_seta" );
            string definicao_lbl_endereco_funcao = ":" + lbl_endereco_funcao;
            vector<string>arg =  $1.c + "&" + $1.c + "arguments" + "@" + "0" + "[@]" + "=" + "^";
            $$.c = vector<string>{"{}"} + "'&funcao'" + lbl_endereco_funcao + "[<=]";
            funcoes = funcoes + definicao_lbl_endereco_funcao + arg + $5.c + "'&retorno'" + "@" + "~";
            ts.pop_back();
            dentro_da_funcao -= 1;
        }
    | '(' LISTA_PARAMs { dentro_da_funcao += 1; } PARENTESES_FUNCAO SETA E 
        { 
            string lbl_endereco_funcao = gera_label( "func_seta" );
            string definicao_lbl_endereco_funcao = ":" + lbl_endereco_funcao;
            vector<string>arg = $2.c;
            $$.c = vector<string>{"{}"} + "'&funcao'" + lbl_endereco_funcao + "[<=]";
            funcoes = funcoes + definicao_lbl_endereco_funcao + arg + $6.c + "'&retorno'" + "@" + "~";
            ts.pop_back();
            dentro_da_funcao -= 1; 
        }
    | ID EMPILHA_TS { declara_var( Let, $1.c[0], $1.linha, $1.coluna ); dentro_da_funcao += 1; } SETA_CHAVES CMDs '}'
    { 
      string lbl_endereco_funcao = gera_label( "funcanon" );
      string definicao_lbl_endereco_funcao = ":" + lbl_endereco_funcao;
      vector<string>arg =  $1.c + "&" + $1.c + "arguments" + "@" + "0" + "[@]" + "=" + "^";
      $$.c = vector<string>{"{}"} + "'&funcao'" + lbl_endereco_funcao + "[<=]";
      funcoes = funcoes + definicao_lbl_endereco_funcao + arg + $5.c;
      ts.pop_back();
      dentro_da_funcao -= 1;
    }
    | '-' T
        { $$.c = "0" + $2.c + $1.c; }
    | T
    ;

T   : CONST_INT
    | CONST_DOUBLE
    | CONST_STRING
    | '(' OBJ ')'
    | ID { checa_simbolo( $1.c[0], false ); $$.c = $1.c + "@"; } 
    ;


LISTA_ARGs: ARGs
            | { $$.clear(); }
            ;

ARGs: ARGs ',' E
        { $$.c = $1.c + $3.c;
         $$.contador += 1; }
    | ARGs ',' '{' '}'
        { $$.c = $1.c + "{}"; 
          $$.contador += 1;}
    | E
        { $$.c = $1.c;
         $$.contador = 1; }
    ;

ELEMENTOS_ARRAY : ELEMENTOs
                | { $$.clear(); }
                ;

ELEMENTOs: ELEMENTOs ',' E
            { $$.c = $1.c + to_string( $$.contador ) + $3.c + "[<=]"; 
              $$.contador += 1;}
         | E
            { $$.c = to_string( $$.contador ) + $1.c + "[<=]"; 
              $$.contador += 1; }
         | ELEMENTOs ',' OBJ
            { $$.c = $1.c + to_string( $$.contador ) + $3.c + "[<=]"; 
              $$.contador += 1;}
         | OBJ
            { $$.c = to_string( $$.contador ) + $1.c + "[<=]"; 
              $$.contador += 1; }
         ;

%%

#include "lex.yy.c"

vector<string> declara_var( TipoDecl tipo, string nome, int linha, int coluna ) {
        
    auto& topo = ts.back();    

    if( topo.count( nome ) == 0 ) {
        topo[nome] = Simbolo{ tipo, linha, coluna };
        return vector<string>{ nome, "&" };
    }
    else if( tipo == Var && topo[nome].tipo == Var ) {
        topo[nome] = Simbolo{ tipo, linha, coluna };
        return vector<string>{};
    } 
    else {
        cerr << "Erro: a variável '" << nome << "' já foi declarada na linha " << topo[nome].linha 
            << "." << endl;
        exit( 1 );     
    }
}

void checa_simbolo( string nome, bool modificavel ) {
    for( int i = ts.size() - 1; i >= 0; i-- ) {  
        auto& atual = ts[i];

        if( atual.count( nome ) > 0 ) {
            if( modificavel && atual[nome].tipo == Const ) {
            cerr << "Erro: a variável '" << nome << "' não pode ser modificada." << endl;
            exit( 1 );     
            }
            else 
                return;
        }
    }

    if (dentro_da_funcao == 0 && nome != "undefined"){
        cerr << "Erro: a variável '" << nome << "' não foi declarada." << endl;
        exit( 1 );  
    }
}

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
