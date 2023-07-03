#ifndef _SCANTYPE_H_
#define _SCANTYPE_H_
//
//  SCANNER TOKENDATA
//

struct TokenData
{
    int  tokenclass;        // token class
    int  linenum;           // line where found
    char *tokenstr;         // what string was read (pointer)
    char cvalue;            // any character value
    int  nvalue;            // any numeric value or Boolean value
    char *svalue;           // any string value e.g. an id (pointer)

};
#endif
