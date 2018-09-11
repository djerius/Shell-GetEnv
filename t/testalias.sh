export FOO=23 BAR=abc
alias setfoo="export FOO=42"
alias setbar="export BAR=def"
# ... || eval setfoo: so it works if sh is aliased to ksh
setfoo || eval setfoo
