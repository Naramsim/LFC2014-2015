alpha [A-Za-z]
digit [0-9]

%%

[\t \n]             ;
int|float|void|char|ciao         return TYPE;
return                 return RETURN;
{digit}+             return NUM;
{alpha}({alpha}|{digit})*     return ID;
.                 return yytext[0];

%%
