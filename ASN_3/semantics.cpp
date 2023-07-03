#include "treeNodes.h"
#include "semantics.h"
#include "treeUtils.h"
#include "scanType.h"
#include "parser.tab.h"

// some globals
extern int numErrors;
extern int numWarnings;
extern bool printErrors;
extern bool printWarnings;


// SPECIAL OPTIONS
static bool noDuplicateUndefs;
static bool shareCompoundSpace;

// expression types
static ExpectType expectType[LASTOP];
static ReturnType returnType[LASTOP];

// memory offsets are GLOBAL
static int goffset;                   // top of global space
static int foffset;                   // top of local space

// Helper function prototypes
bool insertErr(TreeNode *current);
void treeTraverse(TreeNode *current, SymbolTable *symtab);

// helper functions prototypes
// bool insertErr(TreeNode * current);
// void treeTraverse(TreeNode * current, SymbolTable * symtab);


void printErrorSystem(char *err) {  }

void traverseDeclK(TreeNode *current, SymbolTable *symtab) {
    char *id = strdup(current->attr.name);

    static int varCounter = 0;

    switch (current->kind.decl) {
        case VarK: // no break on purpose
        case ParamK: //check for errors later
            symtab->insert(id, (void*)current);
            if (symtab->depth() == 1) {
                current->varKind = Global;
                current->offset = goffset;
                goffset -= current->size;
            } else if (current->isStatic) {
                current->varKind = LocalStatic;
                current->offset = goffset;
                goffset -= current->size;

                { 
                    char * newName;
                    newName = new char[strlen(id) + 10];
                    sprintf(newName, "%s-%d", id, ++varCounter);
                    symtab->insertGlobal(newName, current);
                    delete [] newName;
                }
            } else {
                current->varKind = Local;
                current->offset = foffset;
                foffset -= current->size;
            }

            if (current->kind.decl == ParamK) {
                current->varKind = Parameter; 
            } else if (current->isArray) {
                current->offset--;
            }

            break;
            
        case FuncK:

            symtab->insertGlobal(id, (void*)current);
            current->varKind = Global;
            current->size = foffset;


            break;
        

            // if (!(symtab->lookup(current->attr.name))) {
            //     if (symtab->insert(current->attr.name, (char *)"var")) printf("success\n"); else  printf("FAIL\n"); 
            //     symtab->insert(current->child[0]->attr.name, (char *)"id");
            // } else {
            //     printf("already used error");
            // }           
            // break;
    }

    
}

void traverseStmtK(TreeNode *current, SymbolTable *symtab) {

    switch(current->kind.stmt) {

        case CompoundK:
            current->size = foffset;
            // symtab->enter((char *)"compoundstmt");
            // treeTraverse(current->child[0], symtab); // process declarations
            // // more stuff
            // current->size = foffset;
            // treeTraverse(current->child[1], symtab);
            
            // symtab->leave(); 
            break;
    }

    

    
}

void traverseExpK(TreeNode *current, SymbolTable *symtab) {
// printf("in exp\n"); //////////////////////////////////////////////////////

    switch (current->kind.exp) {

        case AssignK: // no break here
        case OpK:
            switch (returnType[current->attr.op]) {
                case RetInt:
                    current->type = Integer;
                    //printf("print an int type here?");
                    break;
                case RetBool:
                    current->type = Boolean;
                    break;
                case RetLHS:
                    current->type = current->child[0]->type;
                    if (current->attr.op == int('=')) current->isArray = current->child[0]->isArray;
                    break;
            }
            break;
        case IdK: // nop break on purpose
            // if (!(symtab->lookup(current->attr.name))) {
            //     if (symtab->insert(current->attr.name, (char *)"id")) printf("success\n"); else  printf("FAIL\n"); 
            // } else {
            //     printf("already used error");
            // } 
            // break;
        case CallK:

            {
                char * id = strdup(current->attr.name);
                TreeNode *temp =(TreeNode*)symtab->lookup(id);
                if (temp == NULL) {
                    printf("probbaly a segfault\n");
                } 
                current->type = temp->type;
                current->isArray = temp->isArray;
                current->isStatic = temp->isStatic;
                current->size = temp->size;
                current->varKind = temp->varKind;
                current->offset = temp->offset;

            }
            // if (!(symtab->lookup(current->attr.name))) {
            //     if (symtab->insert(current->attr.name, (char *)"call")) printf("success\n"); else  printf("FAIL\n"); 
            // } else {
            //     printf("already used error");
            // } 
            break;
        case ConstantK:
            current->isConst = true;

            // check for string constant (if being stored in global area)
            if (current->type == Char && current->isArray) {
                current->varKind = Global;
                current->offset = goffset - 1;
                goffset -= current->size;
            }
            break;
    }
    
}

bool isNodeCompound(TreeNode *current) {
    if (current == NULL) {
        return false;
    }

    if (current->nodekind == DeclK && current->kind.decl == FuncK) {
        foffset = -2; 
        return true;
    }
    if (current->nodekind == StmtK) {
        if (current->kind.stmt == CompoundK || current->kind.stmt == ForK) {
            return true;
        }
    }
    return false;
}

void treeTraverse(TreeNode *current, SymbolTable *symtab) {

    if (current == NULL) return;
    // check for compound
    bool isCompound = isNodeCompound(current);
    if (isCompound) {
        char *id = strdup("{");
        symtab->enter("new scope from " + (std::string)id);
    }
    // all child descents happen here
    // save current foffset
    int tempOffset = foffset;

    treeTraverse(current->child[0], symtab);
    switch (current->nodekind) {
        case ExpK:          // putting this first for the moment -> still not being reached /////////////////////
        // printf("in treeTrav --> expression\n"); //////////////////////////////////////////////////////
            traverseExpK(current, symtab);
            break;
        case DeclK:
        // printf("in treeTrav --> declaration\n"); //////////////////////////////////////////////////////
            traverseDeclK(current, symtab);
            break;
        case StmtK:
        // printf("in treeTrav --> statement\n"); //////////////////////////////////////////////////////
            traverseStmtK(current, symtab);
            break;
        
        default:
            printErrorSystem((char *)"Unknown nodeKind");
            break;
    }
    if (current->nodekind == StmtK && current->kind.stmt == ForK) {
        foffset -= 2; // has the variables within itself
    }
    treeTraverse(current->child[1], symtab);
    treeTraverse(current->child[2], symtab);


    if (current->nodekind == StmtK && current->kind.stmt == CompoundK) {
        current->size = foffset;
        foffset = tempOffset;
    }
    if (current->nodekind == StmtK && current->kind.stmt == ForK) {
        current->size = foffset;
    }

    if (isCompound) {
        symtab->leave();
    }

    // traverse your siblings
    treeTraverse(current->sibling, symtab); // already checked for NULL

    if (current->nodekind == StmtK && current->kind.stmt == ForK) {
        foffset = tempOffset;
    }

    return;
}


TreeNode *loadIOLib(TreeNode *syntree) {
    TreeNode *input, *output, *param_output;
    TreeNode *inputb, *outputb, *param_outputb;
    TreeNode *inputc, *outputc, *param_outputc;
    TreeNode *outnl;

    input = newDeclNode(FuncK, Integer);
    input->lineno = -1; // all are -1
    input->attr.name = strdup("input"); //We named the variables well
    input->type = Integer;

    inputb = newDeclNode(FuncK, Boolean);
    inputb->lineno = -1; // all are -1
    inputb->attr.name = strdup("inputb"); //We named the variables well
    inputb->type = Boolean;
    
    inputc = newDeclNode(FuncK, Boolean);
    inputc->lineno = -1; // all are -1
    inputc->attr.name = strdup("inputc"); //We named the variables well
    inputc->type = Char;
    
    param_output = newDeclNode(ParamK, Void);
    param_output->lineno = -1; // all are -1
    param_output->attr.name = strdup("*dummy*"); //We named the variables well
    param_output->type = Integer;
    
    output = newDeclNode(FuncK, Void);
    output->lineno = -1; // all are -1
    output->attr.name = strdup("output"); //We named the variables well
    output->type = Void;
    output->child[0] = param_output;

    param_outputb = newDeclNode(ParamK, Void);
    param_outputb->lineno = -1; // all are -1
    param_outputb->attr.name = strdup("*dummy*"); //We named the variables well
    param_outputb->type = Boolean;

    outputb = newDeclNode(FuncK, Void);
    outputb->lineno = -1; // all are -1
    outputb->attr.name = strdup("outputb"); //We named the variables well
    outputb->type = Void;
    outputb->child[0] = param_outputb;

    param_outputc = newDeclNode(ParamK, Void);
    param_outputc->lineno = -1; // all are -1
    param_outputc->attr.name = strdup("*dummy*"); //We named the variables well
    param_outputc->type = Char;

    outputc = newDeclNode(FuncK, Void);
    outputc->lineno = -1; // all are -1
    outputc->attr.name = strdup("outputc"); //We named the variables well
    outputc->type = Void;
    outputc->child[0] = param_outputc;

    outnl = newDeclNode(FuncK, Void);
    outnl->lineno = -1; // all are -1
    outnl->attr.name = strdup("outnl"); //We named the variables well
    outnl->type = Void;
    outnl->child[0] = NULL;


    //////// Stuff from next slides
    // link them and prefix the tree we are interested in traversing.
    // This will put the symbols in the symbol table.
    input->sibling = output;
    output->sibling = inputb;
    inputb->sibling = outputb;
    outputb->sibling = inputc;
    inputc->sibling = outputc;
    outputc->sibling = outnl;
    outnl->sibling = syntree; // add in the tree we were given

    return input;

} 


static bool newScope = true;
static int loopCount = 0;
static int varCounter = 0;
static bool isAssignedErrOk = true;
static bool isUsedErrOk = true;
//static int goffset = 0;

TreeNode *semanticAnalysis(TreeNode *syntree, // pass in and return an annotated syntax tree
                            bool shareCompoundSpaceIn, // SPECIAL OPTION: make compound after a function share scope
                            bool noDuplicateUndefsIn, // SPECIAL OPTION: no duplicate undefines
                            SymbolTable *symtab, // pass in and return the symbol table
                            int &globalOffset // return the offset past the globals
                            )
{
    noDuplicateUndefs = noDuplicateUndefsIn;
    shareCompoundSpace = shareCompoundSpaceIn;

    newScope = true;
    loopCount = 0;
    varCounter = 0;
    isAssignedErrOk = true;
    isUsedErrOk = true;
    goffset = 0;

    // OPERAND TYPES
    // Binary Ops
    for (int i=0; i<LASTOP; i++) expectType[i] = IntInt; // everything is IntInt
    // except the following:
    expectType[AND] = BoolBool;
    expectType[OR] = BoolBool;
    expectType[EQ] = Equal;
    expectType[NEQ] = Equal;
    expectType[LEQ] = Equal;
    expectType[int('<')] = Equal;
    expectType[GEQ] = Equal;
    expectType[int('>')] = Equal;
    expectType[int('=')] = Equal;
    expectType[int('[')] = ArrayInt;
    // Unary Ops
    expectType[NOT] = OneBool;
    expectType[int('?')] = OneInt;
    expectType[SIZEOF] = OneArray;
    expectType[CHSIGN] = OneInt;
    expectType[DEC] = OneInt;
    expectType[INC] = OneInt;
    // OPERATOR VALUES
    // Binary Ops
    for (int i=0; i<LASTOP; i++) returnType[i] = RetInt;
    returnType[AND] = RetBool;
    returnType[OR] = RetBool;
    returnType[EQ] = RetBool;
    returnType[NEQ] = RetBool;
    returnType[LEQ] = RetBool;
    returnType[int('<')] = RetBool;
    returnType[GEQ] = RetBool;
    returnType[int('>')] = RetBool;
    returnType[int('=')] = RetLHS;
    returnType[int('[')] = RetLHS;
    // Unary Ops
    returnType[NOT] = RetBool;

    // Anything else you might want to do.

    syntree = loadIOLib(syntree);
    // traverse the tree doing sematic analysis
    treeTraverse(syntree, symtab); 

    // remember where the globals are
    globalOffset = goffset;

    // More stuff
    return syntree;

}


