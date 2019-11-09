#!/bin/bash

VAR1=aaa
VAR2=bbb

cat > test.txt << EOF
var1=$VAR1
var2=$VAR2
EOF
