#include <string.h>
#include "treeUtils.h"
#include "treeNodes.h"


extern void yyerror(const char *msg);
static int nodeNum = 0;

 FILE *listing;


TreeNode *cloneNode(TreeNode *currnode){ return currnode;}
TreeNode *newDeclNode(DeclKind kind, ExpType type, TokenData *token, TreeNode *c0, TreeNode *c1, TreeNode *c2) {
  int i;
  TreeNode *newNode;
  newNode = new TreeNode;
  newNode->nodeNum = nodeNum++; 

  if (newNode == NULL) {
    yyerror("is NULL");
  } 
  else {
    newNode->child[0] = c0;
    newNode->child[0] = c1;
    newNode->child[0] = c2;

    newNode->sibling = NULL;
    newNode->lineno = (token ? token->linenum: -1);
    newNode->attr.name = (token ? token->svalue : strdup("DUMPSTRING"));
    newNode->type = type;
    newNode->size = 1;
    newNode->varKind = Local;
    newNode->offset = 0;
    newNode->isArray = false;
    newNode->isStatic = false;
    newNode->isConst = false;

    newNode->nodekind = DeclK;
    newNode->kind.decl = kind;

  }

    return newNode;
}  // save TokenData block!!

TreeNode *newStmtNode(StmtKind kind, TokenData *token, TreeNode *c0, TreeNode *c1, TreeNode *c2) {
                        
  int i;
  TreeNode *newNode;
  newNode = new TreeNode;
  newNode->nodeNum = nodeNum++; 

  if (newNode == NULL) {
    yyerror("is NULL");
  } 
  else {
    newNode->child[0] = c0;
    newNode->child[0] = c1;
    newNode->child[0] = c2;

    newNode->sibling = NULL;
    newNode->lineno = (token ? token->linenum: -1);
    newNode->attr.name = (token ? token->svalue : strdup("DUMPSTRING"));
    //newNode->type = type;
    newNode->size = 1;
    newNode->varKind = Local;
    newNode->offset = 0;
    newNode->isArray = false;
    newNode->isStatic = false;
    newNode->isConst = false;

    newNode->nodekind = StmtK;
    newNode->kind.stmt = kind;

  }

    return newNode;}

TreeNode *newExpNode(ExpKind kind, TokenData *token, TreeNode *c0, TreeNode *c1, TreeNode *c2) {

  int i;
  TreeNode *newNode;
  newNode = new TreeNode;
  newNode->nodeNum = nodeNum++; 

  if (newNode == NULL) {
    yyerror("is NULL");
  } 
  else {
    newNode->child[0] = c0;
    newNode->child[0] = c1;
    newNode->child[0] = c2;

    newNode->sibling = NULL;
    newNode->lineno = (token ? token->linenum: -1);
    newNode->attr.name = (token ? token->svalue : strdup("DUMPSTRING"));
    //newNode->type = type;
    newNode->size = 1;
    newNode->varKind = Local;
    newNode->offset = 0;
    newNode->isArray = false;
    newNode->isStatic = false;
    newNode->isConst = false;

    newNode->nodekind = ExpK;
    newNode->kind.exp = kind;

  }

    return newNode; 
}

 /* printSpaces indents by printing spaces */
void printSpaces(FILE *out, int depth) {
    for (int i=0; i < depth; i++)
        fprintf(out, ".   ");
}

void printFullTree(FILE *out, TreeNode *syntaxTree, bool showExpType, bool showAllocation, int depth, int sibCount) {

    int childCount;

    if (syntaxTree != NULL) {
        printTreeNode(out, syntaxTree, showExpType, showAllocation);
        fprintf(out, "\n");
    }
   for (childCount = 0; childCount < MAXCHILDREN; childCount++) {
        if (syntaxTree->child[childCount]) {
            printSpaces(out, depth);
            fprintf(out, "Child: %d  ", childCount);
            printFullTree(out, syntaxTree->child[childCount], showExpType, showAllocation, depth+1, 1);
        }
    }

    syntaxTree = syntaxTree->sibling;

    if (syntaxTree != NULL) {
        if (depth) {
            printSpaces(out, depth-1);
            fprintf(out, "Sibling: %d  ", sibCount);
        }
        printFullTree(out, syntaxTree, showExpType, showAllocation, depth, sibCount+1);
    }
    fflush(out);

}

void printTree(FILE *out, TreeNode *syntaxTree, bool showExpType, bool showAllocation) {
  printFullTree(out, syntaxTree, showExpType, showAllocation,1,1);
}

 
