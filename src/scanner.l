%option never-interactive
%option nounput
%option noinput

/*
 * ============================================================
 *  Scanner States
 * ============================================================
 *  These are exclusive start conditions used when the scanner
 *  enters a special context.
 *
 *  INITIAL : normal tokenizing mode
 *  COMMENT : inside a C-style comment
 *  STRING  : inside a string literal "..."
 */
%x COMMENT
%x STRING

/* C declarations used by rule actions and helper functions. */
%{
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INITIAL_STRING_CAP 64
#define INITIAL_LINE_CAP 512
/* Code runs each time a token is matched. */
#define YY_USER_ACTION updateCurrentLine(yytext);

uint32_t line_num = 1;
uint32_t col_num = 1;
static uint32_t opt_src = 1;
static uint32_t opt_tok = 1;
/* Source listing buffer/state. */
static char *current_line = NULL;
static size_t current_line_cap = 0;
/* Current string-literal buffer/state. */
static char *string_buf = NULL;
static size_t string_len = 0;
static size_t string_cap = 0;

static void updateCurrentLine(const char *source);
static void ensureLineCapacity(size_t required_len);
static void listToken(const char *name);
static void listLiteral(const char *name, const char *literal);
static void beginString(void);
static void appendStringText(const char *text);
static void appendStringChar(char ch);
static void identifierClassify(const char *text);
static void handlePseudocomment(const char *text);

%}

/*
 * ============================================================
 *  Reusable Regex Definitions
 * ============================================================
 *  These named patterns are building blocks for the rules
 *  section. Defining them here keeps the matching rules shorter
 *  and easier to read.
 */
LETTER          [A-Za-z]
DIGIT           [0-9]
ID              {LETTER}({LETTER}|{DIGIT})*
DEC_INT         0|[1-9]{DIGIT}*
OCT_INT         0[0-7]+

FLOAT_FRAC      0|{DIGIT}*[1-9]
NONZERO_FRAC    {DIGIT}*[1-9]
FLOAT           ({DEC_INT})\.({FLOAT_FRAC})

SCI_COEFF       ([1-9]{DIGIT}*|[1-9]{DIGIT}*\.({FLOAT_FRAC})|0\.({NONZERO_FRAC}))
SCI_EXP         [+-]?(0|[1-9]{DIGIT}*)
SCIENTIFIC      ({SCI_COEFF})[Ee]({SCI_EXP})
PSEUDOCOMMENT   \/\/&[A-Z][+-][^\n]*

%%
<INITIAL>[ \t\r]+      { }
\n                      { }

<INITIAL>{PSEUDOCOMMENT} { handlePseudocomment(yytext); }
<INITIAL>"//"[^\n]*      { }

<INITIAL>"/*"            { BEGIN(COMMENT); }
<COMMENT>\n              { }
<COMMENT>[^*\n]+         { }
<COMMENT>"*"+[^*/\n]*    { }
<COMMENT>"*"+"/"         { BEGIN(INITIAL); }

<INITIAL>"\""            { beginString(); BEGIN(STRING); }
<STRING>"\"\""           { appendStringChar('"'); }
<STRING>[^\n\"]+         { appendStringText(yytext); }
<STRING>"\""             { BEGIN(INITIAL); listLiteral("string", string_buf); }

<INITIAL>":="            { listToken(":="); }
<INITIAL>"<="            { listToken("<="); }
<INITIAL>"<>"            { listToken("<>"); }
<INITIAL>">="            { listToken(">="); }

<INITIAL>","             { listToken(","); }
<INITIAL>";"             { listToken(";"); }
<INITIAL>":"             { listToken(":"); }
<INITIAL>"("             { listToken("("); }
<INITIAL>")"             { listToken(")"); }
<INITIAL>"["             { listToken("["); }
<INITIAL>"]"             { listToken("]"); }
<INITIAL>"+"             { listToken("+"); }
<INITIAL>"-"             { listToken("-"); }
<INITIAL>"*"             { listToken("*"); }
<INITIAL>"/"             { listToken("/"); }
<INITIAL>"<"             { listToken("<"); }
<INITIAL>">"             { listToken(">"); }
<INITIAL>"="             { listToken("="); }

<INITIAL>{SCIENTIFIC}    { listLiteral("scientific", yytext); }
<INITIAL>{FLOAT}         { listLiteral("float", yytext); }
<INITIAL>{OCT_INT}       { listLiteral("oct_integer", yytext); }
<INITIAL>{DEC_INT}       { listLiteral("integer", yytext); }
<INITIAL>{ID}            { identifierClassify(yytext); }

. {
    printf("Error at line %u: bad character \"%s\"\n", line_num, yytext);
    exit(-1);
}

%%

/*
 * ============================================================
 *  Helper Functions
 * ============================================================
 *  The rules above focus on matching.
 *  The functions below implement the actual behavior after a
 *  match succeeds, such as:
 *  - maintaining the current source line
 *  - printing tokens
 *  - accumulating string content
 *  - deciding whether an identifier is a keyword
 *  - handling pseudocomment options
 */

/** @note The line is printed out and flushed when a newline character is encountered. */
static void updateCurrentLine(const char *source) {
    // Initialize buffer
    if (current_line == NULL) {
        current_line_cap = INITIAL_LINE_CAP;
        current_line = (char *)malloc(current_line_cap);
        if (current_line == NULL) {
            fprintf(stderr, "Out of memory\n");
            exit(-1);
        }
        current_line[0] = '\0';
    }

    /* col_num is one-based */
    for (const char *c = source; *c; ++c) {
        if (*c == '\n') {
            if (opt_src) {
                printf("%u: %s\n", line_num, current_line);
            }
            ++line_num;
            col_num = 1;
            current_line[0] = '\0';
        } else {
            ensureLineCapacity(col_num + 1);
            current_line[col_num - 1] = *c;
            current_line[col_num] = '\0';
            ++col_num;
        }
    }
}

/*
 * Grow the source-line buffer dynamically so long input lines
 * can still be listed completely.
 */
static void ensureLineCapacity(size_t required_len) {
    /* Most lines are short, so if the current buffer is already enough, just keep using it. */
    if (required_len <= current_line_cap) {
        return;
    }

    /* Double the capacity each time to avoid reallocating too often on long lines. */
    size_t new_cap = current_line_cap;
    while (required_len > new_cap) {
        new_cap *= 2;
    }

    current_line = (char *)realloc(current_line, new_cap);
    if (current_line == NULL) {
        fprintf(stderr, "Out of memory\n");
        exit(-1);
    }
    current_line_cap = new_cap;
}

static void listToken(const char *name) {
    /* T controls token listing only; scanning still happens even when token printing is off. */
    if (opt_tok) {
        printf("<%s>\n", name);
    }
}

static void listLiteral(const char *name, const char *literal) {
    /* Used for tokens whose actual matched text also has to be shown in the output. */
    if (opt_tok) {
        printf("<%s: %s>\n", name, literal);
    }
}

/* Start reading a new string token, so old content must be cleared first. */
static void beginString(void) {
    if (string_buf == NULL) {
        string_cap = INITIAL_STRING_CAP;
        string_buf = (char *)malloc(string_cap);
        if (string_buf == NULL) {
            fprintf(stderr, "Out of memory\n");
            exit(-1);
        }
    }
    string_len = 0;
    string_buf[0] = '\0';
}

static void appendStringText(const char *text) {
    const size_t text_len = strlen(text);

    /* String content may come in several matched chunks, so append instead of overwrite. */
    if (string_len + text_len + 1 > string_cap) {
        size_t new_cap = string_cap;
        while (string_len + text_len + 1 > new_cap) {
            new_cap *= 2;
        }
        string_buf = (char *)realloc(string_buf, new_cap);
        if (string_buf == NULL) {
            fprintf(stderr, "Out of memory\n");
            exit(-1);
        }
        string_cap = new_cap;
    }

    memcpy(string_buf + string_len, text, text_len + 1);
    string_len += text_len;
}

static void appendStringChar(char ch) {
    /* Reuse appendStringText() so single-char and multi-char appends share the same grow logic. */
    char text[2];
    text[0] = ch;
    text[1] = '\0';
    appendStringText(text);
}

/* ID 先用同一條 regex 抓進來，再在這裡分成 keyword / operator / id。 */
static void identifierClassify(const char *text) {
    /* Reserved words need the KW prefix in the output format. */
    if (strcmp(text, "var") == 0 || strcmp(text, "def") == 0 ||
        strcmp(text, "array") == 0 || strcmp(text, "of") == 0 ||
        strcmp(text, "boolean") == 0 || strcmp(text, "integer") == 0 ||
        strcmp(text, "real") == 0 || strcmp(text, "string") == 0 ||
        strcmp(text, "true") == 0 || strcmp(text, "false") == 0 ||
        strcmp(text, "while") == 0 || strcmp(text, "do") == 0 ||
        strcmp(text, "if") == 0 || strcmp(text, "then") == 0 ||
        strcmp(text, "else") == 0 || strcmp(text, "for") == 0 ||
        strcmp(text, "to") == 0 || strcmp(text, "begin") == 0 ||
        strcmp(text, "end") == 0 || strcmp(text, "print") == 0 ||
        strcmp(text, "read") == 0 || strcmp(text, "return") == 0) {
        char keyword[32];
        snprintf(keyword, sizeof(keyword), "KW%s", text);
        listToken(keyword);
        return;
    }
    /* These look like identifiers, but the spec says they are operators. */
    if (strcmp(text, "mod") == 0 || strcmp(text, "and") == 0 ||
        strcmp(text, "or") == 0 || strcmp(text, "not") == 0) {
        listToken(text);
        return;
    }

    /* If it is neither a reserved word nor a word-operator, it is a normal id. */
    listLiteral("id", text);
}

/* The regex already guarantees the //&X+ or //&X- shape, so we only read X and +/- here. */
static void handlePseudocomment(const char *text) {
    /* text[3] is the option letter after //&, and text[4] is + or -. */
    switch (text[3]) {
    case 'S':
        opt_src = (text[4] == '+');
        break;
    case 'T':
        opt_tok = (text[4] == '+');
        break;
    default:
        break;
    }
}

/** @note This function is not required if the input file is guaranteed to end
 * with a newline. However, students may find it useful to handle the case where
 * the input file does not end with a newline, as it has been reported several
 * times in the past.
 */
int yywrap(void) {
    /* Without this, the last source line would not be listed if the file ends without '\n'. */
    if (col_num > 1) {
        updateCurrentLine("\n");
    }
    /* no more input file */
    return 1;
}

int main(int argc, const char **argv) {
    /* This homework expects the scanner to read exactly one input file from argv[1]. */
    if (argc != 2) {
        fprintf(stderr, "Usage: %s [filename]\n", argv[0]);
        exit(-1);
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        fprintf(stderr, "Open file error\n");
        exit(-1);
    }

    /* yylex() is the scanner entry generated by flex from the rules section above. */
    yylex();

    fclose(yyin);
    free(current_line);
    free(string_buf);
    /* Free resources used by the scanner; otherwise, unused data structures
    will persist throughout the successive compiler phases. */
    yylex_destroy();

    return 0;
}
