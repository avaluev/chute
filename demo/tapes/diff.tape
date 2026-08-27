# What did the agent actually change?
#
# GENERATED shape, hand-written content. Re-record with `make -C demo`.
Source common.tape
Source setup.tape
Output out/diff.gif
Set Height 620

Sleep 700ms
Hide
Type `echo "export const RETRIES = 3;" >> src/api/client.ts`
Enter
Type `printf '\nexport function logout() {\n  document.cookie = "";\n}\n' >> src/auth/session.ts`
Enter
Type `sed -i "" "s/Sign in/Log in/" src/ui/Nav.tsx`
Enter
Type `printf 'export const VERSION = "1.1.0";\n' > src/version.ts`
Enter
Type "clear"
Enter
Show
Type "chute diff ."
Enter
Sleep 3s
Sleep 1.2s
