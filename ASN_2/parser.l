%{
#include "scanType.h"
#include "parser.tab.h"

using namespace std;

#define YY_DECL extern "C" int yylex()
#define YYSTYPE int

int line=1;
int errorCount;

int setValue(int linenum, int tokenClass, char *svalue) {
    yylval.tinfo.tokenclass = tokenClass;
    yylval.tinfo.linenum = linenum;
    yylval.tinfo.tokenstr = strdup(svalue);
    yylval.tinfo.cvalue = '@';
    yylval.tinfo.nvalue = 777;
    yylval.tinfo.svalue = NULL;
    return tokenClass;
}

%}

%option noyywrap
letter      [a-zA-Z]
digit    [0-9]
quote    [\']
underbar [_]
letdig      {digit}|{letter}|{underbar}
limitters   [\;\,\(\)\{\}\[\]]
op    [\-\+\*\/\%]
whitespace  [\ \t]
%%

^"#DRBC ".*                   { return setValue(line, PRECOMPILER, yytext); }
^"#DRBCRUN ".*                { return setValue(line, PRECOMPILER2, yytext); }

[] { return setValue(line, yytext[0], yytext); }// put all single char operators here and the limiters

"int"                         { return setValue(line, INT, yytext); }
"bool"                        { return setValue(line, BOOL, yytext);}
"char"                        { return setValue(line, CHAR, yytext);}
"static"                      { return setValue(line, STATIC, yytext); }

"if"                          { return setValue(line, IF, yytext); }
"then"                        { return setValue(line, THEN, yytext); }
"else"                        { return setValue(line, ELSE, yytext); }
"while"                       { return setValue(line, WHILE, yytext); }
"for"                         { return setValue(line, FOR, yytext); }
"to"                          { return setValue(line, TO, yytext); }
"by"                          { return setValue(line, BY, yytext); }
"do"                          { return setValue(line, DO, yytext); }

"return"                      { return setValue(line, RETURN, yytext); }
"break"                       { return setValue(line, BREAK, yytext); }

"{"                           { return setValue(line, LCURLY, yytext); }
"}"                           { return setValue(line, RCURLY, yytext); }
"("                           { return setValue(line, LPAREN, yytext); }
")"                           { return setValue(line, RPAREN, yytext); }
"["                           { return setValue(line, LBRACK, yytext); }
"]"                           { return setValue(line, RBRACK, yytext); }

"and"                         { return setValue(line, AND, yytext); }
"or"                          { return setValue(line, OR, yytext); }
"not"                         { return setValue(line, NOT, yytext); }

"*"                           { return setValue(line, MUL, yytext); }
"/"                           { return setValue(line, DIV, yytext); }
"%"                           { return setValue(line, MOD, yytext); }
"+"                           { return setValue(line, ADD, yytext); }
"-"                           { return setValue(line, SUB, yytext); }
"++"                          { return setValue(line, INC, yytext); }
"--"                          { return setValue(line, DEC, yytext); }

"+="                          { return setValue(line, ADDASS, yytext); }
"-="                          { return setValue(line, SUBASS, yytext); }
"*="                          { return setValue(line, MULASS, yytext); }
"/="                          { return setValue(line, DIVASS, yytext); }
"="                           { return setValue(line, ASS, yytext); }

":<:"                         { return setValue(line, MIN, yytext); }
":>:"                         { return setValue(line, MAX, yytext); }

"=="                          { return setValue(line, EQ, yytext); }
"!="                          { return setValue(line, NEQ, yytext); }
"<"                           { return setValue(line, LT, yytext); }
"<="                          { return setValue(line, LEQ, yytext); }
">"                           { return setValue(line, GT, yytext); }
">="                          { return setValue(line, GEQ, yytext); }

";"                           { return setValue(line, SEMICOLON, yytext); }
":"                           { return setValue(line, COLON, yytext); }
","                           { return setValue(line, COMMA, yytext); }
"?"                           { return setValue(line, QUESTION, yytext); }

"true"|"false"                { return setValue(line, BOOLCONST, yytext); }

[a-zA-Z][a-zA-Z0-9]*          { return setValue(line, ID, yytext); }
[0-9]+                        { return setValue(line, NUMCONST, yytext); }
\"((\\\")|([^\n\"]))*\"       { return setValue(line, STRINGCONST, yytext); }
\'..?\'                       { return setValue(line, CHARCONST, yytext); }

"\n"                          { line++; }
[ \t]                         { }
\/\/.*\n                      { line++; }

.                             { yylval.tinfo.tokenstr = yytext; return ERROR; }
%%
