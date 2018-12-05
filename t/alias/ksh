export FOO=53 BAR=abc
alias setfoo="export FOO=42"
alias setbar="export BAR=def"
alias -x setfoo setbar
# because of ksh evaluation order,  setfoo  alias is not fully
# available until this script completes, so
#     setfoo
# doesn't work here. But this does:
eval setfoo
# see clayb.net/blog/alias-does-not-work-as-expected-in-ksh-functions/
