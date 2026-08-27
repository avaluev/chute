# The other direction: an agent's markdown answer becomes a real file tree.
#
# GENERATED shape, hand-written content. Re-record with `make -C demo`.
Source common.tape
Source setup.tape
Output out/unpack.gif
Set Height 760

Sleep 700ms
Hide
Type "pbcopy < $CHUTE_REPO/demo/fixtures/answer.md"
Enter
Type "clear"
Enter
Show
Type "# an agent just answered with three files, on the clipboard"
Enter
Sleep 600ms
Type "chute unpack"
Enter
Sleep 2.5s
Type "chute unpack --force"
Enter
Sleep 2s
Type "ls src/rate tests"
Enter
Sleep 2s
Sleep 1.2s
