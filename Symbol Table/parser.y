%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
void yyerror();
int yylex(void);
int l_break = -1;
int l_continue = -1;
int l_count=0;
int label=0;
int memory=0;
int mode=0; //0-checking, 1-data, 2-code
struct Literal
{
    int type; // 0-integral 1-floating point
    long long int v_i;
    double v_f;
};
struct Literal ONE;
struct Literal ZERO;
struct K
{
    int is_address;
    int lval;
    struct Literal* rval;
    char varname[20];
};
struct TAC
{
    struct K tl;
    struct K tr1;
    struct K tr2;
    char op;
};
struct Node
{
    int data_type;
    struct Node* left;
    struct Node* right;
    struct TAC ig;
    char tok[20];
    char lexeme[20];
    struct Literal* value;
};
struct Statement
{
    int type; // 0-null 1-unary 2-statement 3-break 4-continue 5-declaration
    struct Node* exp;
    struct Declaration* d;
    char lval[20];
};
struct Declaration
{
    char name[20];
    char type_base; //0-char 1-short 2-int 3-float 4-long 5-double
    char type_modifier; //0-none, 1-array, 2-pointer
    int dim_prod;   // product of dimensions, for arrays
    int depth_pointer; // depth of pointer, for pointers
};
struct Block
{
    struct Program* p;
};
struct Condition
{
    char relop[10];
    struct Node* e1;
    struct Node* e2;
    int type; // 0 if e2 is not used;
};
struct C_exp
{
    int type;   // 1-not 2-and 3-or 0-leaf(condition)
    struct C_exp* cl; // not is stored in left
    struct C_exp* cr;
    struct Condition* c; // if leaf
};
struct Prog
{
    struct Prog* p1;
    struct Prog* p2;
    struct Block* bl;
    struct Statement* s1;
    struct Statement* s2;
    int type;
    /*
    0 - normal (uses b1)
    1 - if else (uses b1 b2 exp)
    2 - while (uses b1 exp)
    3 - do while (uses bl exp)
    4 - for (uses s1 exp s2 b1)
    */
    struct C_exp* exp;
};
struct Program
{
    struct Prog* p;
    struct Program* next;
};
struct D_Table_entry
{
    struct Declaration* d;
    struct D_Table_entry* next;
};
struct D_stack
{
    struct D_Table_entry* t;
    struct D_stack* p;
};
struct D_stack* tail;
struct D_Table
{
    struct D_Table_entry* head;
    struct D_Table_entry* tail;
};
struct D_Table dt_root;
void print_k(struct K*);
void print_TAC(struct TAC*);
void print_IG(struct Node*);
void print_Statement(struct Statement*);
void print_Program(struct Program*);
void print_Block(struct Block*);
void print_Condition(struct Condition*);
void print_Condition_body(struct Condition*);
void print_C_exp(struct C_exp*, int, int);
void print_D_Table(struct D_Table*);
void add(struct D_Table*, struct Declaration*);
int get_base_type_of(struct D_Table*, char*);
int get_modifier_type_of(struct D_Table*, char*);
int search(struct D_Table*, char*);
int new_label();
int max_type(int,int);// return type with higher precedence
%}

%union
{
    struct C_exp* ce;
    struct Condition* c;
	struct Node* n;
    struct Block* bl;
    struct Program* p;
    struct Prog* p_;
    struct Statement* s;
    struct Literal* l;
    int val;
    int vi;
    float vf;
    char lexeme[20];
}
%token INC DEC WHILE RELOP IF ELSE FOR BREAK CONTINUE INT SHORT LONG DOUBLE CHAR FLOAT AND OR NOT LB RB LF RF LSB RSB BEGN ED DO REPEAT UNTIL LOOP_COND THEN ASSIGN
%token <lexeme> VAR
%token <vi> IN
%token <vf> FL
%type <n> E
%type <n> T
%type <c> COND
%type <ce> C_EXP
%type <ce> C_EXP_t
%type <ce> C_EXP_u
%type <ce> C_EXP_v
%type <n> F
%type <n> J
%type <n> NUM
%type <n> LA
%type <n> G
%type <n> V
%type <p> PROGRAM
%type <p_> PROG
%type <lexeme> R
%type <s> STATEMENT
%type <s> STMT
%type <bl> BLOCK
%type <val> DTYPE
%type <val> ARR_DEC
%type <val> POINT_DEC
%type <l> LIT

%{
    
%}

%%
S : PROGRAM {
    mode=1;
    printf("SYMBOL TABLE\n");
    printf("\nOffset\tName\tType");
    print_Program($1);
    printf("\n");
    };
    
PROGRAM :   PROG PROGRAM {
    			$$ = (struct Program*)malloc(sizeof(struct Program));
    			$$->next = $2;
    			$$->p = $1;
			} | {$$ = NULL;};

PROG :   STATEMENT {
    $$ = (struct Prog*)malloc(sizeof(struct Prog));
    $$->s1 = $1;
    $$->type=-2;
} | BLOCK {
    $$ = (struct Prog*)malloc(sizeof(struct Prog));
    $$->bl = $1;
    $$->type=0;
}
| WHILE C_EXP DO  BLOCK {
    $$ = (struct Prog*)malloc(sizeof(struct Prog));
    $$->type=2;
    $$->p1 = $4;
    $$->exp=$2;
} | IF  C_EXP THEN BLOCK ELSE BLOCK{
    $$ = (struct Prog*)malloc(sizeof(struct Prog));
    $$->type=1;
    $$->p1 = $4;
    $$->p2 = $6;
    $$->exp = $2;
} | REPEAT BLOCK UNTIL C_EXP ';' {
    $$ = (struct Prog*)malloc(sizeof(struct Prog));
    $$->type=2;
    $$->p1 = $2;
    $$->exp=$4;
};


C_EXP   : C_EXP_t OR C_EXP {
    				$$ = (struct C_exp*)malloc(sizeof(struct C_exp));
    				$$->cl = $1;
    				$$->cr = $3;
    				$$->type = 3;
			   } | C_EXP_t {$$=$1;} ;

C_EXP_t : C_EXP_u AND C_EXP_t {
    				$$ = (struct C_exp*)malloc(sizeof(struct C_exp));
   				$$->cl = $1;
    				$$->cr = $3;
    				$$->type = 2;
			}
	| C_EXP_u {$$=$1;} ;

C_EXP_u : NOT C_EXP_v {
    			$$ = (struct C_exp*)malloc(sizeof(struct C_exp));
    			$$->cl = $2;
    			$$->type = 1;
			} | C_EXP_v {$$=$1;} ;
			
C_EXP_v : LB C_EXP RB {$$=$2;} | COND {
    					$$ = (struct C_exp*)malloc(sizeof(struct C_exp));
    					$$->c = $1;
    					$$->type = 0;
					} ;
COND     :  E {
    		$$ = (struct Condition*)malloc(sizeof(struct Condition));
    		$$->type = 0;
    		$$->e1 = $1;
    		l_count=0;
		} 
	| E R E {	
    		$$ = (struct Condition*)malloc(sizeof(struct Condition));
    		$$->type = 1;
    		$$->e1 = $1;
    		$$->e2 = $3;
    		strcpy($$->relop,$2);
    		l_count=0;
		}
	;
	
R       :   RELOP {strcpy($$,yylval.lexeme);};

BLOCK :  BEGN   PROGRAM  ED  { $$ = (struct Block*)malloc(sizeof(struct Block)); $$->p = $2;} ;

STATEMENT : STMT ';' {$$=$1;}  ;

STMT  : LA ASSIGN E {
    if(search(&dt_root,$1->lexeme)==0)printf("\nerror detected - %s used without declaration",$1->lexeme);
    int ltype = get_base_type_of(&dt_root,$1->lexeme);
    if(ltype!=max_type(ltype,$3->data_type))printf("\nerror detected - type mismatch for %s",$1->lexeme);
    $$ = (struct Statement*)malloc(sizeof(struct Statement));
    $$->exp = $3;
    strcpy($$->lval,$1->lexeme);
    $$->type = 2;
    l_count=0;
    } | G {
        $$ = (struct Statement*)malloc(sizeof(struct Statement));
        $$->exp = $1;
        $$->type = 1;
        l_count=0;
    } | BREAK {
        $$ = (struct Statement*)malloc(sizeof(struct Statement));
        $$->type = 3;
    } | CONTINUE {
        $$ = (struct Statement*)malloc(sizeof(struct Statement));
        $$->type = 4;
    } | DTYPE LA {
        if(search(&dt_root,$2->lexeme)==1)printf("\nerror detected - %s re-declaration",$2->lexeme);
        $$ = (struct Statement*)malloc(sizeof(struct Statement));
        $$->type = 5;
        $$->d = (struct Declaration*)malloc(sizeof(struct Declaration));
        $$->d->type_base=$1;
        $$->d->type_modifier=0;
        add(&dt_root,$$->d);
        strcpy($$->d->name,$2->lexeme);
    } | DTYPE LA ASSIGN E {
        if(search(&dt_root,$2->lexeme)==1)printf("\nerror detected - %s re-declaration",$2->lexeme);
        $$ = (struct Statement*)malloc(sizeof(struct Statement));
        $$->type = 2;
        $$->exp = $4;
        strcpy($$->lval,$2->lexeme);
        $$->d = (struct Declaration*)malloc(sizeof(struct Declaration));
        $$->d->type_base=$1;
        $$->d->type_modifier=0;
        add(&dt_root,$$->d);
        strcpy($$->d->name,$2->lexeme);
        l_count=0;
        int ltype = get_base_type_of(&dt_root,$2->lexeme);
        if(ltype!=max_type(ltype,$4->data_type))printf("\nerror detected - type mismatch for %s",$2->lexeme);
    } | DTYPE LA ARR_DEC {
        if(search(&dt_root,$2->lexeme)==1)printf("\nerror detected - %s re-declaration",$2->lexeme);
        $$ = (struct Statement*)malloc(sizeof(struct Statement));
        $$->type = 5;
        $$->d = (struct Declaration*)malloc(sizeof(struct Declaration));
        $$->d->type_base=$1;
        $$->d->type_modifier=1;
        $$->d->dim_prod=$3;
        add(&dt_root,$$->d);
        strcpy($$->d->name,$2->lexeme);
    } | DTYPE POINT_DEC LA {
        if(search(&dt_root,$3->lexeme)==1)printf("\nerror detected - %s re-declaration",$3->lexeme);
        $$ = (struct Statement*)malloc(sizeof(struct Statement));
        $$->type = 5;
        $$->d = (struct Declaration*)malloc(sizeof(struct Declaration));
        $$->d->type_base=$1;
        $$->d->type_modifier=2;
        $$->d->depth_pointer=$2;
        add(&dt_root,$$->d);
        strcpy($$->d->name,$3->lexeme);
    } | {
        $$ = (struct Statement*)malloc(sizeof(struct Statement));
        $$->type = 0;} ;

LA      :   VAR {
    			$$ = (struct Node*)malloc(sizeof(struct Node));
    			strcpy($$->tok,"variable");
    			strcpy($$->lexeme,yylval.lexeme);
		};

E		:	E '+' T 	{
					$$ = (struct Node*)malloc(sizeof(struct Node));
					strcpy($$->tok,"operator");
					strcpy($$->lexeme,"plus");
					$$->left = $1;
					$$->right = $3;
					$$->ig.tl.is_address=1;
					$$->ig.tl.lval=l_count;
					l_count++;
					$$->ig.op='+';
					$$->ig.tr1 = $1->ig.tl;
					$$->ig.tr2 = $3->ig.tl;
					$$->data_type = max_type($1->data_type,$3->data_type);
					}
   		| 	E '-' T	        {
					$$ = (struct Node*)malloc(sizeof(struct Node));
					strcpy($$->tok,"operator");
					strcpy($$->lexeme,"minus");
					$$->left = $1;
					$$->right = $3;
					$$->ig.tl.is_address=1;
					$$->ig.tl.lval=l_count;
					l_count++;
					$$->ig.op='-';
					$$->ig.tr1 = $1->ig.tl;
					$$->ig.tr2 = $3->ig.tl;
					$$->data_type = max_type($1->data_type,$3->data_type);
				       }
		|	T	{$$=$1;}
		;

T		:	T '*' F 	{
					$$ = (struct Node*)malloc(sizeof(struct Node));
					strcpy($$->tok,"operator");
					strcpy($$->lexeme,"multiplication");
					$$->left = $1;
					$$->right = $3;
					$$->ig.tl.is_address=1;
					$$->ig.tl.lval=l_count;
					l_count++;
					$$->ig.op='*';
					$$->ig.tr1 = $1->ig.tl;
					$$->ig.tr2 = $3->ig.tl;
					$$->data_type = max_type($1->data_type,$3->data_type);
					}
   		| 	T '/' F		{
					$$ = (struct Node*)malloc(sizeof(struct Node));
					strcpy($$->tok,"operator");
					strcpy($$->lexeme,"division");
					$$->left = $1;
					$$->right = $3;
					$$->ig.tl.is_address=1;
					$$->ig.tl.lval=l_count;
					l_count++;
					$$->ig.op='/';
					$$->ig.tr1 = $1->ig.tl;
					$$->ig.tr2 = $3->ig.tl;
					$$->data_type = max_type($1->data_type,$3->data_type);
   					 }
		|	F			{$$ = $1;}
		;

F   	: 	J {$$ = $1;} 
	| 	LB DTYPE RB J {
				    $$=$4;
				    $$->data_type = $2;
				    if(strcmp($$->tok,"literal")==0)
				    {
				        int dt = $$->data_type;
				        int x = $$->ig.tl.rval->type;
				        if(dt==3 || dt==5)
					        {
					            if(x==0)
					            {
					                $$->ig.tl.rval->type = 1;
					                $$->ig.tl.rval->v_f = (double)$$->ig.tl.rval->v_i;
					            }
					        }
				        else
					        {
					            if(x==1)
					            {
					                $$->ig.tl.rval->type = 0;
					                $$->ig.tl.rval->v_i = (long long int)$$->ig.tl.rval->v_f;
					            }
					        }
					    }
				} ;

J		:	NUM {$$ = $1;} | '(' E ')' { $$ = $2;} ;

NUM     :   LIT {
                    $$ = (struct Node*)malloc(sizeof(struct Node));
                    strcpy($$->tok,"literal");
                    $$->value = $1;
                    $$->ig.tl.is_address=0;
                    $$->ig.tl.rval=$1;
                    $$->data_type = $1->type==0?0:3;
                    // default 0 for char
                    // default 3 for float
                 } | G {$$ = $1;};
                 
V       :   VAR {
                if(search(&dt_root,yylval.lexeme)==0)printf("\nerror detected - %s used without declaration",yylval.lexeme);
                $$ = (struct Node*)malloc(sizeof(struct Node));
                strcpy($$->tok,"variable");
                strcpy($$->lexeme,yylval.lexeme);
                $$->ig.tl.is_address = 1;
                $$->ig.tl.lval = -1;
                strcpy($$->ig.tl.varname,yylval.lexeme);
                $$->data_type = get_base_type_of(&dt_root,yylval.lexeme);
		}  ;

LIT     :   IN {
   		 $$ = (struct Literal*)malloc(sizeof(struct Literal));
   		 $$->type = 0;
   		 $$->v_i = yylval.vi;
		  } 
	| 
	   FL {
    		$$ = (struct Literal*)malloc(sizeof(struct Literal));
    		$$->type = 1;
    		$$->v_f = yylval.vf;
	      } ;

G       :   V { $$ = $1;
} | INC V {
    $$ = (struct Node*)malloc(sizeof(struct Node));
    $$->left = $2;
    strcpy($$->tok,"operator");
    strcpy($$->lexeme,"prefix increment");
    $$->ig.tl.is_address=1;
    $$->ig.tl.lval = l_count;
    l_count++;
    $$->ig.op = '+';
    $$->ig.tr1 = $2->ig.tl;
    $$->ig.tr2.is_address = 0;
    $$->ig.tr2.rval = &ONE;
    $$->data_type = $2->data_type;
} | DEC V {
    $$ = (struct Node*)malloc(sizeof(struct Node));
    $$->left = $2;
    strcpy($$->tok,"operator");
    strcpy($$->lexeme,"prefix decrement");
    $$->ig.tl.is_address=1;
    $$->ig.tl.lval = l_count;
    l_count++;
    $$->ig.op = '-';
    $$->ig.tr1 = $2->ig.tl;
    $$->ig.tr2.is_address = 0;
    $$->ig.tr2.rval = &ONE;
    $$->data_type = $2->data_type;
} | V INC {
    $$ = (struct Node*)malloc(sizeof(struct Node));
    $$->left = $1;
    strcpy($$->tok,"operator");
    strcpy($$->lexeme,"postfix increment");
    $$->ig.tl.is_address=1;
    $$->ig.tl.lval = l_count;
    l_count++;
    $$->ig.op = '+';
    $$->ig.tr1 = $1->ig.tl;
    $$->ig.tr2.is_address = 0;
    $$->ig.tr2.rval = &ZERO;
    $$->data_type = $1->data_type;
}  | V DEC {
    $$ = (struct Node*)malloc(sizeof(struct Node));
    $$->left = $1;
    strcpy($$->tok,"operator");
    strcpy($$->lexeme,"postfix decrement");
    $$->ig.tl.is_address=1;
    $$->ig.tl.lval = l_count;
    l_count++;
    $$->ig.op = '-';
    $$->ig.tr1 = $1->ig.tl;
    $$->ig.tr2.is_address = 0;
    $$->ig.tr2.rval = &ZERO;
    $$->data_type = $1->data_type;
};

DTYPE   	: INT {$$=2;} | FLOAT {$$=3;} | CHAR {$$=0;} | SHORT {$$=1;} | LONG {$$=4;} | DOUBLE {$$=5;};
ARR_DEC 	: LSB IN RSB ARR_DEC {$$=$2*$4;} | LSB IN RSB {$$=$2;};
POINT_DEC 	: '*' POINT_DEC {$$=$2+1;} | '*' {$$=1;} ;

%%

void yyerror(){
  printf("\nSyntax Error\n\n");
}

extern FILE * yyin;

int main(int argc, char* argv[])
{
	if(argc > 1)
	{
		FILE *fp = fopen(argv[1], "r");
		if(fp)
			yyin = fp;
	}
	yyparse();
	return 0;
}
void print_IG(struct Node* root)
{
    if(root == NULL || strcmp(root->tok,"operator")!=0)return;
    
    print_IG(root->left);
    print_IG(root->right);
    printf("\n");
    print_TAC(&root->ig);
    if(strcmp(root->lexeme,"prefix increment") == 0
    || strcmp(root->lexeme,"prefix decrement") == 0)
    {
        printf("\n");
        print_k(&root->ig.tr1);
        printf("=");
        print_k(&root->ig.tl);
    }
    if(strcmp(root->lexeme,"postfix increment") == 0)
    {
        printf("\n");
        print_k(&root->ig.tr1);
        printf("=");
        print_k(&root->ig.tl);
        printf("+1");
    }
    if(strcmp(root->lexeme,"postfix decrement") == 0)
    {
        printf("\n");
        print_k(&root->ig.tr1);
        printf("=");
        print_k(&root->ig.tl);
        printf("-1");
    }
}
void print_k(struct K* t)
    {
        if(t->is_address==1)
        {
            if(t->lval==-1)printf("%s",t->varname);
            else printf("t%d",t->lval);
        }
        else if(t->rval->type==0)printf("%lld",t->rval->v_i);
        else if(t->rval->type==1)printf("%lf",t->rval->v_f);
    }
    void print_TAC(struct TAC* ig)
    {
        print_k(&(ig->tl));
        printf("=");
        print_k(&(ig->tr1));
        printf("%c",ig->op);
        print_k(&(ig->tr2));
    }
void print_Statement(struct Statement* s)
{
    if(mode==2)
    {
        if(s->type == 2)
    {
        //printf("\nstatement identified\n");
        print_IG(s->exp);
        printf("\n%s=",s->lval);
        print_k(&(s->exp->ig.tl));
    }
    else if(s->type == 1)
    {
        //printf("\nunary statement identified\n");
        print_IG(s->exp);
    }
    else if(s->type == 0)
    {
        //printf("\nnull statement identified\n");
    }
    else if(s->type == 3)
    {
        printf("\ngoto L%d",l_break);
    }
    else if(s->type == 4)
    {
        printf("\ngoto L%d",l_continue);
    }
    }
    else if(mode == 1 && s->d != NULL)
    {
        printf("\n%d\t%s\t",memory,s->d->name);
        int size=0;
        if(s->d->type_base==0){size=1;printf("char");}
        else if(s->d->type_base==1){size=2;printf("short");}
        else if(s->d->type_base==2){size=4;printf("int");}
        else if(s->d->type_base==3){size=4;printf("float");}
        else if(s->d->type_base==4){size=8;printf("long");}
        else if(s->d->type_base==5){size=8;printf("double");}
        if(s->d->type_modifier==1){size*=s->d->dim_prod;printf(" array %d",size);}
        else if(s->d->type_modifier==2){size=4;printf(" pointer");}
        memory+=size;
    }
}
int new_label()
{
    label++;
    return label-1;
}
void print_Block(struct Block* bl)
{
    //printf("\nprint_block called");
    memory = 0;
    if(bl==NULL)return;
    print_Program(bl->p);
}
void print_Prog(struct Prog* p)
{
    if(p->type==-1)return;
    else if(p->type==-2)print_Statement(p->s1);
    else if(p->type==0)print_Block(p->bl);
    else if(p->type==2)// while
    {
        if(mode!=2){print_Prog(p->p1);return;}

        int L0 = new_label();
        int L1 = new_label();
        int L2 = new_label();
        int lb = l_break;
        int lc = l_continue;
        l_continue = L0;
        l_break = L2;

        printf("\nL%d:",L0);

        print_C_exp(p->exp,L1,L2);
        
        printf("\nL%d:",L1);
        print_Prog(p->p1);
        printf("\ngoto L%d",L0);
        printf("\nL%d:",L2);

        l_break = lb;
        l_continue = lc;
    }
    else if(p->type==1)// if else
    {
        if(mode!=2){print_Prog(p->p1);print_Prog(p->p2);return;}

        int L1 = new_label(); // true
        int L2 = new_label(); // end of block
        int L3 = new_label(); // false
        
        print_C_exp(p->exp,L1,L3);

        printf("\nL%d:",L3);
        print_Prog(p->p2);
        printf("\ngoto L%d",L2);
        printf("\nL%d:",L1);
        print_Prog(p->p1);
        printf("\nL%d:",L2);
    }
    else if(p->type == 3)// do while
    {
        if(mode!=2){print_Prog(p->p1);return;}

        int L0 = new_label();
        int L1 = new_label();
        int L2 = new_label();
        int lb = l_break;
        int lc = l_continue;
        l_break = L1;
        l_continue = L2;

        printf("\nL%d:",L0);
        print_Block(p->bl);
        printf("\nL%d:",L2);

        print_C_exp(p->exp,L0,L1);

        printf("\nL%d:",L1);

        l_break = lb;
        l_continue = lc;
    }
    else if(p->type == 4)// for
    {
        if(mode!=2)
        {
            print_Statement(p->s1);
            print_Prog(p->p1);
            print_Statement(p->s2);
            return;
        }

        int L0 = new_label(); // start
        int L1 = new_label(); // body
        int L2 = new_label(); // update
        int L3 = new_label(); // end
        int lb = l_break;
        int lc = l_continue;
        l_break = L3;
        l_continue = L2;

        print_Statement(p->s1);
        printf("\nL%d:",L0);

        print_C_exp(p->exp,L1,L3);

        printf("\nL%d:",L1);
        print_Prog(p->p1);
        printf("\nL%d:",L2);
        print_Statement(p->s2);
        printf("\ngoto L%d",L0);
        printf("\nL%d:",L3);

        l_break = lb;
        l_continue = lc;
    }
}
void print_Condition_body(struct Condition* c)
{
    if(c==NULL)return;
    print_IG(c->e1);
    if(c->type==1)print_IG(c->e2);
}
void print_C_exp(struct C_exp* c, int Lt, int Lf)
{
    if(c->type == 0)
    {
        print_Condition_body(c->c);
        printf("\nif ");
        print_Condition(c->c);
        printf(" goto L%d",Lt);
        printf("\ngoto L%d",Lf);
    }
    else if(c->type == 1)//NOT
    {
        print_C_exp(c->cl,Lf,Lt);
    }
    else if(c->type == 2)//AND
    {
        int L0 = new_label();
        print_C_exp(c->cl,L0,Lf);
        printf("\nL%d:",L0);
        print_C_exp(c->cr,Lt,Lf);
    }
    else if(c->type == 3)//OR
    {
        int L0 = new_label();
        print_C_exp(c->cl,Lt,L0);
        printf("\nL%d:",L0);
        print_C_exp(c->cr,Lt,Lf);
    }
}
void print_Condition(struct Condition* c)
{
    print_k(&(c->e1->ig.tl));
    if(c->type==0)
    {
        printf("!=0");
    }
    else if(c->type==1)
    {
        printf("%s",c->relop);
        print_k(&(c->e2->ig.tl));
    }
}
void print_Program(struct Program* p)
{
    ONE.type = 0;
    ZERO.type = 0;
    ONE.v_i=1;
    ZERO.v_i=0;
    if(p==NULL)return;
    print_Prog(p->p);
    print_Program(p->next);
}
void print_D_Table(struct D_Table* dt)
{
    struct D_Table_entry* x = dt->head;
    while(x!=NULL)
    {
        printf("\ntype: %d|%d",x->d->type_base,x->d->type_modifier);
        printf("\tname: %s",x->d->name);
        x=x->next;
    }
}
void add(struct D_Table* dt, struct Declaration* d)
{
    struct D_Table_entry* x = dt->tail;
    dt->tail = (struct D_Table_entry*)malloc(sizeof(struct D_Table_entry));
    dt->tail->d = d;
    if(x!=NULL)x->next = dt->tail;
    else dt->head=dt->tail;
}
int search(struct D_Table* dt, char* name)
{
    struct D_Table_entry* x = dt->head;
    while(x!=NULL)
    {
        if(strcmp(x->d->name,name)==0)return 1;
        x=x->next;
    }
    return 0;
}
int get_base_type_of(struct D_Table* dt, char* name) // returns -1 if not found
{
    struct D_Table_entry* x = dt->head;
    while(x!=NULL)
    {
        if(strcmp(x->d->name,name)==0)return x->d->type_base;
        x=x->next;
    }
    return -1;
}
int get_modifier_type_of(struct D_Table* dt, char* name) // returns -1 if not found
{
    struct D_Table_entry* x = dt->head;
    while(x!=NULL)
    {
        if(strcmp(x->d->name,name)==0)return x->d->type_modifier;
        x=x->next;
    }
    return -1;
}
int max_type(int t1, int t2) // some more nuance is there to determine order of types
{
    if(t1>t2)return t1;
    return t2;
}
