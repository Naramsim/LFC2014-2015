/*
	Author Lorenzo Massimo Gramola AA 2014/1015
	http://lists.gnu.org/archive/html/help-bison/2009-03/msg00015.html
*/
%{
	#include <stdio.h>
	#include <stdlib.h> //exit
	#include <math.h>
	#include <string.h> //strncmp
	#include "header.h"
	int yylex(void);
	type *composeType(array*);
	array * composeArray(char const * , int , array *, basic *);
	void yyerror(char const *);
	char * name_temp;
	basic * b_temp = NULL;
	int inside_record = 0;
	symrec * tempTable = NULL;
%}

%union {
	double dbl;
	symrec *srec;
	type *tp;
	basic *bt;
	array *at;
	ref * rf;
	LRhand * H;
	record * rec;
};
%start P

%token INT FLOAT
%token <dbl>  NUM 
%token <srec> VAR
%nonassoc PRINT
%nonassoc SEMICOLON LBRACK RBRACK LCURLY RCURLY RECORD DOT


%type <dbl> expr
%type <rf>Cvar
%type <bt> B
%type <at> C
%type <tp> T
%type <H> L R


%error-verbose

%%

P: opt_dec_list LCURLY opt_cmd_list RCURLY;

opt_dec_list: 	/*empty*/
				| D 						{readTable(sym_table);}
				;

opt_cmd_list:	/*empty*/
				| cmd_list
				;
cmd_list:		cmd SEMICOLON
				| cmd SEMICOLON cmd_list
				;
cmd:		 		/*empty*/
					| L '=' R  {
											int n = $3->value.num;
											int res = assignment($1,$3);
											if(res == 0){
												printf("ASsignment exception.\nPlease check the code at line %d column %d\n", @2.first_line,@2.first_column);			
												exit(0);
											}
										}
					| PRINT expr
										{ printf("%f\n", $2);
									//    printf("%d\n", (yyvsp[(2) - (3)].dbl));

										}
	 				;

expr: 			R 					{
										$$ = Revaluate($1);	
									}
				;
L: 				VAR Cvar			{	

										if($2 != NULL){
											$1->ref = (ref*)malloc(sizeof(ref));
										}
										$1->ref = $2;
										//controllo istantaneo - se Cvar è un tipo di array controlliamo che
										// gli indici non eccedano quelli dichiarati per quella variabile
										// sempre che quella variabile sia un array
										int res = checkTypes($1);
										if(res == 0){
											printf("Lvalue evaluation exception.\nPlease check the code at line %d column %d\n", @2.first_line,@2.first_column);			
											exit(0);
										}
										LRhand *L = (LRhand*)malloc(sizeof(LRhand));
										L->name = "VAR";
										L->value.rec = $1;
										$$ = L;
									}
				| VAR DOT VAR 		{	
										int res = validateStructAccess($1->name, $3->name);
										if(res == 0){
											printf("Undefined Sruct access exception.\nPlease check the code at line %d column %d\n", @2.first_line,@2.first_column);			
											exit(0);
										}
										LRhand *l = (LRhand*)malloc(sizeof(LRhand));
										l->name = "STRUCT";
										l->value.rec = $1;
										l->member.name = $3;
										$$ = l;
									}									
				
				;
R :				VAR Cvar 			{	
										if($2 == NULL){

											$1->ref = NULL;
										}
										else{
											$1->ref = (ref*)malloc(sizeof(ref));
											$1->ref = $2;
										}
										int res = checkTypes($1);
										if(res == 0){
											printf("Rvalue evaluation exception.\nPlease check the code at line %d column %d\n", @2.first_line,@2.first_column);										
											exit(0);
										}
										LRhand *R = (LRhand*)malloc(sizeof(LRhand));
										R->name = "VAR";
										R->value.rec = $1;
										$$ = R;	
	
										
									}
				| NUM				{ 	
										$<dbl>$ = $1; // default we can skip it
										LRhand *R = (LRhand*)malloc(sizeof(LRhand));
										R->name = "NUM";
										R->value.num = $1;
										int n = R->value.num;
										$$ = R;
										}
				| VAR DOT VAR 		{	
										int res = validateStructAccess($1->name, $3->name);
										if(res == 0){
											printf("Undefined Sruct access exception.\nPlease check the code at line %d column %d\n", @2.first_line,@2.first_column);			
											exit(0);
										}
										LRhand *r = (LRhand*)malloc(sizeof(LRhand));
										r->name = "STRUCT";
										r->value.rec = $1;
										r->member.name = $3;
										$$ = r;
									}
				;

Cvar: 	/*empty*/					{ 	
										$$ = NULL;
									}
		| LBRACK NUM RBRACK Cvar 	{ 	
										ref *res = (ref*)malloc(sizeof(ref));
										//perform some check on i - our input have just test purposes
										int i = $2;
										res->n = i;
										res->next = $4;
										$$ = res;
									}
		;
D: 	 T VAR SEMICOLON D 				{	
										if(inside_record){
											//se arrivo qui ho gia inizializzato tempTable
											createSymStruct($2->name,$1,&tempTable);
										}else{
										
											$2 = createSym($2->name,$1);
										}
									}
	| T VAR SEMICOLON				{	
										if(inside_record){
												if(tempTable == NULL){
													printf(""); //questo printf fa andare tutto il programma
												tempTable = newRecordTable();
											}
											$2 = createSymStruct($2->name,$1,&tempTable);
										}else{
											$2 = createSym($2->name,$1);
										}

									}
	
	;


T:	B								{
										name_temp = malloc(sizeof($1->name)+1);
										strcpy(name_temp,$1->name); // t = B.type
										b_temp = $1;
									}


	C 								{
										$$ = composeType($3);
									}
	| RECORD 						{
										inside_record = 1;
									}
			LCURLY D RCURLY			{ 
										type * t = (type*)malloc(sizeof(type));
										t->name = "STRUCT";
										record * r = (record*)malloc(sizeof(record));
										r->tabella = tempTable;
										t->value.r = r;
										//readTable(r-> tabella);
										inside_record=0;
										tempTable = NULL;
										$$ = t;
									}
	;
B: 	 INT 							{;}
	| FLOAT							{;}
	;

C:	/*empty*/						{	;

										$$ = composeArray(b_temp->name,1,NULL,b_temp);
									}
	| LBRACK NUM RBRACK C 			{
										int n = $2;
										if(($2 - n)> 0){
											printf("Can not declare array with float range\nError occured at line %d column %d\n", @2.first_line,@2.first_column);
											exit(0);
										}
										if(n < 1){
											printf("Parser refuses to parse arrays with less than 1 items or with negative valuesnError occured at line %d column %d\n", @2.first_line,@2.first_column);
											exit(0);
										}
										$$ = composeArray("ARRAY", n, $4 , NULL);
									}
	;

%%


symrec *sym_table;

array * newArray(array * a){
	array * res = (array*)malloc(sizeof(array));
	res->name = malloc(sizeof(a->name)+1);
	strcpy(res->name,a->name);
	res->width = a->width;
	res->value.a = malloc(sizeof(array));
	res->value.a = a->value.a;
	res->value.b = malloc(sizeof(basic));
	if(a->value.b != NULL){
		basic * b = a->value.b;
		res->value.b->name = malloc(sizeof(a->value.b->name)+1);
		strcpy(res->value.b->name, a->value.b->name);
	}else{
		//does it ever jump in here?
		res->value.b = a->value.b;
	}
	if(a->value.a != NULL && a->width >1){
		res->value.a = (array*)malloc(sizeof(array)*a->width);
		for (int i = 0; i< a->width; i++){
			*(res->value.a +i) = *(newArray(a->value.a));
		}
	}
	return res;
}

/*
	prende un tipo, lunghezza dell'array, un riferimento ad un array e a un tipo base
	se creiamo un tipo di base array = NULL
	se creiamo un array il tipo di base è NULL
*/
array * composeArray(char const * tipo, int larghezza, array *a, basic *b){
	array * res = (array*)malloc(sizeof(array));
	res->width = larghezza;
	res->name = malloc(strlen(tipo)+1);
	strcpy(res->name, tipo);
	if(strcmp("ARRAY",res->name) == 0){
		// sto processando un array
		res->value.a = malloc(res->width*sizeof(array));
		for(int i = 0; i < larghezza; i++){			
			*((res->value.a)+i) = *newArray(a);
		}
	}
	else{
		//tipo di base
		res->name = "ARRAY";
		res->value.b = (basic*)malloc(sizeof(basic));
		res->value.b = b;
	}
	return res;
};

type * composeType(array * a){
	type * res = (type*)malloc(sizeof(type));
	if(a->width == 1){
		//in realtà è un tipo di base
		//è dovuto alla costruzione per C -> epsilon dove mettiamo lunghezza = 1
		//quindi il type (il tipo) è di base - valorizziamo b
		res->value.b = (basic*)malloc(sizeof(basic));
		res->value.b = a->value.b;
		res->name = malloc(sizeof(a->value.b->name)+1);
		//printf("%s\n",a->value.b->name);
		strcpy(res->name, a->value.b->name);
	}else{
		//è proprio un array
		//quindi settiamo direttamente il valore di a per il type
		res->value.a = malloc(sizeof(array));
		res->value.a = a;
		res->name = malloc(sizeof(a->name));
		strcpy(res->name, a->name);
	}
	
	return res;
}

void checkVariableStructure(symrec * var){
	printf("%s\n", "variable checking procedure");
	printf("\t%s%s\n", "variable name is ", var->name);
	char * tipo = var->tipo->name;
	printf("\t%s%s\n","varibale declared type is ", tipo);
	if(strcmp("ARRAY", tipo)!=0){
		return;
	}
	else{
		checkTypeStructure(var->tipo);
	}

}
void checkTypeStructure(type * type){
	printf("\t%s\n", "type checking procedure");
	printf("\t\t%s%s\n", "type declared name is ", type->name);
	if(strcmp("ARRAY", type->name)!=0){
		//è un tipo di base
		printf("\t\t%s%s\n", "referenced type is ", type->value.b->name);
	}
	else{
		//è un array
		 checkArrayStructure(type->value.a);
	}
}
void checkArrayStructure(array * a){
	printf("\t\t%s\n", "array checking procedure");
	printf("\t\t\t%s%s\n", "array declared type is ", a->name);
	printf("\t\t\t%s%d\n", "array declared width is ", a->width);
	//durante la costruzione dell'array il passo base è creare un array di lunghezza uno
	//che contiene una variabile di tipo base il cui name è quello del tipo di base
	//quindi l'array "termina" quando troviamo un tipo di base di lunghezza 1
	int res = strcmp("ARRAY", a->value.b->name);
	if(res!=0){
		//è un tipo di base
		printf("\t\t\t%s%s\n", "referenced type is ", a->value.b->name);
	}
	else{
		//è un array
		 checkArrayStructure(a->value.a);
	}
}


int
main (void)
{
  yylloc.first_line = yylloc.last_line = 1;
  yylloc.first_column = yylloc.last_column = 0;
  return yyparse ();
}