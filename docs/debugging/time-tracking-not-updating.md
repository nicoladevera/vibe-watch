# VibeWatch Debugging Note - Time Tracking Not Updating (2026-01-03)

**Status**: Resolved - time tracking updating correctly
**Scope**: Time tracking stuck at 0s or stalled under 1 minute, history breakdown lagged behind live totals

---

## 🎯 Problem Statement

**Issue**: Time tracking stayed at 0 seconds even with Cursor/Antigravity/Terminal active.
**Impact**: Menu bar and history showed no progress.

---

## 🔍 Findings

- Tracking timer fired once but did not keep ticking reliably.
- App detection was working; tracked apps were detected in logs.
- Idle detection via `ioreg` stalled the tracking loop.
- History view used persisted records (saved every 5 minutes), so per-app breakdown lagged live totals.

---

## ✅ Fixes Applied

1) **Tracking timer reliability**
- Replaced `Timer` with `DispatchSourceTimer` on a background queue.
- Ensured ticks continue reliably.

2) **Idle detection (non-blocking)**
- Replaced `ioreg`-based idle detection with CoreGraphics:
  `CGEventSource.secondsSinceLastEventType`.
- Uses the minimum idle time across key/mouse/scroll events.

3) **App detection robustness**
- Improved case-insensitive matching and added bundle ID alias for Cursor.

4) **Accurate totals and UI updates**
- Total time capped to real elapsed time; per-app breakdown recorded separately.
- Polling interval set to 15 seconds for consistent increments.
- History view merges the live `todayRecord` so breakdowns match the menu bar.

---

## ✅ Validation

- Time increments in 15s steps while using tracked apps.
- Menu bar time updates immediately after Settings changes.
- History breakdown reflects live totals (no 5-minute lag).

---

## 📄 Files Changed

- `VibeWatch/Services/TimeTracker.swift`
- `VibeWatch/Services/IdleMonitor.swift`
- `VibeWatch/Services/AppDetector.swift`
- `VibeWatch/AppDelegate.swift`
- `VibeWatch/Views/MenuBarIcon.swift`
- `VibeWatch/Models/DailyRecord.swift`
- `VibeWatch/Views/HistoryView.swift`
