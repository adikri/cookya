# RESUME — slice 1: EAS Build → APK setup

**Active branch:** `infra/eas-android-distribution` (off `origin/codex/react-native-android` at `bb7e141`)
**Worktree:** `.claude/worktrees/mystifying-perlman-6edff6` is on this branch. Main worktree (`/Users/adi/Documents/iosProjects/cookya`) is still on `codex/react-native-android` with an uncommitted `cookya/Views/HomeView.swift` modification from a previous session.

## Goal of this slice
Wire EAS Build so an installed APK exists for partner-distribution testing. Acceptance: `eas build --profile preview --platform android` produces an APK that installs and signs in on a real Android phone.

## Plan
1. ✅ Confirmed `android.package = com.adikri.cookya`
2. ⏳ User: stash uncommitted `cookya/Views/HomeView.swift` in main worktree (`git stash push -m "WIP HomeView from prev session" cookya/Views/HomeView.swift`)
3. ✅ Edited `mobile/app.json` to add `android.package`
4. ⏳ Commit (`Add android.package to mobile/app.json for EAS Android distribution`)
5. ⏳ Push branch to origin
6. ⏳ User: switch main worktree to `infra/eas-android-distribution` (`git checkout infra/eas-android-distribution` after stash)
7. ⏳ User: `cd mobile && npm install -g eas-cli && eas login`
8. ⏳ User: `eas build:configure` — generates `eas.json`, adds `extra.eas.projectId` to `app.json`. User commits these (file changes from the eas tooling).
9. ⏳ Claude adds env-var block to `eas.json` (public Supabase + Worker URLs); user runs `eas secret:create` for sensitive worker token
10. ⏳ User: `eas build --profile preview --platform android`. Wait ~10–15 min.
11. ⏳ User installs APK on Adi's phone + partner's phone. Smoke-test sign-in.

## Exact next step
Commit `mobile/app.json` change, push branch, hand off to user for steps 2 + 6–8.

## What lives where
- App: `mobile/` (Expo SDK 54, RN 0.81.5, expo-router, supabase-js, zustand, expo-secure-store)
- Currently no `eas.json`, no `android.package`, no `extra.eas.projectId`
- Env vars: app reads `process.env.EXPO_PUBLIC_*` (verified by grep on the branch)
- Sensitive: COOKYA_APP_TOKEN for worker auth; everything else (Supabase URL, anon key, Worker URL) is safe-to-bundle public values

## Carry forward (slice 2 onwards)
Once APK installs and partner can sign in: smoke-test checklist in `WORKLOG.md` 2026-05-02 entry → big merge → first trunk-based feature.
