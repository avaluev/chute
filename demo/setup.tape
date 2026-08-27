# Hidden setup every demo shares. Not generated: this is logic, not colour.
#
# It puts the release binary on PATH and drops into the deterministic fixture, then replaces
# bash's default ">" with a prompt that looks like the product. A viewer who watches three demos
# should see one continuous machine, not three different terminals.
Hide
Type `export PATH="$CHUTE_REPO/.build/release:$PATH"; cd "$CHUTE_FIXTURE"`
Enter
Type `export PS1='\[\e[38;2;138;147;166m\]acme-app \[\e[38;2;115;250;102m\]❯\[\e[0m\] '`
Enter
Type "clear"
Enter
Show
