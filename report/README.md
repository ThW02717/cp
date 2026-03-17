# hw1 report

|Field|Value|
|-:|:-|
|Name|TODO|
|ID|TODO|

## How much time did you spend on this project

About 6 hours.

## Project overview

This project implements a scanner for the P language in `flex`.

The main implementation is in `src/scanner.l`. The scanner recognizes:

- Delimiters such as `,`, `;`, `:`, `(`, `)`, `[` and `]`
- Arithmetic, relational, assignment, and logical operators
- Reserved words and identifiers
- Decimal integers, octal integers, floating-point constants, and scientific notation
- String constants with doubled double-quotes (`""`) handled as a literal `"`
- C-style comments, C++-style comments, and pseudocomments

I used Flex start conditions to simplify multi-character contexts:

- `COMMENT` handles multi-line comments until the first `*/`
- `STRING` collects string contents and converts `""` into a single double quote

The scanner also keeps track of the current source line and line number. This is used to implement:

- source program listing (`S` option)
- token listing (`T` option)
- precise error messages for invalid characters

For pseudocomments, the scanner checks `//&<option><sign>` at the beginning of a line comment and updates option `S` or `T` immediately on that same source line.

## What is the hardest you think in this project

The hardest part was number tokenization because the lexical rules are intentionally strict. Several inputs that look like a single number actually have to be split into multiple tokens, for example:

- `008` should become `00` and `8`
- `678.670` should become `678.67` and `0`
- `123e-001` should become `123e-0` and `01`

This means the regular expressions must be written to match only the valid prefix instead of greedily assuming the whole substring belongs to one token.

Another tricky part is pseudocomment behavior. Since `//&S+` and `//&T-` take effect on the same line where they appear, the scanner must update the option state before the newline is flushed for source listing.

## Feedback to T.A.s

> Please help us improve our assignment, thanks.

The assignment is well-structured and the incremental design makes sense for a compiler course. The provided sample outputs are especially helpful for understanding edge cases in numbers and pseudocomments.
