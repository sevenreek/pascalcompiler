/* A Bison parser, made by GNU Bison 3.5.1.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2020 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

#ifndef YY_YY_PARSER_HPP_INCLUDED
# define YY_YY_PARSER_HPP_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif
/* "%code requires" blocks.  */
#line 3 "parser.y"

    #include "symboltable.hpp"
    #include "emitter.hpp"
    #include <exception>
    #include <string>
    #include <fmt/format.h>

#line 56 "parser.hpp"

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    TOK_PROGRAM = 258,
    TOK_ID = 259,
    TOK_VAR = 260,
    TOK_ARRAY = 261,
    TOK_OF = 262,
    TOK_NUM = 263,
    TOK_INTEGER = 264,
    TOK_REAL = 265,
    TOK_FUNCTION = 266,
    TOK_PROCEDURE = 267,
    TOK_BEGIN = 268,
    TOK_END = 269,
    TOK_ASSIGNOP = 270,
    TOK_IF = 271,
    TOK_THEN = 272,
    TOK_ELSE = 273,
    TOK_WHILE = 274,
    TOK_DO = 275,
    TOK_NOT = 276,
    TOK_OR = 277,
    TOK_AND = 278,
    TOK_LE = 279,
    TOK_GE = 280,
    TOK_NEQ = 281,
    TOK_DIV = 282,
    TOK_MOD = 283,
    TOK_EQ = 284,
    TOK_WRITE = 285
  };
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef address_t YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif

/* Location type.  */
#if ! defined YYLTYPE && ! defined YYLTYPE_IS_DECLARED
typedef struct YYLTYPE YYLTYPE;
struct YYLTYPE
{
  int first_line;
  int first_column;
  int last_line;
  int last_column;
};
# define YYLTYPE_IS_DECLARED 1
# define YYLTYPE_IS_TRIVIAL 1
#endif


extern YYSTYPE yylval;
extern YYLTYPE yylloc;
int yyparse (void);
/* "%code provides" blocks.  */
#line 11 "parser.y"

    const static size_t NO_SYMBOL = -1;
    void yyerror(char *s);
    int yylex(void);
    std::string operatorTokenToString(address_t token);

#line 127 "parser.hpp"

#endif /* !YY_YY_PARSER_HPP_INCLUDED  */
