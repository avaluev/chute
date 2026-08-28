# Agent B — ProcessIdentity — 2026-08-28

Baseline: 846 assertions, 0 failed. After: 893 assertions, 0 failed (+47, all mine).
Perturbation: broke `userDataDir`'s flag string → 10 failed, 883 passed. Restored → 893/0 clean.
(One unrelated flaky `ProcessMetrics ›` timing failure seen once mid-session — the coordinator's
concurrent file, ignored per instruction; not present on the final green run.)

argv cache, measured directly (not the task's cited 0.371 ms/pid, which I could not reproduce):
153 pids visible via `proc_listallpids` (122 resolved) — cold 0.0095 ms/pid, warm (cached)
0.00013 ms/pid, ~73x. `proc_listallpids` itself undercounts vs `KERN_PROC_ALL` for a non-root
user (153–169 here vs 659) — noted, not fixed, since I read pids handed in, not enumerate them.

Limit hit: `proc_pidpath` is NOT uid-scoped like `proc_pid_rusage`/`KERN_PROCARGS2` — it resolves
root's launchd for this non-root user. Fixed a wrong test assumption (pid 1 refusing) accordingly.
Product limit documented in code: a profile *inside* one running Chrome instance is unattributable
from process info — only the instance (`--user-data-dir`) is nameable.
