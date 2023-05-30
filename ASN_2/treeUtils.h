#ifndef _UTIL_H_
#define _UTIL_H_
#include "treeNodes.h"
#include "scanType.h"
#include <string.h>

// lots of these save the TokenData block so line number and yytext are saved
TreeNode *cloneNode(TreeNode *currnode);
TreeNode *newDeclNode(DeclKind kind,
                      ExpType type,
                      TokenData *token=NULL,
                      TreeNode *c0=NULL,
                      TreeNode *c1=NULL,
                      TreeNode *c2=NULL);  // save TokenData block!!
TreeNode *newStmtNode(StmtKind kind,
                      TokenData *token,
                      TreeNode *c0=NULL,
                      TreeNode *c1=NULL,
                      TreeNode *c2=NULL);
TreeNode *newExpNode(ExpKind kind,
                     TokenData *token,
                     TreeNode *c0=NULL,
                     TreeNode *c1=NULL,
                     TreeNode *c2=NULL);
char *tokenToStr(int type);
char *expTypeToStr(ExpType type, bool isArray=false, bool isStatic=false);

void printTreeNode(FILE *out, TreeNode *syntaxTree, bool showExpType, bool showAllocation);
void printTree(FILE *out, TreeNode *syntaxTree, bool showExpType, bool showAllocation);

#endif
