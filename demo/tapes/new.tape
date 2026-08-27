# The clipboard becomes a correctly named, correctly typed file.
#
# GENERATED shape, hand-written content. Re-record with `make -C demo`.
Source common.tape
Source setup.tape
Output out/new.gif
Set Height 480

Sleep 700ms
Hide
Type "pbcopy < $CHUTE_REPO/demo/fixtures/answer.md"
Enter
Type "clear"
Enter
Show
Type "chute new --no-rename"
Enter
Sleep 2s
Type "ls *.md"
Enter
Sleep 2s
Sleep 1.2s
