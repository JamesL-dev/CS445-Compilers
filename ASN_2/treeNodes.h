#ifndef _TREENODES_H_
#define _TREENODES_H_
#include <stdio.h>

// 
//  SYNTAX TREE NODE TYPES FILE 
//   used by treeUtils
// 

// the exact type of the token or node involved.  These are divided into
// various "kinds" in the enums that follow

// Kinds of Operators
// these are the token numbers for the operators same as in flex
typedef int OpKind;  

// Kinds of Statements
//typedef enum {DeclK, StmtK, ExpK} NodeKind;
enum NodeKind {DeclK, StmtK, ExpK};

// Subkinds of Declarations
enum DeclKind {VarK, FuncK, ParamK};

// Subkinds of Statements
enum  StmtKind {IfK, WhileK, ForK, CompoundK, ReturnK, BreakK, RangeK};

// Subkinds of Expressions
enum ExpKind {AssignK, CallK, ConstantK, IdK, OpK};

// =====

// Type of variables
enum ExpType {Void, Integer, Boolean, Char, UndefinedType};

// expected types for operator: 3 unary + 4 binary
enum ExpectType {OneInt, OneBool, OneArray, IntInt, BoolBool, Equal, ArrayInt};

// expected return types for operator
enum ReturnType {RetInt, RetBool, RetLHS};

// =====

// What kind of scoping is used?  (decided during typing)
enum VarKind {None, Local, Global, Parameter, LocalStatic};

#define MAXCHILDREN 3                      // no more than 3 children allowed

struct TreeNode
{
    // connectivity in the tree
    struct TreeNode *child[MAXCHILDREN];   // children of the node
    struct TreeNode *sibling;              // siblings for the node
    int nodeNum;                           // unique node number for DOT PLOTS

    // what kind of node
    int lineno;                            // linenum relevant to this node
    NodeKind nodekind;                     // type of node
    struct                                  // subtype of type
    {
      DeclKind decl;                     // used when DeclK
      StmtKind stmt;                     // used when StmtK
      ExpKind exp;                       // used when ExpK
    } kind;
    
    // extra properties about the node depending on type of the node
    struct                                  // relevant data to type -> attr
    {
      OpKind op;                         // type of token (same as in bison)
      int value;                         // used when ConstantK: int or bool
      char cvalue;                       // used with ConstantK: char
      char *name;                        // used when IdK as name of variable
      char *string;                      // used when ConstantK: string
    } attr;                                 
    ExpType type;		           // used when ExpK for type checking
    bool isStatic;                         // is staticly allocated?
    bool isArray;                          // is this an array?
    bool isConst;                          // can be computed at compile time?
    bool isUsed;                           // is this variable used?
    bool isAssigned;                       // has the variable been given a value?

    // extra stuff inferred about the node
    VarKind varKind;                       // global, local, localStatic, parameter
    int offset;                            // offset for address of object
    int size;                              // used for size of array
};
#endif
