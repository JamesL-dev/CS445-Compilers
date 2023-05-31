%{
#include <cstdio>
#include <iostream>
#include <unistd.h>
#include "scanType.h"
using namespace std;

extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;

void yyerror(const char *msg);

void printToken(TokenData myData, string tokenName, int type = 0) {
   cout << "Line: " << myData.linenum << " Type: " << tokenName;
   if(type==0)
     cout << " Token: " << myData.tokenstr;
   if(type==1)
     cout << " Token: " << myData.nvalue;
   if(type==2)
     cout << " Token: " << myData.cvalue;
   cout << endl;
}

%}
%union
{
   struct   TokenData tinfo ;
}

%token <tinfo> PRECOMPILER PRECOMPILER2
%token <tinfo> NUMCONST BOOLCONST CHARCONST STRINGCONST ID
%token <tinfo> INT BOOL CHAR STATIC
%token <tinfo> ASS ADDASS SUBASS MULASS DIVASS MIN MAX
%token <tinfo> IF THEN ELSE WHILE FOR TO BY DO
%token <tinfo> COLON SEMICOLON COMMA
%token <tinfo> RETURN BREAK
%token <tinfo> AND OR NOT
%token <tinfo> ADD SUB MUL DIV MOD INC DEC QUESTION
%token <tinfo> RPAREN LPAREN RBRACK LBRACK LCURLY RCURLY
%token <tinfo> GT GEQ LT LEQ EQ NEQ
%token <tinfo> ERROR 

%type <tinfo> program term
 //%type <node> program declList decl varDecl scopedVarDecl varDeclList varDeclInit
 //%type <node> varDeclId funDecl parms parmList parmTypeList parmIdList parmId stmt
 //%type <node> stmtUnmatched stmtMatched expStmt compountStmt localDecls stmtList
 //%type <node> selectStmtUnmatched selectStmtMatched iterStmtUnmatched iterStmtMatched iterRange
 //%type <node> returnStmt breakStmt exp assignop simpleExp andExp unaryRelExp relExp relOp sumExp
 //%type <node> sumOp mulExp mulOp unaryExp unaryOp factor mutable immutable call args argList constant

%%
program : program term
        | term {$$=$1;}
        ;
term :    PRECOMPILER   {printToken(yyval.tinfo, "PRECOMPILER");}
        | PRECOMPILER2  {printToken(yyval.tinfo, "PRECOMPILER");}
        | INT           {printToken(yyval.tinfo, "INT");}
        | BOOL          {printToken(yyval.tinfo, "BOOL");}
        | CHAR          {printToken(yyval.tinfo, "CHAR");}
        | STATIC        {printToken(yyval.tinfo, "STATIC");}
        | IF            {printToken(yyval.tinfo, "IF");}
        | THEN          {printToken(yyval.tinfo, "THEN");}
        | ELSE          {printToken(yyval.tinfo, "ELSE");}
        | WHILE         {printToken(yyval.tinfo, "WHILE");}
        | FOR           {printToken(yyval.tinfo, "FOR");}
        | TO            {printToken(yyval.tinfo, "TO");}
        | BY            {printToken(yyval.tinfo, "BY");}
        | DO            {printToken(yyval.tinfo, "DO");}
        | RETURN        {printToken(yyval.tinfo, "RETURN");}
        | BREAK         {printToken(yyval.tinfo, "BREAK");}
        | AND           {printToken(yyval.tinfo, "AND");}
        | OR            {printToken(yyval.tinfo, "OR");}
        | NOT           {printToken(yyval.tinfo, "NOT");}
        | LCURLY        {printToken(yyval.tinfo, "OP");}
        | RCURLY        {printToken(yyval.tinfo, "OP");}
        | LPAREN        {printToken(yyval.tinfo, "OP");}
        | RPAREN        {printToken(yyval.tinfo, "OP");}
        | LBRACK        {printToken(yyval.tinfo, "OP");}
        | RBRACK        {printToken(yyval.tinfo, "OP");}
        | MUL           {printToken(yyval.tinfo, "OP");}
        | DIV           {printToken(yyval.tinfo, "OP");}
        | MOD           {printToken(yyval.tinfo, "OP");}
        | ADD           {printToken(yyval.tinfo, "OP");}
        | SUB           {printToken(yyval.tinfo, "OP");}
        | INC           {printToken(yyval.tinfo, "INC");}
        | DEC           {printToken(yyval.tinfo, "DEC");}
        | ADDASS        {printToken(yyval.tinfo, "ADDASS");}
        | SUBASS        {printToken(yyval.tinfo, "SUBASS");}
        | MULASS        {printToken(yyval.tinfo, "MULASS");}
        | DIVASS        {printToken(yyval.tinfo, "DIVASS");}
        | MIN           {printToken(yyval.tinfo, "MIN");}
        | MAX           {printToken(yyval.tinfo, "MAX");}
        | EQ            {printToken(yyval.tinfo, "EQ");}
        | NEQ           {printToken(yyval.tinfo, "NEQ");}
        | LT            {printToken(yyval.tinfo, "OP");}
        | LEQ           {printToken(yyval.tinfo, "LEQ");}
        | GT            {printToken(yyval.tinfo, "OP");}
        | GEQ           {printToken(yyval.tinfo, "GEQ");}
        | ASS           {printToken(yyval.tinfo, "OP");}
        | SEMICOLON     {printToken(yyval.tinfo, "OP");}
        | COLON         {printToken(yyval.tinfo, "OP");}
        | COMMA         {printToken(yyval.tinfo, "OP");}
        | QUESTION      {printToken(yyval.tinfo, "OP");}
        | BOOLCONST     {printToken(yyval.tinfo, "BOOLCONST");}
        | ID            {printToken(yyval.tinfo, "ID");}
        | NUMCONST      {printToken(yyval.tinfo, "NUMCONST");}
        | STRINGCONST   {printToken(yyval.tinfo, "STRINGCONST");}
        | CHARCONST     {printToken(yyval.tinfo, "CHARCONST");}
        | ERROR         {cout << "ERROR(" << yyval.tinfo.linenum << "):" << " Token error, invalid or misplaced input character: " << "'" << yyval.tinfo.tokenstr << "'. Character Ignored." <<endl;}
%%
void yyerror (const char *msg)
{ 
   cout << "Error: " <<  msg << endl;
}
int main(int argc, char **argv) {
   yylval.tinfo.linenum = 1;
   int option, index;
   char *file = NULL;
   extern FILE *yyin;
   while ((option = getopt (argc, argv, "")) != -1)
      switch (option)
      {
      default:
         ;
      }
   if ( optind == argc ) yyparse();
   for (index = optind; index < argc; index++) 
   {
      yyin = fopen (argv[index], "r");
      yyparse();
      fclose (yyin);
   }
   return 0;
}

