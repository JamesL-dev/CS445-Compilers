%{
#include <stdio>
#include <iostream>
#include <Stdlib.h>
#include <unistd.h>
#include "treeUtils.h"
#include "scanType.h"
#include "dot.h"
using namespace std;

extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;
int numErrors;
int numWarnings;
extern int line;
extern int yylex();

TreeNode *addSibling(TreeNode *t, TreeNode *s)
{
  // make sure s is not null. if it is this s a major error, exit the program!
  // Make sure t is not null. if it is, just return s
  // look down t's sibling list until you fin with with sibbling = null(the end of the list) and add s there.
  return s;
}

// pass the static and type attribute down the sibling list
void setType(TreeNode *t, ExpType type, bool isStatic)
{
  while(t) 
  {
    //set t->type and t->static
    t = t-> siblingl;
  }
}

// the syntax tree goes here
TreeNode *syntaxTree;

void yyerror(const char *msg);

%}
%union
{
  TokenData *tokenData;
  TreeNode *tree;
  ExpType type; // for passing type spec up the tree
}


%type <tree> program declList decl varDecl scopedVarDecl varDeclList varDeclInit
%type <tree> varDeclId funDecl parms parmList parmTypeList parmIdList parmId stmt
%type <tree> stmtUnmatched stmtMatched expStmt compountStmt localDecls stmtList
%type <tree> selectStmtUnmatched selectStmtMatched iterStmtUnmatched iterStmtMatched iterRange
%type <tree> returnStmt breakStmt exp assignop simpleExp andExp unaryRelExp relExp relOp sumExp
%type <tree> factor mutable immutable call args argList constant

%type <type> typeSpec
%token <tokenData> '(' ')' ',' ';' '[' '{' '}' ']' ':‘
 // %token <tokenData> ADD SUB MUL DIV MOD INC DEC QUESTION // Add to single character operators above
%token <tokdenData> FIRSTOP
%type <tokenData> sumOp mulExp mulOp unaryExp unaryOp
%token <tokenData> GT GEQ LT LEQ EQ NEQ
%token <tokdenData> LASTOP

%token <tokenData> PRECOMPILER PRECOMPILER2
%token <tokenData> NUMCONST BOOLCONST CHARCONST STRINGCONST ID
%token <tokenData> INT BOOL CHAR STATIC
%token <tokenData> ASS ADDASS SUBASS MULASS DIVASS MIN MAX
%token <tokenData> IF THEN ELSE WHILE FOR TO BY DO
%token <tokenData> COLON SEMICOLON COMMA
%token <tokenData> RETURN BREAK
%token <tokenData> AND OR NOT
%token <tokenData> RPAREN LPAREN RBRACK LBRACK LCURLY RCURLY
%token <tokdenData> LASTTERM

%%
program                 : declList
                        {
                            $$ = $1;
                            syntaxTree = $$;
                        }
                        ;

declList                : declList decl
                        {
                            $$ = $1;
                            $$->addSibling($2);
                        }
                        | decl
                        {
                            $$ = $1;
                        }
                        ;

decl                    : varDecl
                        {
                            $$ = $1;
                        }
                        | funDecl
                        {
                            $$ = $1;
                        }
                        ;

varDecl                 : typeSpec varDeclList SEMICOLON
                        {
                            $$ = $2;
                            Var *tree = (Var *)$$;
                            tree->setType($1);
                        }
                        ;

scopedVarDecl           : STATIC typeSpec varDeclList SEMICOLON
                        {
                            $$ = $3;
                            Var *tree = (Var *)$$;
                            tree->setType($2);
                            tree->makeStatic();
                        }
                        | typeSpec varDeclList SEMICOLON
                        {
                            $$ = $2;
                            Var *tree = (Var *)$$;
                            tree->setType($1);
                        }
                        ;

varDeclList             : varDeclList COMMA varDeclInit
                        {
                            $$ = $1;
                            $$->addSibling($3);
                        }
                        | varDeclInit
                        {
                            $$ = $1;
                        }
                        ;

varDeclInit             : varDeclId
                        {
                            $$ = $1;
                        }
                        | varDeclId COLON simpleExp
                        {
                            $$ = $1;
                            $$->addChild($3);
                        }
                        ;

varDeclId               : ID
                        {
                            $$ = new Var($1->tokenLineNum, new Primitive(Primitive::Type::Void), $1->tokenContent);
                        }
                        | ID LBRACK NUMCONST RBRACK
                        {
                            $$ = new Var($1->tokenLineNum, new Primitive(Primitive::Type::Void, true), $1->tokenContent);
                        }
                        ;

typeSpec                : INT
                        {
                            $$ = Primitive::Type::Int;
                        }
                        | BOOL
                        {
                            $$ = Primitive::Type::Bool;
                        }
                        | CHAR
                        {
                            $$ = Primitive::Type::Char;
                        }
                        ;

funDecl                 : typeSpec ID LPAREN parms RPAREN compoundStmt
                        {
                            $$ = new Func($2->tokenLineNum, new Primitive($1), $2->tokenContent);
                            $$->addChild($4);
                            $$->addChild($6);
                        }
                        | ID LPAREN parms RPAREN compoundStmt
                        {
                            $$ = new Func($1->tokenLineNum, new Primitive(Primitive::Type::Void), $1->tokenContent);
                            $$->addChild($3);
                            $$->addChild($5);
                        }
                        ;

parms                   : parmList
                        {
                            $$ = $1;
                        }
                        |
                        {
                            $$ = nullptr;
                        }
                        ;

parmList                : parmList SEMICOLON parmTypeList
                        {
                            $$ = $1;
                            $$->addSibling($3);
                        }
                        | parmTypeList
                        {
                            $$ = $1;
                        }
                        ;

parmTypeList            : typeSpec parmIdList
                        {
                            $$ = $2;
                            Parm *tree = (Parm *)$$;
                            tree->setType($1);
                        }
                        ;

parmIdList              : parmIdList COMMA parmId
                        {
                            if ($1 == nullptr)
                            {
                                $$ = $3;
                            }
                            else
                            {
                                $$ = $1;
                                $$->addSibling($3);
                            }
                        }
                        | parmId
                        {
                            $$ = $1;
                        }
                        ;

parmId                  : ID
                        {
                            $$ = new Parm($1->tokenLineNum, new Primitive(Primitive::Type::Void), $1->tokenContent);
                        }
                        | ID LBRACK RBRACK
                        {
                            $$ = new Parm($1->tokenLineNum, new Primitive(Primitive::Type::Void, true), $1->tokenContent);
                        }
                        ;

stmt                    : stmtUnmatched
                        {
                            $$ = $1;
                        }
                        | stmtMatched
                        {
                            $$ = $1;
                        }
                        ;

stmtUnmatched           : selectStmtUnmatched
                        {
                            $$ = $1;
                        }
                        | iterStmtUnmatched
                        {
                            $$ = $1;
                        }
                        ;

stmtMatched             : selectStmtMatched
                        {
                            $$ = $1;
                        }
                        | iterStmtMatched
                        {
                            $$ = $1;
                        }
                        | expStmt
                        {
                            $$ = $1;
                        }
                        | compoundStmt
                        {
                            $$ = $1;
                        }
                        | returnStmt
                        {
                            $$ = $1;
                        }
                        | breakStmt
                        {
                            $$ = $1;
                        }
                        ;

expStmt                 : exp SEMICOLON
                        {
                            $$ = $1;
                        }
                        | SEMICOLON
                        {
                            $$ = nullptr;
                        }
                        ;

compoundStmt            : LCURLY localDecls stmtList RCURLY
                        {
                            $$ = new Compound($1->tokenLineNum);
                            $$->addChild($2);
                            $$->addChild($3);
                        }
                        ;

localDecls              : localDecls scopedVarDecl
                        {
                            if ($1 == nullptr)
                            {
                                $$ = $2;
                            }
                            else
                            {
                                $$ = $1;
                                $$->addSibling($2);
                            }
                        }
                        |
                        {
                            $$ = nullptr;
                        }
                        ;

stmtList                : stmtList stmt
                        {
                            if ($1 == nullptr)
                            {
                                $$ = $2;
                            }
                            else
                            {
                                $$ = $1;
                                $$->addSibling($2);
                            }
                        }
                        |
                        {
                            $$ = nullptr;
                        }
                        ;

selectStmtUnmatched     : IF simpleExp THEN stmt
                        {
                            $$ = new If($1->tokenLineNum);
                            $$->addChild($2);
                            $$->addChild($4);
                        }
                        | IF simpleExp THEN stmtMatched ELSE stmtUnmatched
                        {
                            $$ = new If($1->tokenLineNum);
                            $$->addChild($2);
                            $$->addChild($4);
                            $$->addChild($6);
                        }
                        ;

selectStmtMatched       : IF simpleExp THEN stmtMatched ELSE stmtMatched
                        {
                            $$ = new If($1->tokenLineNum);
                            $$->addChild($2);
                            $$->addChild($4);
                            $$->addChild($6);
                        }
                        ;

iterStmtUnmatched       : WHILE simpleExp DO stmtUnmatched
                        {
                            $$ = new While($1->tokenLineNum);
                            $$->addChild($2);
                            $$->addChild($4);
                        }
                        | FOR ID ASGN iterRange DO stmtUnmatched
                        {
                            $$ = new For($1->tokenLineNum);
                            Var *tree = new Var($2->tokenLineNum, new Primitive(Primitive::Type::Int), $2->tokenContent);
                            $$->addChild(tree);
                            $$->addChild($4);
                            $$->addChild($6);
                        }
                        ;

iterStmtMatched         : WHILE simpleExp DO stmtMatched
                        {
                            $$ = new While($1->tokenLineNum);
                            $$->addChild($2);
                            $$->addChild($4);
                        }
                        | FOR ID ASGN iterRange DO stmtMatched
                        {
                            $$ = new For($1->tokenLineNum);
                            Var *tree = new Var($2->tokenLineNum, new Primitive(Primitive::Type::Int), $2->tokenContent);
                            $$->addChild(tree);
                            $$->addChild($4);
                            $$->addChild($6);
                        }
                        ;

iterRange               : simpleExp TO simpleExp
                        {
                            $$ = new Range($1->getTokenLineNum());
                            $$->addChild($1);
                            $$->addChild($3);
                        }
                        | simpleExp TO simpleExp BY simpleExp
                        {
                            $$ = new Range($1->getTokenLineNum());
                            $$->addChild($1);
                            $$->addChild($3);
                            $$->addChild($5);
                        }
                        ;

returnStmt              : RETURN SEMICOLON
                        {
                            $$ = new Return($1->tokenLineNum);
                        }
                        | RETURN exp SEMICOLON
                        {
                            $$ = new Return($1->tokenLineNum);
                            $$->addChild($2);
                        }
                        ;

breakStmt               : BREAK SEMICOLON
                        {
                            $$ = new Break($1->tokenLineNum);
                        }
                        ;

exp                     : mutable assignop exp
                        {
                            $$ = $2;
                            $$->addChild($1);
                            $$->addChild($3);
                        }
                        | mutable INC
                        {
                            $$ = new UnaryAsgn($1->getTokenLineNum(), UnaryAsgn::Type::Inc);
                            $$->addChild($1);
                        }
                        | mutable DEC
                        {
                            $$ = new UnaryAsgn($1->getTokenLineNum(), UnaryAsgn::Type::Dec);
                            $$->addChild($1);
                        }
                        | simpleExp
                        {
                            $$ = $1;
                        }
                        ;

assignop                : ASGN
                        {
                            $$ = new Asgn($1->tokenLineNum, Asgn::Type::Asgn);
                        }
                        | ADDASGN
                        {
                            $$ = new Asgn($1->tokenLineNum, Asgn::Type::AddAsgn);
                        }
                        | SUBASGN
                        {
                            $$ = new Asgn($1->tokenLineNum, Asgn::Type::SubAsgn);
                        }
                        | MULASGN
                        {
                            $$ = new Asgn($1->tokenLineNum, Asgn::Type::MulAsgn);
                        }
                        | DIVASGN
                        {
                            $$ = new Asgn($1->tokenLineNum, Asgn::Type::DivAsgn);
                        }
                        ;

simpleExp               : simpleExp OR andExp
                        {
                            $$ = new Binary($1->getTokenLineNum(), Binary::Type::Or);
                            $$->addChild($1);
                            $$->addChild($3);
                        }
                        | andExp
                        {
                            $$ = $1;
                        }
                        ;

andExp                  : andExp AND unaryRelExp
                        {
                            $$ = new Binary($1->getTokenLineNum(), Binary::Type::And);
                            $$->addChild($1);
                            $$->addChild($3);
                        }
                        | unaryRelExp
                        {
                            $$ = $1;
                        }
                        ;

unaryRelExp             : NOT unaryRelExp
                        {
                            $$ = new Unary($1->tokenLineNum, Unary::Type::Not);
                            $$->addChild($2);
                        }
                        | relExp
                        {
                            $$ = $1;
                        }
                        ;

relExp                  : sumExp relOp sumExp
                        {
                            $$ = $2;
                            $$->addChild($1);
                            $$->addChild($3);
                        }
                        | sumExp
                        {
                            $$ = $1;
                        }
                        ;

relOp                   : LT
                        {
                            $$ = new Binary($1->tokenLineNum, Binary::Type::LT);
                        }
                        | LEQ
                        {
                            $$ = new Binary($1->tokenLineNum, Binary::Type::LEQ);
                        }
                        | GT
                        {
                            $$ = new Binary($1->tokenLineNum, Binary::Type::GT);
                        }
                        | GEQ
                        {
                            $$ = new Binary($1->tokenLineNum, Binary::Type::GEQ);
                        }
                        | EQ
                        {
                            $$ = new Binary($1->tokenLineNum, Binary::Type::EQ);
                        }
                        | NEQ
                        {
                            $$ = new Binary($1->tokenLineNum, Binary::Type::NEQ);
                        }
                        ;

sumExp                  : sumExp sumOp mulExp
                        {
                            $$ = $2;
                            $$->addChild($1);
                            $$->addChild($3);
                        }
                        | mulExp
                        {
                            $$ = $1;
                        }
                        ;

sumOp                   : ADD
                        {
                            $$ = new Binary($1->tokenLineNum, Binary::Type::Add);
                        }
                        | SUB
                        {
                            $$ = new Binary($1->tokenLineNum, Binary::Type::Sub);
                        }
                        ;

mulExp                  : mulExp mulOp unaryExp
                        {
                            $$ = $2;
                            $$->addChild($1);
                            $$->addChild($3);
                        }
                        | unaryExp
                        {
                            $$ = $1;
                        }
                        ;

mulOp                   : MUL
                        {
                            $$ = new Binary($1->tokenLineNum, Binary::Type::Mul);
                        }
                        | DIV
                        {
                            $$ = new Binary($1->tokenLineNum, Binary::Type::Div);
                        }
                        | MOD
                        {
                            $$ = new Binary($1->tokenLineNum, Binary::Type::Mod);
                        }
                        ;

unaryExp                : unaryOp unaryExp
                        {
                            $$ = $1;
                            $$->addChild($2);
                        }
                        | factor
                        {
                            $$ = $1;
                        }
                        ;

unaryOp                 : SUB
                        {
                            $$ = new Unary($1->tokenLineNum, Unary::Type::Chsign);
                        }
                        | MUL
                        {
                            $$ = new Unary($1->tokenLineNum, Unary::Type::Sizeof);
                        }
                        | QUESTION
                        {
                            $$ = new Unary($1->tokenLineNum, Unary::Type::Question);
                        }
                        ;

factor                  : mutable
                        {
                            $$ = $1;
                        }
                        | immutable
                        {
                            $$ = $1;
                        }
                        ;

mutable                 : ID
                        {
                            $$ = new Id($1->tokenLineNum, $1->tokenContent);
                        }
                        | ID LBRACK exp RBRACK
                        {
                            $$ = new Binary($1->tokenLineNum, Binary::Type::Index);
                            Id *tree = new Id($1->tokenLineNum, $1->tokenContent, true);
                            $$->addChild(tree);
                            $$->addChild($3);
                        }
                        ;

immutable               : LPAREN exp RPAREN
                        {
                            $$ = $2;
                        }
                        | call
                        {
                            $$ = $1;
                        }
                        | constant
                        {
                            $$ = $1;
                        }
                        ;

call                    : ID LPAREN args RPAREN
                        {
                            $$ = new Call($1->tokenLineNum, $1->tokenContent);
                            $$->addChild($3);
                        }
                        ;

args                    : argList
                        {
                            $$ = $1;
                        }
                        |
                        {
                            $$ = nullptr;
                        }
                        ;

argList                 : argList COMMA exp
                        {
                            $$ = $1;
                            $$->addSibling($3);
                        }
                        | exp
                        {
                            $$ = $1;
                        }
                        ;

constant                : NUMCONST
                        {
                            $$ = new Const($1->tokenLineNum, Const::Type::Int, $1->tokenContent);
                        }
                        | BOOLCONST
                        {
                            $$ = new Const($1->tokenLineNum, Const::Type::Bool, $1->tokenContent);
                        }
                        | CHARCONST
                        {
                            $$ = new Const($1->tokenLineNum, Const::Type::Char, $1->tokenContent);
                        }
                        | STRINGCONST
                        {
                            $$ = new Const($1->tokenLineNum, Const::Type::String, $1->tokenContent);
                        }
                        ;
%%
void yyerror (const char *msg)
{ 
   cout << "Error: " <<  msg << endl;
}
char *largerTokens[LASTTERM+1]; // used in the utils.cpp file printing routines
// create a mapping from token class enum to a printable name in a
// way that makes it easy to keep the mapping straight.
void initTokenStrings()
{
largerTokens[ADDASS] = (char *)"+=";
largerTokens[AND] = (char *)"and";
largerTokens[BOOL] = (char *)"bool";
largerTokens[BOOLCONST] = (char *)"boolconst";
largerTokens[BREAK] = (char *)"break";
largerTokens[BY] = (char *)"by";
largerTokens[CHAR] = (char *)"char";
largerTokens[CHARCONST] = (char *)"charconst";
largerTokens[CHSIGN] = (char *)"chsign";
largerTokens[DEC] = (char *)"--";
largerTokens[DIVASS] = (char *)"/=";
largerTokens[DO] = (char *)"do";
largerTokens[ELSE] = (char *)"else";
largerTokens[EQ] = (char *)"==";
largerTokens[FOR] = (char *)"for";
largerTokens[GEQ] = (char *)">=";
largerTokens[ID] = (char *)"id";
largerTokens[IF] = (char *)"if";
largerTokens[INC] = (char *)"++";
largerTokens[INT] = (char *)"int";
largerTokens[LEQ] = (char *)"<=";
largerTokens[MAX] = (char *)":>:";
largerTokens[MIN] = (char *)":<:";
largerTokens[MULASS] = (char *)"*=";
largerTokens[NEQ] = (char *)"!=";
largerTokens[NOT] = (char *)"not";
largerTokens[NUMCONST] = (char *)"numconst";
largerTokens[OR] = (char *)"or";
largerTokens[RETURN] = (char *)"return";
largerTokens[SIZEOF] = (char *)"sizeof";
largerTokens[STATIC] = (char *)"static";
largerTokens[STRINGCONST] = (char *)"stringconst";
largerTokens[SUBASS] = (char *)"-=";
largerTokens[THEN] = (char *)"then";
largerTokens[TO] = (char *)"to";
largerTokens[WHILE] = (char *)"while";
largerTokens[LASTTERM] = (char *)"lastterm";
}

int main(int argc, char **argv) {
   //yylval.tinfo.linenum = 1;
   int index;
   char *file = NULL;
   bool dotAST = false;             // make dot file of AST
   extern FILE *yyin;

   int ch;

   while ((ch = getopt(argc, argv, "d")) != -1) {
      switch (ch) {
         case 'd':
                 dotAST = true;
                 break;
         case '?':
         default:
                 //usage();
               ;
      }
   }

   if ( optind == argc ) yyparse();
   for (index = optind; index < argc; index++)
   {
      yyin = fopen (argv[index], "r");
      yyparse();
      fclose (yyin);
   }
   if (numErrors==0) {
      printTree(stdout, syntaxTree, true, true);
      if(dotAST) {
         printDotTree(stdout, syntaxTree, false, false);
      }
   }
   else {
      printf("-----------\n");
      printf("Errors: %d\n", numErrors);
      printf("-----------\n");
   }
   return 0;
}
