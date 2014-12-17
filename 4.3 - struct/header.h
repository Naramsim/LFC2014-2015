/**
	this file will contain generally useful function such as
	those that manage the environment
	EG put and get symbol from the symbol table
	as well as structures and so on..
*/
/* FUNCTION TYPE*/
typedef double (*funct_t)(double);


/*DATA TYPE FOR LINKS IN THE CHAIN OF SYMBOLS*/

typedef struct basicType{
	char * name; //either float, int or boolean or whatever basic type
	union{
		int i;
		float f;
	} value;
} basic;
typedef struct arrayType
{
	char * name;
	int width;
	union{
		basic *b;
		struct arrayType *a;
	} value;
} array;

typedef struct type{
	char * name; //is coming from the basic type or either the array or the struct etc etc
	union{
		basic *b;
		array *a;
		struct record *r;
	} value; 
}type;

typedef struct ref{
	int n; // the actual position
	struct ref * next; // next position
}ref;

typedef struct symrec
{
	char * name; //name of the symbol
	type * tipo;
	ref * ref; //ref to be cleaned after each assignment - holds current accessed position
	struct symrec *next;
} symrec;

typedef struct record{
	symrec * tabella;
}record;

typedef struct LRhand{
    char * name; //è il tipo di valore che stiamo andando a valutare - serve per lo "switch" sulle "funzioni di valutazione"
    union{
        symrec * rec; // il record che dobbiamo valutare/assegnare
        double num;
    }value;
    union{
        symrec * name;
        void * empty;
    }member;
}LRhand;



/*THE SYMBOL TABLE: A CHAIN OF 'STRUCT SYMREC'*/
extern symrec *sym_table;

//=========================================
//||        AUXILIARY FUNCTIONS          ||
//=========================================
void checkVariableStructure(symrec *);
void checkTypeStructure(type * );
void checkArrayStructure(array * );
void readTable(symrec *);


symrec * newRecordTable();
symrec *createSym(char const *, type *);
symrec *createSymStruct(char const *, type *, symrec **);
symrec *putsym(char const *, type *);
symrec *putsymStruct(char const *, type *, symrec **);
void updatesym(symrec*);
symrec *getsym(char const *);
symrec *getsymStruct(char const *, symrec *);
int checkArrayAccess(array *, ref *);
int* arrayElement(array *, ref *);
int checkTypes(symrec *);
int * Levaluate(LRhand *);
int Revaluate (LRhand *);
int assignment(LRhand *, LRhand *);
int validateStructAccess(char const *, char const *);


