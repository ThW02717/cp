# hw1 report

|Field|Value|
|-:|:-|
|Name|曹瀚文|
|ID|314551138|

## How much time did you spend on this project

About 6 hours.

## Project overview

In this homework, I implemented a scanner for the P language with `flex`.

Most of the work is in `src/scanner.l`. My scanner can recognize:

- Delimiters such as `,`, `;`, `:`, `(`, `)`, `[` and `]`
- Arithmetic, relational, assignment, and logical operators
- Reserved words and identifiers
- Decimal integers, octal integers, floating-point constants, and scientific notation
- String constants with doubled double-quotes (`""`) handled as a literal `"`
- C-style comments, C++-style comments, and pseudocomments

While implementing it, I used Flex start conditions to make some parts easier to handle:

- `COMMENT` handles multi-line comments until the first `*/`
- `STRING` collects string contents and converts `""` into a single double quote

I also tracked the current line content and line number so the scanner can:

- source program listing (`S` option)
- token listing (`T` option)
- precise error messages for invalid characters

For pseudocomments, I checked patterns like `//&S+` and `//&T-` and updated the option immediately on that same line.

## What is the hardest you think in this project

The hardest part for me was number tokenization. At first it looked simple, but after reading the spec carefully, I found that many inputs that look like one number actually need to be split into multiple tokens. For example:

- `008` should become `00` and `8`
- `678.670` should become `678.67` and `0`
- `123e-001` should become `123e-0` and `01`

Because of this, I had to be careful not to write the regex too greedily. The scanner should only match the valid prefix and leave the remaining characters for later rules.

Another part that took some time was pseudocomment behavior. Since `//&S+` and `//&T-` take effect on the same line where they appear, I had to make sure the scanner updates the option before printing the source listing of that line.

## Feedback to T.A.s

> Please help us improve our assignment, thanks.

Good 

