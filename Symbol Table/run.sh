#!/bin/bash
yacc -v -d -t parser.y
lex lexer.l
gcc -w y.tab.c lex.yy.c -ll -o parser
./parser < test.pas > symbol_table
cat symbol_table
