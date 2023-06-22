#include <string.h>
#include "treeUtils.h"
#include "treeNodes.h"


extern void yyerror(const char *msg);
static int nodeNum = 0;

 // trying some pointers
 FILE *listing;
 //TreeNode *syntaxTree;
 //syntaxTree = new TreeNode;
 // end trying


 // lots of these save the TokenData block so line number and yytext are saved
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


  // from tiny compiler
 /* Variable indentno is used by printTree to
  * store current number of spaces to indent
  */
static int indentno = 0; 

 /* macros to increase/decrease indentation */
#define INDENT indentno+=2
#define UNINDENT indentno-=2

 /* printSpaces indents by printing spaces */
static void printSpaces(void)
{ int i;
  for (i=0;i<indentno;i++)
    fprintf(listing, ". ");
}
 // end from tiny compiler

 
void printTree(FILE *out, TreeNode *syntaxTree, bool showExpType, bool showAllocation) {
  int i;
  //INDENT;
  while (syntaxTree != NULL) {
    // printSpaces();
    if (syntaxTree->type) {
        printTreeNode(out, syntaxTree, true, false);
        if (syntaxTree->type && syntaxTree->isArray)
            printTreeNode(out, syntaxTree, true, true);
    }
    else if (syntaxTree->isArray)
        printTreeNode(out, syntaxTree, false, true);

    else
        printTreeNode(out, syntaxTree, false, false);


    for (i=0;i<MAXCHILDREN;i++) {
      printTree(out, syntaxTree->child[i], false, false);
    }
    syntaxTree = syntaxTree->sibling;
    //printTree(out, syntaxTree,false,false);
    //UNINDENT;
  }
}


 // char *tokenToStr(int type){ return (char*)""; }


char *varKindToStr(int kind)
{
    switch (kind) {
    case None:
        return (char *)"None";
    case Local:
        return (char *)"Local";
    case Global:
        return (char *)"Global";
    case Parameter:
        return (char *)"Parameter";
    case LocalStatic:
        return (char *)"LocalStatic";
    default:
   return (char *)"unknownVarKind";
    }
}

  // allocate a FIX BUFFER.  You must copy the string if you
 // are referencing the function twice in the same printf for example.
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
    sprintf(expTypeToStrBuffer, "%s%s%s", (isStatic ? "static " : ""), (isArray ? "array of " : ""), typeName);

    return strdup(expTypeToStrBuffer); // memory leak
}

 // don't have: "Sibling" "Child" "chsign" "variable" 

// print a node without a newline
void printTreeNode(FILE *listing, TreeNode *tree, bool showExpType, bool showAllocation)
{
    //while (tree != NULL) {
        //int i;
   // print a declaration node
    if (tree->nodekind == DeclK) {
   switch (tree->kind.decl) {
   case VarK:
            printf("Var: %s ", tree->attr.name);
            printf("of %s", expTypeToStr(tree->type, tree->isArray, tree->isStatic));
            if (showAllocation) {
                printf(" [mem: %s loc: %d size: %d]", varKindToStr(tree->varKind), tree->offset, tree->size);
            }
       break;
   case FuncK:
            printf("Func: %s ", tree->attr.name);
            printf("returns %s", expTypeToStr(tree->type, tree->isArray, tree->isStatic));
            if (showAllocation) {
                printf(" [mem: %s loc: %d size: %d]", varKindToStr(tree->varKind), tree->offset, tree->size);
            }
       break;
   case ParamK:
            printf("Parm: %s ", tree->attr.name);
            printf("of %s", expTypeToStr(tree->type, tree->isArray, tree->isStatic));
            if (showAllocation) {
                printf(" [mem: %s loc: %d size: %d]", varKindToStr(tree->varKind), tree->offset, tree->size);
            }
       break;
   default:
       fprintf(listing, "Unknown declaration node kind: %d",
          tree->kind.decl);
       break;
   }
    }

    // print a statement node
    else if (tree->nodekind == StmtK) {
   switch (tree->kind.stmt) {
   case IfK:
       fprintf(listing, "If");
       break;
   case WhileK:
       fprintf(listing, "While");
       break;
   case CompoundK:
       fprintf(listing, "Compound");
            if (showAllocation) {
                printf(" [mem: %s loc: %d size: %d]", varKindToStr(tree->varKind), tree->offset, tree->size);
            }
       break;
        case ForK:
       fprintf(listing, "For");
            if (showAllocation) {
                printf(" [mem: %s loc: %d size: %d]", varKindToStr(tree->varKind), tree->offset, tree->size);
            }
       break;
        case RangeK:
       fprintf(listing, "Range");
       break;
   case ReturnK:
       fprintf(listing, "Return");
       break;
   case BreakK:
       fprintf(listing, "Break");
       break;
   default:
       fprintf(listing, "Unknown  statement node kind: %d",
          tree->kind.stmt);
       break;
   }
    }

    // print an expression node
    else if (tree->nodekind == ExpK) {

   switch (tree->kind.exp) {
   case AssignK:
       fprintf(listing, "Assign: %s", tokenToStr(tree->attr.op));
       break;
   case OpK:
       fprintf(listing, "Op: %s", tokenToStr(tree->attr.op));
       break;
   case ConstantK:
            switch (tree->type) {
            case Boolean:
      fprintf(listing, "Const %s", (tree->attr.value) ?  "true" : "false");
                break;
            case Integer:
      fprintf(listing, "Const %d", tree->attr.value);
                break;
            case Char:
                if (tree->isArray) {
                    fprintf(listing, "Const ");
                    printf("\"");
                    for (int i=0; i<tree->size-1; i++) {
                        printf("%c", tree->attr.string[i]);
                    }
                    printf("\"");
                }
      else fprintf(listing, "Const '%c'", tree->attr.cvalue);
                break;
            case Void:
            case UndefinedType:
                fprintf(listing, "SYSTEM ERROR: parse tree contains invalid type for constant: %s\n", expTypeToStr(tree->type, tree->isArray, tree->isStatic));
       }
       break;
   case IdK:
       fprintf(listing, "Id: %s", tree->attr.name);
       break;
   case CallK:
       fprintf(listing, "Call: %s", tree->attr.name);
       break;
   default:
       fprintf(listing, "Unknown expression node kind: %d", tree->kind.exp);
       break;
   }
   if (showExpType) {
       fprintf(listing, " of %s", expTypeToStr(tree->type, tree->isArray, tree->isStatic));
   }
        if (showAllocation) {
            if (tree->kind.exp == IdK || tree->kind.exp == ConstantK && tree->type == Char && tree->isArray) {
                printf(" [mem: %s loc: %d size: %d]", varKindToStr(tree->varKind), tree->offset, tree->size);
            }
        }
    }
    else fprintf(listing, "Unknown class of node: %d",
       tree->nodekind);

    fprintf(listing, " [line: %d]", tree->lineno);

    // for (i=0;i<MAXCHILDREN;i++) {
    //   printTree(listing, tree->child[i], false, false);
    // }

    //tree = tree->sibling;
    //}
}
