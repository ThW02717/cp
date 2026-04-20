# hw2 report

|||
|-:|:-|
|Name|曹瀚文|
|ID|314551138|

## How much time did you spend on this project

About 4 to 5 hours.

## Project overview

In this homework, I mainly modified `scanner.l` and `parser.y`.

For `scanner.l`, I kept the original behavior for printing source lines and tokens, but changed the actions so that the scanner also returns tokens to the parser. For example, identifiers return `ID`, reserved words return their corresponding token names, and symbols such as `+`, `-`, `(`, `)` are returned as character tokens. This lets `yyparse()` use the scanner output instead of only printing tokens like in hw1.

I also kept the pseudo-comment options such as `//&S+`, `//&S-`, `//&T+`, and `//&T-`, so the output format still follows the requirement from hw1.

For `parser.y`, I wrote the grammar rules according to the homework spec. The parser supports program structure, declarations, scalar types, array types, function declarations, function definitions, compound statements, assignment, print, read, if-else, while, for, return statements, function calls, variable references, and expressions.

I separated the grammar into smaller parts, such as `declaration_list`, `function_list`, `statement_list`, `identifier_list`, `formal_argument_list`, and `expression_list`. This made it easier to represent the optional and repeated parts in the spec. For array types and array references, I used recursive rules, so declarations like `array 4 of array 2 of integer` and references like `a[i][j]` can be parsed.

For expressions, I used bison precedence declarations to handle arithmetic, relational, logical, and unary operators. This also makes cases like `--b` and `not not b` parse correctly. Parentheses are also supported, so expressions can be grouped explicitly.

This homework only checks syntax, so I did not handle semantic errors such as type mismatch, undeclared variables, wrong return type, or wrong number of function arguments. For example, an expression like `3 + true` is syntactically valid in this homework, even though it should be rejected in semantic analysis later.

For testing, I ran `make test` in the docker environment, and all visible test cases passed. I also tried some extra cases by myself, including:

- empty compound statements
- function declarations and definitions with no arguments
- multiple formal argument groups separated by semicolons
- nested array declarations
- multidimensional array references
- consecutive unary operators like `--b` and `not not b`
- declarations after statements, which should be rejected
- function return type being an array type, which should be rejected by the grammar

## What is the hardest you think in this project

The hardest part for me was deciding how to organize the grammar rules for expressions and statements. Some rules start with the same token, especially identifier-related rules like variable references and function calls, so I had to make sure they still parse correctly in different places.

Another tricky part was handling the order inside a compound statement. Declarations must appear before statements, so a case like declaring a variable after a statement should become a syntax error.

The error cases were also a little tricky because the parser should reject the input at a reasonable token. I used the sample outputs to check whether my grammar accepts and rejects programs in the expected places.

## Feedback to T.A.s

good!