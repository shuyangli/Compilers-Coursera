/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
ASSIGNMENT      <-
LESSEQUAL       <=
MONOCHAROP      [\+\-\*\/\=\(\)\:\;\{\}\.\,\@\<\~]
WHITESPACE      [\ \t\r\n\f\v]
DIGIT           [0-9]
ALPHA           [a-zA-Z]
UPPERCASE       [A-Z]
LOWERCASE       [a-z]
ALPHANUM        [0-9a-zA-Z]
IDCHAR          [0-9a-zA-Z_]
A               [Aa]
B               [Bb]
C               [Cc]
D               [Dd]
E               [Ee]
F               [Ff]
G               [Gg]
H               [Hh]
I               [Ii]
J               [Jj]
K               [Kk]
L               [Ll]
M               [Mm]
N               [Nn]
O               [Oo]
P               [Pp]
Q               [Qq]
R               [Rr]
S               [Ss]
T               [Tt]
U               [Uu]
V               [Vv]
W               [Ww]
X               [Xx]
Y               [Yy]
Z               [Zz]


%x COMMENT
%x STRING
%option stack
%%

 /*
  *  Nested comments
  */

--.*<<EOF>>             {
    BEGIN(INITIAL);
    cool_yylval.error_msg = "EOF in comment";
    return (ERROR);
}
--.*                    ;
<COMMENT>\(\*           { yy_push_state(COMMENT); }
<COMMENT>\*\)           { yy_pop_state(); }
<COMMENT><<EOF>>        {
    BEGIN(INITIAL);
    cool_yylval.error_msg = "EOF in comment";
    return (ERROR);
}
<COMMENT>\n             { curr_lineno++; }
<COMMENT>.              ;

<INITIAL>\(\*           { yy_push_state(COMMENT); }
<INITIAL>\*\)           {
    cool_yylval.error_msg = "Unmatched *)";
    return (ERROR);
}


 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
{ASSIGNMENT}            { return (ASSIGN); }
{LESSEQUAL}             { return (LE); }

 /*
  * Single-character operators
  */
{MONOCHAROP}            { return yytext[0]; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{C}{L}{A}{S}{S}         { return (CLASS); }
{E}{L}{S}{E}            { return (ELSE); }
{F}{I}                  { return (FI); }
{I}{F}                  { return (IF); }
{I}{N}                  { return (IN); }
{I}{S}{V}{O}{I}{D}      { return (ISVOID); }
{L}{E}{T}               { return (LET); }
{L}{O}{O}{P}            { return (LOOP); }
{P}{O}{O}{L}            { return (POOL); }
{T}{H}{E}{N}            { return (THEN); }
{W}{H}{I}{L}{E}         { return (WHILE); }
{C}{A}{S}{E}            { return (CASE); }
{E}{S}{A}{C}            { return (ESAC); }
{N}{E}{W}               { return (NEW); }
{O}{F}                  { return (OF); }
{N}{O}{T}               { return (NOT); }
{I}{N}{H}{E}{R}{I}{T}{S}    { return (INHERITS); }
t{R}{U}{E}              {
    cool_yylval.boolean = true;
    return (BOOL_CONST);
}
f{A}{L}{S}{E}           {
    cool_yylval.boolean = false;
    return (BOOL_CONST);
}

 /* Identifiers */
{UPPERCASE}{IDCHAR}*    {
    cool_yylval.symbol = idtable.add_string(yytext);
    return (TYPEID);
}
{LOWERCASE}{IDCHAR}*    {
    cool_yylval.symbol = idtable.add_string(yytext);
    return (OBJECTID);
}

 /* Whitespace */
\n                      { curr_lineno++; }
{WHITESPACE}            ;

 /* Integer */
{DIGIT}+                {
    cool_yylval.symbol = inttable.add_string(yytext);
    return (INT_CONST);
}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
<INITIAL>\"             {
    yy_push_state(STRING);
    string_buf_ptr = &string_buf[0];
}
<STRING>\\b             { *(string_buf_ptr++) = '\b'; }
<STRING>\\t             { *(string_buf_ptr++) = '\t'; }
<STRING>\\\n            { *(string_buf_ptr++) = '\n'; }
<STRING>\\n             { *(string_buf_ptr++) = '\n'; }
<STRING>\\f             { *(string_buf_ptr++) = '\f'; }
<STRING>\\\"            { *(string_buf_ptr++) = '"'; }
<STRING>\\\0            {
    BEGIN(INITIAL);
    cool_yylval.error_msg = "Escaped null character in string constant";
    return (ERROR);
}
<STRING>\\.             { *(string_buf_ptr++) = yytext[1]; }
<STRING>\"              {
    yy_pop_state();
    *(string_buf_ptr++) = '\0';
    cool_yylval.symbol = stringtable.add_string(string_buf);
    return (STR_CONST);
}
<STRING>\n             {
    BEGIN(INITIAL);
    cool_yylval.error_msg = "Newline character in string constant";
    return (ERROR);
}
<STRING>\0             {
    BEGIN(INITIAL);

    cool_yylval.error_msg = "Unescaped null character in string constant";
    return (ERROR);
}
<STRING><<EOF>>         {
    BEGIN(INITIAL);
    cool_yylval.error_msg = "EOF in string constant";
    return (ERROR);
}
<STRING>.               { *(string_buf_ptr++) = yytext[0]; }

 /* Catch-all error case */
.                       {
    BEGIN(INITIAL);
    cool_yylval.error_msg = yytext;
    return(ERROR);
}

%%
