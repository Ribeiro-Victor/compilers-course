%{
#include <string>
#include <iostream>
string lexema;
// enum TOKEN { _ID = 256, _FOR, _IF, _INT, _FLOAT, _MAIG, _MEIG, _IG, _DIF, _STRING, _STRING2, _COMENTARIO, _EXPR};
%}
/* Coloque aqui definições regulares */
DIGITO			[0-9]
LETRA           [A-Za-z]
WS	            [ \t\n\r]
INT             {DIGITO}+
UNDERLINE       "_"
ID              ("$"|{LETRA}|{UNDERLINE})({LETRA}|{DIGITO}|{UNDERLINE})*
ID_INVALID		(({ID})*"$"({ID})*)
FOR				[Ff][Oo][Rr]
IF              [Ii][Ff]
POT				[Ee](\+|\-)?
FLOAT			{DIGITO}+({POT}|\.){DIGITO}+({POT}{DIGITO}+)?
COMENTARIO		("//".*|"/*"([^*]|"*"+[^*"/"])*"*"+"/")

SNG_QUOTE		['](([^']|\\')*('')?([^']|\\')*)[']
DBL_QUOTE		["](([^"]|\\\")*(\"\")?([^"]|\\\")*)["]
STRING			({SNG_QUOTE}|{DBL_QUOTE})

STR_NO_EXPR		`([^`\$]|("$"[^\{]))*`
EXPR			"{"({ID})
STR_EXP_STRT	`[^`\$]*\$
STR_EXP_END		"}"(.)*`
STRING2			({STR_EXP_STRT}|{STR_EXP_END}|{STR_NO_EXPR})

%%
    /* Padrões e ações. Nesta seção, comentários devem ter um tab antes */

{WS}			{ /* ignora espaços, tabs e '\n' */ }
"if"			{lexema = yytext; return _IF;}
{FOR}			{lexema = yytext; return _FOR;}
"<="			{lexema = yytext; return _MEIG;}
">="			{lexema = yytext; return _MAIG;}
"=="			{lexema = yytext; return _IG;}
"!="			{lexema = yytext; return _DIF;}


{ID}    		{lexema = yytext; return _ID;}
{ID_INVALID}	{cout << "Erro: Identificador invalido: " << yytext << endl;}
{INT}   		{lexema = yytext; return _INT;}
{FLOAT}			{lexema = yytext; return _FLOAT;}
{COMENTARIO}	{lexema = yytext; return _COMENTARIO;}

{STRING}		{string buffer = yytext;
				string starting_qt = buffer.substr(0, 1);
				buffer = buffer.substr(1, buffer.length()-2); //Remove aspas do começo e final

				// Troca as aspas com barra por aspas sem barra
				string qt_to_find = "\\"+ starting_qt;
				while(buffer.find(qt_to_find) != string::npos)
					buffer.replace(buffer.find(qt_to_find), 2, starting_qt);

				// Troca duas aspas por uma só
				qt_to_find = starting_qt + starting_qt;
				while(buffer.find(qt_to_find) != string::npos)
					buffer.replace(buffer.find(qt_to_find), 2, starting_qt);

				lexema = buffer;
				return _STRING;}

{EXPR}			{string buffer = yytext;
				if(buffer.find("{") != string::npos)
					buffer.replace(buffer.find("{"), 1, "");
				lexema = buffer;
				return _EXPR;}

{STRING2}		{string buffer = yytext;
				if(buffer.at(0) == '`' || buffer.at(0) == '}')
					buffer = buffer.substr(1, buffer.length()); //Remove aspas invertidas ou brackets do começo
				if(buffer.at(buffer.length()-1) == '`' || buffer.at(buffer.length()-1) == '$')
					buffer = buffer.substr(0, buffer.length()-1); //Remove aspas invertidas ou cifrão do final
				lexema = buffer;
				return _STRING2;
				}

.       {lexema = yytext; return *yytext; 
          /* Essa deve ser a última regra. Dessa forma qualquer caractere isolado será retornado pelo seu código ascii. */ }

%%

/* Não coloque nada aqui - a função main é automaticamente incluída na hora de avaliar e dar a nota. */