---
name: Bug report
about: Something in the Finder menu, the menu bar, or the CLI is wrong
title: ""
labels: bug
---

## What happened

<!-- What you did, what you expected, what you got instead. -->

## `chute doctor --report` output

Run this and paste the output — it carries the build stamp (git SHA the running app was built
from), macOS version, and the install/extension/hook checks in one block, which is the same
question a report needs answered first:

```bash
chute doctor --report
```

```
<paste here>
```

If `chute` isn't on your `PATH` (a source build, not Homebrew), run it from the built binary
instead: `.build/release/chute doctor --report`.

## Steps to reproduce

1.
2.
3.

## Anything else

<!-- Logs, screenshots, a link to the file/repo that triggered it (redact anything private) -->
