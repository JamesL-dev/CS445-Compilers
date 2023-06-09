%{
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include "treeNodes.h"
#include "scanType.h"
#include "parser.tab.h"

using namespace std;

char *lastToken = (char*)"";
int line = 1;
extern int numWarnings;
extern int numErrors;

#define YY_DECL extern "C" int yylex()
#define YYSTYPE int

 // need this to communicate between .l and .y files
int setValue(int linenum, int tokenClass, char *svalue) {
    yylval.tokenData = new TokenData;
    //cout << "setvalue:  " << linenum << ", " << tokenClass << ", " << svalue << endl;
    yylval.tokenData->tokenclass = tokenClass;
    yylval.tokenData->linenum = line;
    yylval.tokenData->tokenstr = lastToken = strdup(svalue);
    yylval.tokenData->cvalue = svalue[0];
    yylval.tokenData->nvalue = atoi(svalue); // check to see if should be ll
    yylval.tokenData->svalue = strdup(svalue);

    switch (tokenClass) {
        case BOOLCONST:
            yylval.tokenData->nvalue = ((lastToken[0]=='t') ? 1 : 0);
            break;
        case STRINGCONST:
            yylval.tokenData->nvalue = strlen(svalue);
            break;
        case CHARCONST: // This doesnt work for slash n and slash 0, need fix
            yylval.tokenData->cvalue = svalue[1];
            if (svalue[1] == '\\')
            {
              if (svalue[2] == 'n')
                yylval.tokenData->cvalue = '\n';
              if (svalue[2] == '0')
                yylval.tokenData->cvalue = '\0';
            }
            
            break;
    }
    
    return tokenClass;
}

%}

%option noyywrap

letter      [a-zA-Z]
digit       [0-9]
quote       [\']
underbar    [_]
letdig      {digit}|{letter}|{underbar}
whitespace  [\ \t]
userVar     [letter](letter|digit)*
stringconst \"((\\\")|([^\n\"]))*\"
op   	    [\(\)\*\+\,\-\/\:\;\<\=\>\?\[\]\%\{\}]
charconst2  [\']\\?.[\']
charconst3  [\'](\\[^\n]|[^\'\\\n]*)[\']
comment     \/\/.*

%%
"++"                { return setValue(line, INC, yytext); }
"--"                { return setValue(line, DEC, yytext); }
"=="                { return setValue(line, EQ , yytext); }
"+="                { return setValue(line, ADDASS, yytext); }
"-="                { return setValue(line, SUBASS, yytext); }
"*="                { return setValue(line, MULASS, yytext); }
"/="                { return setValue(line, DIVASS, yytext); }
"!="                { return setValue(line, NEQ, yytext); }
"<="                { return setValue(line, LEQ, yytext); }
">="                { return setValue(line, GEQ, yytext); }
":<:"               { return setValue(line, MIN, yytext); }
":>:"               { return setValue(line, MAX, yytext); }

^"#DRBC ".*         { return setValue(line, PRECOMPILER, yytext);  }
^"#DRBCRUN ".*      { return setValue(line, PRECOMPILER, yytext); }

"if"                { return setValue(line, IF , yytext); }
"then"              { return setValue(line, THEN, yytext); }
"else"              { return setValue(line, ELSE, yytext); }
"for"               { return setValue(line, FOR, yytext); }
"to"                { return setValue(line, TO , yytext); }
"do"                { return setValue(line, DO , yytext); }
"while"             { return setValue(line, WHILE, yytext); }
"and"               { return setValue(line, AND, yytext); }
"or"                { return setValue(line, OR , yytext); }
"not"               { return setValue(line, NOT, yytext); }
"by"                { return setValue(line, BY , yytext); }
"static"            { return setValue(line, STATIC, yytext); }
"return"            { return setValue(line, RETURN, yytext); }
"break"             { return setValue(line, BREAK, yytext); }
"int"               { return setValue(line, INT, yytext); }
{digit}+            { return setValue(line, NUMCONST, yytext); }
"char"              { return setValue(line, CHAR, yytext); }
"true"|"false"      { return setValue(line, BOOLCONST, yytext); }
"bool"              { return setValue(line, BOOL, yytext); }
{letter}{letdig}*   { return setValue(line, ID , yytext); }
{op}		        { return setValue(line, yytext[0], yytext); }
{stringconst}       { return setValue(line, STRINGCONST, yytext);  }
{charconst2}        { return setValue(line, CHARCONST, yytext); }
{charconst3}        { return setValue(line, CHARCONST, yytext); }
{comment}               ; 
\n                  { line++ ; }
{whitespace}+           ;
.                   {printf("TOKEN ERROR(%d): invalid or misplaced input character: \'%c\' Character Ignored.\n", line, yytext[0]); numErrors++;}

