#!/bin/bash                                                                     
lex lexer.l
gcc lex.yy.c -ll -o lexer
./lexer test.c < test.pas

