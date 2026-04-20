# hw2 report

|||
|-:|:-|
|Name|曹瀚文|
|ID|314551138|

## How much time did you spend on this project

About 4 hours.

## Project overview

The project is implemented with `scanner.l` and `parser.y`.

In `scanner.l`, I kept the source listing and token listing behavior from the starter code, and added return values for every token so that `yyparse()` can receive tokens from `yylex()`. Single-character delimiters and operators are returned as character tokens, while reserved words, multi-character operators, identifiers, and literals are returned as named tokens defined in `parser.y`.

In `parser.y`, I implemented the grammar for program units, declarations, scalar and array types, function declarations and definitions, compound statements, simple statements, conditionals, loops, return statements, variable references, function calls, literals, and expressions. The parser only checks syntax in this assignment. Semantic errors such as type mismatches are not checked.

Expression grammar uses bison precedence declarations to parse unary operators, binary arithmetic operators, relational operators, and logical operators. This also handles consecutive unary operators such as `--x` and `not not x`.

## What is the hardest you think in this project

The hardest part was organizing the grammar so that constructs starting with an identifier, such as variable references and function calls, can be parsed cleanly in different contexts. Another tricky part was keeping declaration blocks before statement blocks inside compound statements, since this affects syntactic error detection.

## Feedback to T.A.s

good assignment
