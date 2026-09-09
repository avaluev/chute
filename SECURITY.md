# Security

## No network code

Chute opens no socket. It has no telemetry, no update checker, no account, no server it talks to.

```bash
grep -rn 'URLSession\|NSURLConnection' Sources/
```

returns nothing — that grep is the claim, run it yourself rather than take this file's word for
it.

## The one exception: `chute gist`

`chute gist <files…>` uploads, and only when you run it yourself
([`Sources/chute/Commands/GitCommands.swift`](Sources/chute/Commands/GitCommands.swift)). It never
opens a network connection directly — it shells out to your own `gh` CLI, using your own
credentials, and runs `gh gist create --secret` on the files you named, after staging redacted
copies (`chute redact`'s logic, applied before anything leaves the machine). "Secret" means
unlisted, not private — anyone with the URL can read it. If `gh` isn't installed or isn't
authenticated, the command fails before touching the network at all.

No other command in Chute makes a network call. `chute doctor`, `chute hooks`, and everything else
read and write local files only, mostly under `~/.chute/`.

## Reporting a vulnerability

Open a private report at
[github.com/avaluev/chute/security/advisories/new](https://github.com/avaluev/chute/security/advisories/new)
rather than a public issue. If you'd rather not use GitHub for it, reach the maintainer directly —
[@asnkt on Telegram](https://t.me/asnkt) or [linkedin.com/in/valuev](https://www.linkedin.com/in/valuev/),
both linked from the app itself (Chute menu bar → Settings → About).

There is no bug bounty — Chute is free and MIT with no company behind it — but a real report gets
read and fixed.

## What Chute touches on your machine

- **Reads:** the Finder selection you right-click, files you name on the CLI, your Keychain (only
  for `chute env inject`, and only key *names* are ever printed — never values), and hook JSON
  files it wrote itself under `~/.chute/sessions/`.
- **Writes:** files you explicitly asked it to create (`chute new`, `chute seed`, `chute basket`),
  and `~/.chute/` for its own session/basket state. It never writes to `~/.claude/settings.json`
  or any other tool's configuration — `chute hooks snippet`/`merged` print what you'd need to add,
  on stdout, for you to apply yourself.
- **Runs:** `gh` (only for `chute gist`, only if you invoke it), and standard macOS tools
  (`lsof`, `ps`, `osascript`) to read process/port state — never to modify anything outside what
  you asked for.

## Scope

Chute has no server, no cloud storage, and no user accounts, so most of the usual web
vulnerability classes don't apply. The categories that do: a Finder-extension permission escalation,
a `chute redact`/`chute gist` masking failure that leaks a secret, a path-traversal bug in file
commands, or anything that writes outside the directory you pointed Chute at. Report any of those.
