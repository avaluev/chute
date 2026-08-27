# The highest-frequency job: 32 times a day, clean absolute paths.
#
# GENERATED shape, hand-written content. Re-record with `make -C demo`.
Source common.tape
Source setup.tape
Output out/paths.gif
Set Height 420

Sleep 700ms
Type "chute paths src/auth/*.ts src/api/routes.ts"
Enter
Sleep 2.5s
Sleep 1.2s
