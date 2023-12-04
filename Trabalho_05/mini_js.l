%{
    int token( int tk );
    string trim( char*, string);
    vector<string> tokeniza(string);
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

"asm{".*"}"  {  string lexema = trim( yytext + 3, "{}" );
                yylval.c = tokeniza( lexema );
                coluna += strlen( yytext ); 
                yylval.linha = linha;
                yylval.coluna = coluna;
                return ASM; }
"function"  { return token( FUNCTION ); }
"return"    { return token( RETURN ); }
"let"       { return token( LET ); }
"const"     { return token( CONST ); }
"var"       { return token( VAR ); }
    /* "print"     { return token( PRINT ); } */
"if"        { return token( IF ); }
"else"      { return token( ELSE ); }
"for"       { return token( FOR ); }
"while"     { return token( WHILE ); }
"=>"        { return token(SETA); }
")"/(.)*"=>"  { return token(PARENTESES_FUNCAO); }

"=>"[ \n\s\t]*"{"  { return token(SETA_CHAVES); }

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
"true"      { return token( TRUE ); }
"false"     { return token( FALSE ); }

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

string trim( char* original, string chars_para_remover ){

    size_t tam_original = strlen(original);
    string modificada = "";
    for (size_t i = 0; i < tam_original; ++i) {
        if ( chars_para_remover.find(original[i]) == string::npos ) {
            modificada += original[i];
        }
    }

    return modificada;
}

vector<string> tokeniza( string texto ){
    vector<string> vetor;
    istringstream str_stream(texto);
    string token;

    while (str_stream >> token) {
        vetor.push_back(token);
    }

    return vetor;
}