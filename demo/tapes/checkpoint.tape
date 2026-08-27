# A snapshot before the agent runs. It never touches your worktree.
#
# GENERATED shape, hand-written content. Re-record with `make -C demo`.
Source common.tape
Source setup.tape
Output out/checkpoint.gif
Set Height 520

Sleep 700ms
Type `echo "// agent was here" >> src/api/client.ts`
Enter
Sleep 500ms
Type "chute checkpoint ."
Enter
Sleep 2.5s
Type "git status --short"
Enter
Sleep 2s
Sleep 1.2s
