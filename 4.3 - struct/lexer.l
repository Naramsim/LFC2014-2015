%{
	#include<stdio.h>
	#include<stdlib.h>
    #include "header.h"
    #include "y.tab.h"

    void yyerror(char const *);
%}

%%

-?[0-9]+				{  	yylloc.first_line = yylloc.last_line;
		  					yylloc.first_column = yylloc.last_column;
						    yylval.dbl = atof(yytext);
						    yylloc.last_column+=yyleng;
					    	return NUM;
						}
int						{
									basic *b = malloc(sizeof(basic));
									b->name = "INTEGER";
									*((basic**)(&yylval)) = b;
									return INT;	
						}					
float					{
									basic *b = malloc(sizeof(basic));
									b->name = "FLOAT";
									*((basic**)&yylval) = b;
									return FLOAT;
						}
record					{
									return RECORD;
						}
print 					{			return PRINT;}
[a-zA-Z][a-zA-Z0-9]*	{
							yylloc.last_column+=yyleng;
							/*
								manage variables
								if the varibale is not declared,
								put it in the symbol table
							*/
							symrec * s;
							char * variableName = malloc(strlen(yytext));
							strcpy(variableName,yytext);
							s = getsym(variableName);
							if (s == 0){
								s =(symrec *) malloc (sizeof (symrec));
								s->name = (char *) malloc(strlen(yytext));
								strcpy (s->name,yytext);
							}
							*((symrec**)&yylval) = s; //just saying that yylval is a symrec and a pointer to s
							return VAR;
						}

[ \t]					{    yylloc.last_column++;}

[-+/*^=()]				{	
							yylloc.last_column++;
							return *yytext;
						}
\n 						{	
							yylloc.last_line++;
							yylloc.last_column = 0;
						}
;						{return SEMICOLON;}
\{						{return LCURLY;}

\}						{return RCURLY;}
\[						{return LBRACK;}
\]						{return RBRACK;}
\.						{return DOT;}
.						{
							yylloc.last_column++;
							ECHO;
							printf("\n");
							yyerror("the previous char unknow to the lexer\n");
						}
%%

int yywrap(void){
	return 1;
}

void yyerror (char const *s) {
   fprintf (stderr, "%s\n", s);
}