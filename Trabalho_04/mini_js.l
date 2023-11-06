%{
    int token( int tk );
%}

DIGITO      [0-9]
LETRA	      [A-Za-z_]
INT	        {DIGITO}+
DOUBLE      {DIGITO}+"."{DIGITO}+([Ee][+\-]?{DIGITO}+)?
ID          (_|{LETRA})({LETRA}|{DIGITO})*
STRING_DB   ["](([^"]|\\\")*(\"\")?([^"]|\\\")*)["]
STRING_SNG  ['](([^']|\\\')*(\'\')?([^']|\\\')*)[']
STRING      ({STRING_SNG}|{STRING_DB})

%%

" "         { coluna++; }
"\t"        { coluna += 4; }
"\n"        { linha++; coluna = 1; }

{INT}       { return token( CONST_INT ); }
{DOUBLE}    { return token( CONST_DOUBLE ); }
{STRING}    { return token( CONST_STRING ); }   

"let"       { return token( LET ); }
"const"     { return token( CONST ); }
"var"       { return token( VAR ); }
"print"     { return token( PRINT ); }
"if"        { return token( IF ); }
"else"      { return token( ELSE ); }
"for"       { return token( FOR ); }
"while"     { return token( WHILE ); }

"&&"        { return token( AND ); }
"||"        { return token( OR ); }
"<="        { return token( ME_IG ); }
">="        { return token( MA_IG ); }
"!="        { return token( DIF ); }
"=="        { return token( IGUAL ); }  
"+="        { return token( MAIS_IGUAL ); }
"-="        { return token( MENOS_IGUAL ); }
"++"        { return token( MAIS_MAIS ); }
"--"        { return token( MENOS_MENOS ); }

{ID}        { return token( ID ); }

.           { return token( *yytext ); }

%%

int token( int tk ) {  
    yylval.c = vector<string>{ yytext };
    coluna += strlen( yytext );
    yylval.linha = linha;
    yylval.coluna = coluna;
    return tk;
}