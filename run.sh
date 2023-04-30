#!/bin/bash
yacc -v -d -t parser.y
lex lexer.l
gcc -w y.tab.c lex.yy.c -ll -o parser
./parser < test.pas > icg.output
python3 optimizer.py > optimized_ICG
