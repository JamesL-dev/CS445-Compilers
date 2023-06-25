%{
#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <unistd.h>
#include "treeNodes.h"
#include "treeUtils.h"
#include "scanType.h"
#include "dot.h"
using namespace std;

extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;

int numErrors = 0;
int numWarnings = 0;
extern int line;
extern int yylex();
extern FILE *listing;
void yyerror(const char *msg);

TreeNode *addSibling(TreeNode *t, TreeNode *s) {
   // finish
   //check  for null
   if(s == NULL) {
      printf("ERROR (system): no sibling\n");
      exit (1); // for big problem
   }
   if (t == NULL) {
      return s;
   }
   TreeNode *nodePtr = t;
   while (nodePtr->sibling != NULL) {
      nodePtr = nodePtr->sibling;
   }
   nodePtr->sibling = s;
   // end of linked list
   return t;
}

 // pass the static and type attribute down the sibling list
TreeNode *setType(TreeNode *t, ExpType type, bool isStatic)
{
   while (t) {
      // set t->type and t->isStatic
      t->type = type;
      t->isStatic = isStatic;
      t = t->sibling;
   }
   return t;
}

// the syntax tree goes here
TreeNode *syntaxTree;

%}
%union
{
  TokenData *tokenData;
  TreeNode *tree;
  ExpType type; // for passing type spec up the tree
}
%type <tokenData> assignop minmaxop mulop relop sumop unaryop

%type <tree> andExp argList args breakStmt call compoundStmt constant
%type <tree> declList decl expStmt exp factor funDecl immutable iterRange
%type <tree> precomList
%type <tree> localDecls minmaxExp mulExp mutable parmIdList
%type <tree> parmId parmList parmTypeList parms program relExp returnStmt
%type <tree> scopedVarDecl simpleExp stmtList stmt sumExp
%type <tree> unaryExp unaryRelExp varDeclId varDeclInit varDeclList
%type <tree> varDecl
%type <tree> matched unmatched

%type <type> typeSpec
// we require that ops come before other tokens and be followed by LASTOP and preceded by FIRSTOP
// IMPORTANT: see token string name mapping largerTokens[] below
%token <tokenData> FIRSTOP
%token <tokenData> ADDASS AND DEC DIVASS EQ GEQ INC LEQ MAX MIN MULASS NEQ NOT OR SUBASS
%token <tokenData> CHSIGN SIZEOF
%token <tokenData> '*' '+' '-' '/' '<' '=' '>' '%' '?'
%token <tokenData> PRECOMPILER
%token <tokenData> LASTOP

// we require that all token classes larger than 255 be followed by LASTTERM
%token <tokenData> BOOL BREAK BY CHAR DO ELSE FOR IF INT RETURN STATIC THEN TO WHILE
%token <tokenData> BOOLCONST CHARCONST ID NUMCONST STRINGCONST
%token <tokenData> '(' ')' ',' ';' '[' '{' '}' ']' ':'
%token <tokenData> LASTTERM

%%
program        :  precomList declList                             { syntaxTree = $2; }
               ;
precomList     : precomList PRECOMPILER                      { $$ = NULL; printf("%s\n", yylval.tokenData->tokenstr);}
               | PRECOMPILER                                 { $$ = NULL; printf("%s\n", yylval.tokenData->tokenstr);}
               | /* empty */                                 { $$ = NULL;}
               ;
declList       :  declList decl                                   { $$ = addSibling($1, $2); }
               |  decl                                            { $$ = $1; }
               ;
decl           :  varDecl                                         { $$ = $1; }
               |  funDecl                                         { $$ = $1; }
               ;
varDecl        :  typeSpec varDeclList ';'                        { $$ = $2; setType($2, $1, false); }
               ;
scopedVarDecl  :  STATIC typeSpec varDeclList ';'                 { $$ = $3; setType($3, $2, true); yyerrok; }
               |  typeSpec varDeclList ';'                        { $$ = $2; setType($2, $1, false); yyerrok; }
               ;
varDeclList    :  varDeclList ',' varDeclInit                     { $$ = addSibling($1, $3); yyerrok; }
               |  varDeclInit                                     { $$ = $1; }
               ;
varDeclInit    :  varDeclId                                       { $$ = $1; }
               |  varDeclId ':' simpleExp                         { $$ = $1; 
                                                                     if ($$ != NULL) $$->child[0] = $3; }
               ;
varDeclId      :  ID                                              { $$ = newDeclNode(VarK, UndefinedType, $1);
                                                                     $$->isArray = false;
                                                                     $$->size = 1; }
               |  ID '[' NUMCONST ']'                             { $$ = newDeclNode(VarK, UndefinedType, $1);
                                                                     $$->isArray = true;
                                                                     $$->size = $3->nvalue + 1; }
               ;
typeSpec       :  INT                                             { $$ = Integer; }
               |  BOOL                                            { $$ = Boolean; }
               |  CHAR                                            { $$ = Char; }
               ;
funDecl        :  typeSpec ID '(' parms ')' stmt                  { $$ = newDeclNode(FuncK, $1, $2, $4, $6); }
               |  ID '(' parms ')' stmt                           { $$ = newDeclNode(FuncK, Void, $1, $3, $5); } 
               ;
parms          :  parmList                                        { $$ = $1; }
               |  /* empty */                                     { $$ = NULL; }
               ;
parmList       :  parmList ';' parmTypeList                       { $$ = addSibling($1, $3); }
               |  parmTypeList                                    { $$ = $1; }
               ;
parmTypeList   :  typeSpec parmIdList                             { $$ = $2; setType($2, $1, false); }
               ;
parmIdList     :  parmIdList ',' parmId                           { $$ = addSibling($1, $3); yyerrok; }
               |  parmId                                          { $$ = $1; }
               ;
parmId         :  ID                                              { $$ = newDeclNode(ParamK, UndefinedType, $1);
                                                                    $$->isArray = false;
                                                                    $$->size = 1; }
               |  ID '[' ']'                                      { $$ = newDeclNode(ParamK, UndefinedType, $1); 
                                                                    $$->isArray = true;
                                                                    $$->size = 1; }
               ;
stmt           :  matched                                         { $$ = $1; }
               |  unmatched                                       { $$ = $1; }
               ;
matched        :  IF simpleExp THEN matched ELSE matched          { $$ = newStmtNode(IfK, $1, $2, $4, $6); }
               |  WHILE simpleExp DO matched                      { $$ = newStmtNode(WhileK, $1, $2, $4); }
               |  FOR ID '=' iterRange DO matched                 { $$ = newStmtNode(ForK, $1, NULL, $4, $6);
                                                                     $$->child[0] = newDeclNode(VarK, Integer, $2);
                                                                     $$->child[0]->attr.name = $2->svalue;
                                                                     $$->child[0]->isArray = false; 
                                                                     $$->child[0]->size = 1; }
               |  expStmt                                         { $$ = $1; }
               |  compoundStmt                                    { $$ = $1; }
               |  returnStmt                                      { $$ = $1; }
               |  breakStmt                                       { $$ = $1; }
               ;
iterRange      :  simpleExp TO simpleExp                          {$$ = newStmtNode(RangeK, $2, $1, $3); }
               |  simpleExp TO simpleExp BY simpleExp             {$$ = newStmtNode(RangeK, $2, $1, $3, $5); }
               ;
unmatched      :  IF simpleExp THEN stmt                          { $$ = newStmtNode(IfK, $1, $2, $4); }
               |  IF simpleExp THEN matched ELSE unmatched        { $$ = newStmtNode(IfK, $1, $2, $4, $6); }
               |  WHILE simpleExp DO unmatched                    { $$ = newStmtNode(WhileK, $1, $2, $4); }
               |  FOR ID '=' iterRange DO unmatched               { $$ = newStmtNode(ForK, $1, NULL, $4, $6);
                                                                     $$->child[0] = newDeclNode(VarK, Integer, $2);
                                                                     $$->child[0]->attr.name = $2->svalue;
                                                                     $$->child[0]->isArray = false;
                                                                     $$->child[0]->size = 1; }
               ;
expStmt        :  exp ';'                                         { $$ = $1; }
               | ';'                                              { $$ = NULL; }
               ;
compoundStmt   :  '{' localDecls stmtList '}'                     { $$ = newStmtNode(CompoundK, $1, $2, $3); yyerrok; }
               ;
localDecls     :  localDecls scopedVarDecl                        { $$ = addSibling($1, $2); }
               |  /* empty */                                     { $$ = NULL; }
               ;
stmtList       :  stmtList stmt                                   { $$ = ($2 == NULL ? $1 : addSibling($1, $2)); }
               |  /* empty */                                     { $$ = NULL; }
               ;
returnStmt     :  RETURN ';'                                      { $$ = newStmtNode(ReturnK, $1); }
               |  RETURN exp ';'                                  { $$ = newStmtNode(ReturnK, $1, $2); yyerrok; }
               ;
breakStmt      :  BREAK ';'                                       { $$ = newStmtNode(BreakK, $1); }
               ;
exp            :  mutable assignop exp                            { $$ = newExpNode(AssignK, $2, $1, $3); }
               |  mutable INC                                     { $$ = newExpNode(AssignK, $2, $1); }
               |  mutable DEC                                     { $$ = newExpNode(AssignK, $2, $1); }
               |  simpleExp                                       { $$ = $1; }
               ;
assignop       :  '='                                             { $$ = $1;  }
               |  ADDASS                                          { $$ = $1;  }
               |  SUBASS                                          { $$ = $1;  }
               |  MULASS                                          { $$ = $1;  }
               |  DIVASS                                          { $$ = $1;}
               ;
simpleExp      :  simpleExp OR andExp                             { $$ = newExpNode(OpK, $2, $1, $3); }
               |  andExp                                          { $$ = $1; }
               ;
andExp         :  andExp AND unaryRelExp                          { $$ = newExpNode(OpK, $2, $1, $3); }
               |  unaryRelExp                                     { $$ = $1; }
               ;
unaryRelExp    :  NOT unaryRelExp                                 { $$ = newExpNode(OpK, $1, $2);
                                                                     $$->attr.op = NOT; }
               |  relExp                                          { $$ = $1; }
               ;
relExp         :  minmaxExp relop minmaxExp                       { $$ = $1; }
               |  minmaxExp                                       { $$ = $1; }
               ; 
relop          :  LEQ                                             { $$ = $1;}
               |  '<'                                             { $$ = $1;}
               |  '>'                                             { $$ = $1;}
               |  GEQ                                             { $$ = $1;}
               |  EQ                                              { $$ = $1;}
               |  NEQ                                             { $$ = $1;}
               ;
minmaxExp      :  minmaxExp minmaxop sumExp                       { $$ = newExpNode(OpK, $2, $1, $3); }
               |  sumExp                                          { $$ = $1; }
               ;
minmaxop       :  MAX                                             { $$ = $1; }
               |  MIN                                             { $$ = $1; }
               ;

sumExp         :  sumExp sumop mulExp                             { $$ = newExpNode(OpK, $2, $1, $3); }
               |  mulExp                                          { $$ = $1; }
               ;
sumop          :  '+'                                             { $$ = $1;}
               |  '-'                                             { $$ = $1;}
               ;
mulExp         :  mulExp mulop unaryExp                           { $$ = newExpNode(OpK, $2, $1, $3); }
               |  unaryExp                                        { $$ = $1; }
               ;
mulop          :  '*'                                             { $$ = $1; }
               |  '/'                                             { $$ = $1; }
               |  '%'                                             { $$ = $1; }
               ;
unaryExp       :  unaryop unaryExp                                { $$ = newExpNode(OpK, $1, $2); }
               |  factor                                          { $$ = $1; }
               ;
unaryop        :  '-'                                             {$1->tokenclass=CHSIGN; $$=$1; }
               |  '*'                                             {$1->tokenclass=SIZEOF; $$=$1; }
               |  '?'                                             { $$ = $1; }
               ;
factor         :  immutable                                       { $$ = $1; }
               |  mutable                                         { $$ = $1; }
               ;
mutable        :  ID                                              { $$ = newExpNode(IdK, $1);
                                                                     $$->isArray = false; 
                                                                     $$->attr.name = $1->svalue; }
               |  ID '[' exp ']'                                  { $$ = newExpNode(OpK, $2, NULL, $3);
                                                                     $$->child[0] = newExpNode(IdK, $1); 
                                                                     $$->child[0]->attr.name = $1->svalue;
                                                                     $$->isArray = false; }
               ;
immutable      :  '(' exp ')'                                     { $$ = $2; }
               |  call                                            { $$ = $1; }
               |  constant                                        { $$ = $1; }
               ;
call           :  ID '(' args ')'                                 { $$ = newExpNode(CallK, $1, $3);
                                                                     $$->attr.name = $1->svalue; }
               ;
args           :  argList                                         { $$ = $1; }
               |  /* empty */                                     { $$ = NULL; }
               ;
argList        :  argList ',' exp                                 { $$ = addSibling($1, $3); yyerrok; }
               |  exp                                             { $$ = $1; }
               ;
constant       :  NUMCONST                                        { $$ = newExpNode(ConstantK, $1);
                                                                     $$->attr.value = $1->nvalue;
                                                                     $$->type = Integer;
                                                                     $$->isArray = false;
                                                                     $$->size = 1; }
               |  CHARCONST                                       { $$ = newExpNode(ConstantK, $1);
                                                                     $$->attr.value = $1->cvalue;
                                                                     $$->type = Char;
                                                                     $$->isArray = false;
                                                                     $$->size = 1; }
               |  STRINGCONST                                     { $$ = newExpNode(ConstantK, $1);
                                                                     $$->attr.string = $1->svalue;
                                                                     $$->type = Char;
                                                                     $$->isArray = true;
                                                                     $$->size = 1; }
               |  BOOLCONST                                       { $$ = newExpNode(ConstantK, $1);
                                                                     $$->attr.value = $1->nvalue;
                                                                     $$->type = Boolean;
                                                                     $$->isArray = false;
                                                                     $$->size = 1; }
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

static char tokenBuffer[16];
char *tokenToStr(int type)
  { 
   if (type>LASTTERM) {
   return (char*)"UNKNOWN";
    }
    else if (type>256) {
   return largerTokens[type];
    }
    else if ((type<32) || (type>127)) {
   sprintf(tokenBuffer, "Token#%d", type);
    } else {
   tokenBuffer[0] = type;
   tokenBuffer[1] = '\0';
    }
    return tokenBuffer;
}

int main(int argc, char **argv) {
   //yylval.tokdenData.linenum = 1;
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
      printTree(stdout, syntaxTree, false, false);
      if(dotAST) {
         printDotTree(stdout, syntaxTree, false, false);
      }
   }
   else {
      printf("-----------\n");
      printf("Errors: %d\n", numErrors);
      printf("-----------\n");
   }
   // report the number of errors and warnings
   printf("Number of warnings: %d\n", numWarnings);
   printf("Number of errors: %d\n", numErrors);
   return 0;
}
