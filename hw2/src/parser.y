%{
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

extern int32_t line_num;    /* declared in scanner.l */
extern char current_line[]; /* declared in scanner.l */
extern FILE *yyin;          /* declared by lex */
extern char *yytext;        /* declared by lex */

extern int yylex(void);
static void yyerror(const char *msg);
extern int yylex_destroy(void);
%}

%token ID
%token INT_LITERAL OCT_LITERAL FLOAT_LITERAL SCI_LITERAL STRING_LITERAL
%token VAR ARRAY OF BOOLEAN INTEGER REAL STRING TRUE FALSE
%token DEF RETURN BEGIN_T END WHILE DO IF THEN ELSE FOR TO PRINT READ
%token ASSIGN LE NE GE MOD AND OR NOT

%left OR AND NOT
%nonassoc '<' LE NE GE '>' '='
%left '+' '-'
%left '*' '/' MOD
%right UMINUS

%%

program
    : ID ';' declaration_list function_list compound_statement END
    ;

declaration_list
    : /* empty */
    | declaration_list declaration
    ;

declaration
    : variable_declaration
    | constant_declaration
    ;

variable_declaration
    : VAR identifier_list ':' type ';'
    ;

constant_declaration
    : VAR identifier_list ':' optional_sign integer_literal ';'
    | VAR identifier_list ':' optional_sign real_literal ';'
    | VAR identifier_list ':' STRING_LITERAL ';'
    | VAR identifier_list ':' boolean_literal ';'
    ;

optional_sign
    : /* empty */
    | '-'
    ;

identifier_list
    : ID
    | identifier_list ',' ID
    ;

type
    : scalar_type
    | array_type
    ;

scalar_type
    : INTEGER
    | REAL
    | STRING
    | BOOLEAN
    ;

array_type
    : ARRAY integer_literal OF type
    ;

integer_literal
    : INT_LITERAL
    | OCT_LITERAL
    ;

real_literal
    : FLOAT_LITERAL
    | SCI_LITERAL
    ;

boolean_literal
    : TRUE
    | FALSE
    ;

function_list
    : /* empty */
    | function_list function
    ;

function
    : function_header ';'
    | function_header compound_statement END
    ;

function_header
    : ID '(' formal_argument_seq ')' return_type
    ;

formal_argument_seq
    : /* empty */
    | formal_argument_list
    ;

formal_argument_list
    : formal_argument
    | formal_argument_list ';' formal_argument
    ;

formal_argument
    : identifier_list ':' type
    ;

return_type
    : /* empty */
    | ':' scalar_type
    ;

compound_statement
    : BEGIN_T declaration_list statement_list END
    ;

statement_list
    : /* empty */
    | statement_list statement
    ;

statement
    : simple_statement
    | conditional_statement
    | function_call_statement
    | loop_statement
    | return_statement
    | compound_statement
    ;

simple_statement
    : assignment_statement
    | print_statement
    | read_statement
    ;

assignment_statement
    : variable_reference ASSIGN expression ';'
    ;

print_statement
    : PRINT expression ';'
    ;

read_statement
    : READ variable_reference ';'
    ;

conditional_statement
    : IF expression THEN compound_statement END IF
    | IF expression THEN compound_statement ELSE compound_statement END IF
    ;

function_call_statement
    : function_call ';'
    ;

loop_statement
    : WHILE expression DO compound_statement END DO
    | FOR ID ASSIGN integer_literal TO integer_literal DO compound_statement END DO
    ;

return_statement
    : RETURN expression ';'
    ;

expression
    : literal_constant
    | variable_reference
    | function_call
    | '(' expression ')'
    | expression '+' expression
    | expression '-' expression
    | expression '*' expression
    | expression '/' expression
    | expression MOD expression
    | expression '<' expression
    | expression LE expression
    | expression NE expression
    | expression GE expression
    | expression '>' expression
    | expression '=' expression
    | expression AND expression
    | expression OR expression
    | '-' expression %prec UMINUS
    | NOT expression
    ;

literal_constant
    : integer_literal
    | real_literal
    | STRING_LITERAL
    | boolean_literal
    ;

variable_reference
    : ID array_index_list
    ;

array_index_list
    : /* empty */
    | array_index_list '[' expression ']'
    ;

function_call
    : ID '(' expression_seq ')'
    ;

expression_seq
    : /* empty */
    | expression_list
    ;

expression_list
    : expression
    | expression_list ',' expression
    ;

%%

void yyerror(const char *msg) {
    fprintf(stderr,
            "\n"
            "|-----------------------------------------------------------------"
            "---------\n"
            "| Error found in Line #%d: %s\n"
            "|\n"
            "| Unmatched token: %s\n"
            "|-----------------------------------------------------------------"
            "---------\n",
            line_num, current_line, yytext);
    exit(-1);
}

int main(int argc, const char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <filename>\n", argv[0]);
        exit(-1);
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        perror("fopen() failed");
        exit(-1);
    }

    yyparse();

    fclose(yyin);
    yylex_destroy();

    printf("\n"
           "|--------------------------------|\n"
           "|  There is no syntactic error!  |\n"
           "|--------------------------------|\n");
    return 0;
}
