#include <stdio.h> /* for stderr */
#include <stdlib.h> /* malloc. */
#include <string.h> /* strlen. */
#include "header.h" //Asdf

symrec *
putsym (char const * identifier, type * tipo)
{
  symrec *ptr = (symrec *) malloc (sizeof (symrec));
  ptr->name = (char *) malloc (strlen (identifier) + 1);
  strcpy (ptr->name,identifier);
  ptr->tipo = (type*)malloc(sizeof(type));
  ptr->tipo = tipo;
  ptr->next = (struct symrec *)sym_table;
  sym_table = ptr;
  return ptr;
}
symrec 
*putsymStruct(char const * identifier, type * tipo, symrec ** tabella){
  symrec *ptr = (symrec *) malloc (sizeof (symrec));
  ptr->name = (char *) malloc (strlen (identifier) + 1);
  strcpy (ptr->name,identifier);
  ptr->tipo = tipo;
    ptr->next = *tabella;
    *tabella = ptr;
  return ptr;
}


symrec *
getsym (char const * identifier)
{
  symrec *ptr;
  for (ptr = sym_table; ptr != (symrec *) 0;
       ptr = (symrec *)ptr->next){
		if (strcmp (ptr->name, identifier) == 0)
      	return ptr;
  }
  return NULL;
}
symrec 
*getsymStruct(char const *identifier, symrec * tabella){
  symrec *ptr;
  for (ptr = tabella; ptr != (symrec *) 0;
       ptr = ptr->next){
    if (strcmp (ptr->name, identifier) == 0)
        return ptr;
  }
  return NULL;
}


void
updatesym(symrec * var){
symrec *ptr;
int updated = 0;
  for (ptr = sym_table; ptr != (symrec *) 0;
       ptr = (symrec *)ptr->next){
    if (strcmp (ptr->name, var->name) == 0){
        ptr = var;
        updated = 1;
        break;
    }
  }
  if(!updated){
    printf("%s\n", "no such variable in the environment");
    exit(0);
  }
}
int checkArrayAcces(array * a, ref * r){
    //controllo di non essere arrivato alla fine dell'array
    int res = strcmp("ARRAY", a->value.b->name);
    if(res==0){
      //sono dentro la struttura dell'array
        if(r == NULL){
          printf("%s\n", "please access a specific element of the array");
          return 0;
        }
        int actualLength = a->width;
        int accessedItem = r->n;
        if (accessedItem > actualLength-1){
            printf("%s %d %s %d\n", "Index out of bound exception. Accessed item is", accessedItem, ", array length is",actualLength);
          return 0;
        }else{
            return checkArrayAcces((a->value.a+accessedItem), r->next);
        }
    }
    else{
      // è un tipo di base
      //controllo che non vengano fatte ulteriori accessi
      if(r!=NULL){
            printf("%s\n", "Index out of bound exception. Accessing to many items");
          return 0;
      }
      else{
          return a->width;
      }
    }
}
int* arrayElement(array * a, ref * r){
    //il controllo è gia avvenuto a monte, vado diretto a prendere il puntatore
    int res = strcmp("ARRAY", a->value.b->name);
    if(res==0){
        int accessedItem = r->n;
        //controllo che il prossimo elemento non sia la fine dell'array
        return arrayElement((a->value.a + accessedItem),r->next);
        
    }
    else{
        //devo restituire la locazione
        return &(a->value.b->value.i);

    }
}
int checkTypes(symrec * variable){
  int existInEnvironment = (getsym(variable->name) == NULL) ? 0 : 1;
  if(existInEnvironment == 0){
    return 0;
  }

  char * tipo = variable->tipo->name;
  int res = strcmp("ARRAY", tipo); // if res!=0 è una variabile normale
  //controllo il tipo di variablie
  if(res == 0 && variable->ref== NULL){
      printf("%s %s\n %s %s\n %s\n", "accessing variablie",variable->name, "which is of type", variable->tipo->name, "we do not implement pointer arithmetic. Review your code please");
          return 0;
  }
  if(res!=0 && variable->ref!= NULL){
      printf("%s %s\n %s %s\n %s\n", "accessing variablie",variable->name, "which is of type", variable->tipo->name, "This is not an array and we do not implement pointer arithmetic. Review your code please");
          return 0;
  }

  if(res!=0 && variable->ref== NULL){
      // è una variabile di base eg int ciao
      return 1;
  }
  //altrimenti è un array, devo controllare gli indici ai quali accedo
  //ad ogni modo metto una guardia nell'if per controllare
  if(res==0 && variable->ref!= NULL){
     int res = checkArrayAcces(variable->tipo->value.a,variable->ref);
     return res;
  }
  //se ogni altro controllo non va bene, c'è qualcosa che non va
  return 0;
}

int Revaluate(LRhand * expr){
    if(strcmp(expr->name, "VAR") == 0){
        symrec * var = (symrec*)malloc(sizeof(symrec));
        var = expr->value.rec;
        if(var->ref == NULL){
            return var->tipo->value.b->value.i;
        }
        else{
            //sfrutto arrayElement - mi faccio dare l'address
            int * addr = arrayElement(var->tipo->value.a, var->ref);
            return *addr;
        }
    }
    if(strcmp(expr->name, "NUM") == 0){
        int n = expr->value.num;
        return n;
    }
    if(strcmp(expr->name, "STRUCT")== 0){
        //once here all the control are already done
        //we have to take pointer location and return its value
        //in the LRHand struct we save the struct as rec and the accessed value
        //as name, notice that we can not nest in this case structs calling structs
        //our structures are far from being simple, with a more simple architecture
        //we could play around with this a bit
        
        symrec s = *getsymStruct(expr->member.name->name,
                                expr->value.rec->tipo->value.r->tabella);
        //suppose we do not declare array, even if possible
        //so that we have only basic types eg int
        return s.tipo->value.b->value.i;
        
    }
    printf("%s %s\n", "Right hand operator\nnot able to evaluate expression", expr->name);
    exit(0);
}

int * Levaluate(LRhand * expr){
    if(strcmp(expr->name, "VAR") == 0){
        //i controlli sull'accesso all'array o alla variabile sono gia stati fatti
        symrec * var = (symrec*)malloc(sizeof(symrec));
        var = expr->value.rec;
        if(var->ref == NULL){
            return &(var->tipo->value.b->value.i);
        }
        else{
            return arrayElement(var->tipo->value.a, var->ref);
        }
    }
    if(strcmp(expr->name, "NUM") == 0){
        printf("%s\n", "not able to assign value to a constant");
        return 0;
    }
    if(strcmp(expr->name, "STRUCT")== 0){
        
        symrec s = *getsymStruct(expr->member.name->name,
                                 expr->value.rec->tipo->value.r->tabella);
        return &(s.tipo->value.b->value.i);
        
    }

    printf("%s %s\n", "Left hand operator\nnot able to evaluate expression", expr->name);
    exit(0);
}
int assignment(LRhand * L, LRhand * R){
    //evaluate R and then assign it to L
    //switch over string not supported
    //we should use a kind of enum or.. chain some IF-ELSE stmt
    double Rvalue = Revaluate(R);
    int *Lvalue = Levaluate(L);
    int v = Rvalue;
    *Lvalue = v;
    return 1;
}

symrec *createSym(char const * varName, type * type){

    symrec * s;
    char * variableName = malloc(strlen(varName)+1);
    strcpy(variableName,varName);
    s = getsym(variableName);
    if (s == 0){
        s = putsym(variableName, NULL);
    }
    s->tipo = type;
    return s;
}

symrec * newRecordTable(){
    symrec * res;
    //shall we place some already declared variable here
    //some reserved keyword or preceding declared var?
    return res;
}
symrec *createSymStruct(char const * varName, type * type, symrec ** tabella){
    
    
    symrec * s;
    //printf("creating new varibale for struct\n");
    char * variableName = malloc(strlen(varName)+1);
    strcpy(variableName,varName);
    s = getsymStruct(variableName, *tabella);
    if (s == 0){
        //printf("putting symbol into table\n");
        s = putsymStruct(variableName, NULL, &(*tabella));
    }
    s->tipo = type;
    
    return s;
}

void readTable(symrec * tabella){
    printf("PRINTING TABLE\n");
    if(tabella == NULL){
        printf("table is empty\n");
    }
    symrec *ptr;

    printf("\n");
    for (ptr = tabella; ptr != (symrec *) 0;
         ptr = (symrec *)ptr->next){
        printf("|\t%*s\t|\n",20,ptr->name);
    }

    printf("\n");


}



int validateStructAccess(char const * structName, char const * propertyName){
    symrec *s;
    s = getsym(structName);
    if(s == NULL){
        printf("there is no struct in the environment with name %s\n", structName);
        return 0;
    }
    int res = strcmp("STRUCT", s->tipo->name);
    if(res!=0){
        printf("%s is not a struct\n", structName);
        return 0;
    }
    // so far we checked that we have a struct, is time to check for its property
    symrec * m;
    m = getsymStruct(propertyName, s->tipo->value.r->tabella);
    if(m == NULL){
        printf("There is no %s in %s, are you sure about %s.%s ? \n", propertyName, structName, structName, propertyName);
        return 0;
    }
    //all checks so far are done
    return 1;
}













