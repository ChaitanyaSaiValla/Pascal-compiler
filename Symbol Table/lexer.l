%{
#include "y.tab.h"
#include <string.h>
void yyerror();
%}
RELOP (<|>|<=|>=|==|!=)
%%
"++"  			{ return INC;}
"--"    		{ return DEC;}
"begin"         {return BEGN;}
"end"           { return ED;}
"do"            { return DO ;}
"while" 		{ return WHILE;}
"if"    		{ return IF;}
"else"  		{ return ELSE;}
"for"   		{ return FOR;}
"break" 		{ return BREAK;}
"repeat"        {return REPEAT;}
"until"         {return UNTIL;}
"then"          {return THEN;}
"continue"  		{ return CONTINUE;}
"int"   		{ return INT;}
"float" 		{ return FLOAT;}
"char"  		{ return CHAR;}
"long"      		{ return LONG;}
"double"      		{ return DOUBLE;}
"&&"  			{ return AND;}
"||"  			{ return OR;}
"!"  			{ return NOT;}
"("			{return LB;}
")"			{return RB;}
"{"			{return LF;}
"}"			{return RF;}
"["			{return LSB;}
"]"			{return RSB;}
":="        {return ASSIGN;}
{RELOP}    		{ strcpy(yylval.lexeme,yytext); return RELOP;}
[a-zA-Z][a-zA-Z0-9]*	{ strcpy(yylval.lexeme,yytext); return VAR; }
[0-9]+\.[0-9]+ 		{ yylval.vf = atof(yytext); return FL; }
[0-9]+      		{ yylval.vi = atoi(yytext); return IN; }


[ \t\n]	;	
"$"	return 0;	
.	return yytext[0];
%%

int yywrap()
{
    return 1 ;
}
