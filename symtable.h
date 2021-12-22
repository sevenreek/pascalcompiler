#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
struct entry
{
  char *lexptr;
  int token;
};
extern struct entry symtable[];
int insert (char s[], int tok);
int lookup (char s[]) ;
