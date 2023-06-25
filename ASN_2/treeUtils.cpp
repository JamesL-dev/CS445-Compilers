#include <string.h>
#include "treeUtils.h"
#include "treeNodes.h"

extern void yyerror(const char *msg);
static int nodeNum = 0;

FILE *listing;
char expTypeToStrBuffer[80];
char *expTypeToStr(ExpType type, bool isArray, bool isStatic)
{
    char *typeName;

    switch (type) {
    case Void:
       typeName = (char *)"type void";
       break;
    case Integer:
       typeName = (char *)"type int";
       break;
    case Boolean:
       typeName = (char *)"type bool";
       break;
    case Char:
       typeName = (char *)"type char";
       break;
    case UndefinedType:
       typeName = (char *)"undefined type";
       break;
    default:
       char *buffer;
       buffer = new char [80];
       sprintf(buffer, "invalid expType: %d", (int)type);
       return buffer;
    }

    // add static and array attributes
    // static type int
    // static array of type int
    sprintf(expTypeToStrBuffer, "%s%s%s",
            (isStatic ? "static " : ""),
            (isArray ? "array of " : ""),
            typeName);

    return strdup(expTypeToStrBuffer); // memory leak
}

TreeNode *newDeclNode(DeclKind kind, ExpType type, TokenData *token, TreeNode *c0, TreeNode *c1, TreeNode *c2)
{
   TreeNode *newNode;
   int i;

   newNode = new TreeNode;
   newNode->nodeNum = nodeNum++;

   if (newNode == NULL) {
      yyerror("ERROR: Out of memory");
   }
   else {
      // set the defaults for a general node
      newNode->child[0] = c0;
      newNode->child[1] = c1;
      newNode->child[2] = c2;
      newNode->sibling = NULL;
      newNode->lineno = (token ? token->linenum : -1);
      newNode->attr.name = (token ? token->svalue : strdup("DUMMY"));    // NOTE: just copies pointer
      newNode->type = type;
// set default values for inferred parts
      newNode->size = 1;
      newNode->varKind = Local;
      newNode->offset = 0;
      newNode->isArray = false;
      newNode->isStatic = false;
      newNode->isConst = false;

      // set the defaults for this class of nodes
      newNode->nodekind = DeclK;
      newNode->kind.decl = kind;
   }
   return newNode;
}

// basic statement node defaults
TreeNode *newStmtNode(StmtKind kind, TokenData *token, TreeNode *c0, TreeNode *c1, TreeNode *c2)
{
   TreeNode *newNode;
   int i;

   newNode = new TreeNode;
   newNode->nodeNum = nodeNum++;

   if (newNode == NULL) {
   yyerror("ERROR: Out of memory");
    }
    else {
      // set the defaults for a general node
      newNode->child[0] = c0;
      newNode->child[1] = c1;
      newNode->child[2] = c2;
      newNode->sibling = NULL;
      newNode->lineno = token->linenum;
// set default just to be sure (should not be needed except varKind)
      newNode->varKind = None;
      newNode->size = 1;
      newNode->offset = 0;
      newNode->isArray = false;
      newNode->isStatic = false;
      newNode->isConst = false;

      // set the defaults for this class of nodes
      newNode->nodekind = StmtK;
      newNode->kind.stmt = kind;
   }
   return newNode;
}

// this node is concerned also with operator and expression type
TreeNode *newExpNode(ExpKind kind, TokenData *token, TreeNode *c0, TreeNode *c1, TreeNode *c2)
{
   TreeNode *newNode;
   int i;

   newNode = new TreeNode;
   newNode->nodeNum = nodeNum++;

   if (newNode == NULL) {
      yyerror("ERROR: Out of memory");
   }
   else {
//////////////////
//printf("%c %d\n", token->tokenclass, token->tokenclass);
      // set the defaults for a general node
      newNode->child[0] = c0;
      newNode->child[1] = c1;
      newNode->child[2] = c2;
      newNode->sibling = NULL;
      newNode->lineno = token->linenum;
      newNode->attr.op = OpKind(token->tokenclass);
      newNode->type = UndefinedType;
// set default just to be sure
      newNode->size = 1;
      newNode->varKind = Local;
      newNode->offset = 0;
      newNode->isArray = false;
      newNode->isStatic = false;
      newNode->isConst = false;

      // set the defaults for this class of nodes
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
