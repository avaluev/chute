# Mask every key before the file leaves your machine.
#
# GENERATED shape, hand-written content. Re-record with `make -C demo`.
Source common.tape
Source setup.tape
Output out/redact.gif
Set Height 520

Sleep 700ms
Type "cat $CHUTE_REPO/demo/fixtures/leaky.env.txt"
Enter
Sleep 2s
Type "chute redact $CHUTE_REPO/demo/fixtures/leaky.env.txt"
Enter
Sleep 3s
Sleep 1.2s
