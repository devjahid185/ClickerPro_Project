# Cleanup — Step 3 Changelog: Remove Deprecated Node Backend

> Date: 2026-06-08
> Scope approved: Step 3 only (remove dead `backend/`), archive-first.
> Constraints honored: no business-logic / UI / API / route / DB changes to the
> **active** apps. Only the unused legacy directory was removed.

---

## Summary

The deprecated Node.js/Express backend (`backend/`) — fully replaced by
`laravel_backend/` — has been archived to a git tag and removed from the
working tree. **174 tracked files** removed; the active stack (Laravel API,
web app, admin panel, Flutter) is unaffected.

---

## 1. Archive Method Used

**Git annotated tag** (chosen over a branch because there were 63 unrelated
uncommitted changes in the working tree — a branch checkout would have been
risky; a tag captures the committed `backend/` state cleanly without touching
the working tree).

```
Tag:     archive/node-backend
Points at: b4553ae (Initial commit — contained the full backend/)
Message: "Archive: deprecated Node.js backend before removal (Step 3 cleanup)…"
```

Verified the tag contains the complete backend tree (`backend/src`,
`backend/package.json`, `.github`, etc.) → fully restorable.

---

## 2. Verification Performed (before removal)

| Check | Result |
|-------|--------|
| Flutter imports of `backend/` | ✅ NONE |
| Web app imports | ✅ NONE |
| Admin panel imports | ✅ NONE |
| Laravel backend references | ✅ NONE |
| CI/CD dependency | ✅ NONE — only `backend/.github/workflows/backend-ci.yml` (self-contained, removed with it); no root/active workflow references it |
| Root `docker-compose` / `Makefile` / `package.json` | ✅ NONE exist referencing it |
| `.mcp` / `.cursor` configs | ✅ NONE |
| `backend/` self-contained | ✅ Own `package.json` — isolated Node project |

---

## 3. Files Removed

- **Entire `backend/` directory** — **174 git-tracked files** (`git rm -r backend/`)
  plus its untracked `node_modules/` (`rm -rf`).
- Size reclaimed: **~231 MB** working tree.
- Includes the stale `backend/Dockerfile`, `backend/DEPLOY.md`,
  `backend/.github/workflows/backend-ci.yml` — all deploy footguns now gone.

No files in `laravel_backend/`, `web_app/`, `admin_panel/`, or `clicker_pro/`
were modified.

---

## 4. Verification Performed (after removal)

| Check | Result |
|-------|--------|
| Top-level dirs | `admin_panel/ clicker_pro/ keystores/ laravel_backend/ web_app/` (dead backend gone) |
| Laravel `route:list` | ✅ 166 routes (unchanged) |
| web_app `tsc --noEmit` | ✅ 0 errors |
| admin_panel `tsc --noEmit` | ✅ 0 errors |
| Archive tag restorable | ✅ `git ls-tree archive/node-backend backend/` returns full tree |

---

## 5. Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Losing the old API contract reference | 🟢 Low | Fully preserved in `archive/node-backend` tag — restore anytime |
| The deletion is staged but not yet committed | 🟢 Low | Working tree change only; can be reverted with `git restore` until committed (see rollback) |
| Tag not pushed to remote | 🟡 Note | If you use a remote, **push the tag** so the archive survives a fresh clone: `git push origin archive/node-backend` |

No runtime risk — nothing depended on `backend/`.

---

## 6. Rollback Instructions

**Before committing** (removal is currently staged in the working tree):
```bash
# Restore the whole directory from the index/HEAD
git restore --staged --worktree backend/
# (or simply: git checkout HEAD -- backend/)
```

**After committing** the removal:
```bash
# Restore from the archive tag
git checkout archive/node-backend -- backend/
```

**Inspect the archive without restoring:**
```bash
git ls-tree -r archive/node-backend backend/      # list files
git show archive/node-backend:backend/package.json # view a file
```

---

## Result
- ✅ Dead Node backend archived (`archive/node-backend` tag) and removed (174 files, ~231 MB)
- ✅ Active stack untouched — Laravel 166 routes, web+admin tsc clean
- ✅ Fully reversible
- ⏭️ **Step 4 (gradual `any` typing) NOT started — awaiting your approval**

> Reminder: if working with a remote, run `git push origin archive/node-backend`
> and then commit the removal so the change and its archive both persist.
