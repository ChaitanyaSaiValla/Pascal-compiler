%{
int COMMENT=0;
%}
letter [a-zA-Z]
digit [0-9]
%%
int |
float |
char |
double |
while |
for |
struct |
typedef |
do |
if |
break |
continue |
void |
switch |
return |
else |
begin |
end  |
goto |
repeat |
until |
then {printf("Keyword ");}
"{" {COMMENT=1;}
{letter}({letter}|{digit})* {if(!COMMENT) printf("Identifier");}
{digit}+|({digit}+.{digit}+) {if(!COMMENT) printf("Number");}
%%

int yywrap()
{
    return 1 ;
}
