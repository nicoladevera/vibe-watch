# Product Requirements Document: Vibe Watch

## 1. Introduction/Overview

**Vibe Watch** is a macOS menu bar application that tracks the amount of time a user spends "vibe coding" each day. Vibe coding is defined as actively using coding-related applications (Cursor, Antigravity, Terminal) while the system detects user activity (not idle).

The app provides a playful, at-a-glance indicator in the menu bar that changes expression based on how close the user is to their self-imposed daily coding limit. This helps developers maintain healthy work-life balance by making them aware of their coding time without being intrusive or blocking their workflow.

**Key Principle:** All time calculations are performed locally using native macOS commands—no AI or external API calls are used.

## 2. Goals

1. **Track vibe coding time accurately** by detecting when coding apps (Cursor, Antigravity, Terminal) are running AND the user is actively interacting with the system.
2. **Provide instant visual feedback** via a playful menu bar icon that reflects the user's proximity to their daily limit.
3. **Enable customizable daily limits** with different thresholds for weekdays vs. weekends.
4. **Maintain historical records** of daily coding time indefinitely for self-reflection and pattern recognition.
5. **Be non-intrusive**—never interrupt or block ongoing work, even when limits are exceeded.

## 3. User Stories

### US-1: At-a-Glance Status
> As a developer, I want to glance at my menu bar and immediately know how my vibe coding time compares to my daily limit, so I can make informed decisions about taking breaks.

### US-2: Set Personal Limits
> As a developer, I want to set different coding time limits for weekdays and weekends, so I can balance productivity during the work week with rest on weekends.

### US-3: View Today's Progress
> As a developer, I want to click the menu bar icon and see my current coding time, remaining time, and a mini weekly summary, so I have context without opening a full dashboard.

### US-4: Review Historical Data
> As a developer, I want to view my coding history with daily totals, per-app breakdowns, and hourly activity visualizations, so I can identify patterns and adjust my habits.

### US-5: Gentle Limit Warnings
> As a developer, I want the app to visually warn me as I approach my limit (without interrupting my work), so I can wrap up naturally rather than being cut off.

## 4. Functional Requirements

### 4.1 Time Tracking

| ID | Requirement |
|----|-------------|
| FR-1 | The system must detect when the following applications are running: **Cursor**, **Antigravity**, and **Terminal**. |
| FR-2 | The system must detect user activity (keyboard/mouse input) using native macOS commands (e.g., `ioreg` to check `HIDIdleTime`). |
| FR-3 | The system must only count time as "vibe coding" when at least one tracked app is running AND the user has been active within the last **3 minutes** (configurable idle threshold). |
| FR-4 | The system must track time in 1-minute increments. |
| FR-5 | The tracking day resets at **midnight (00:00)** local time and ends at **23:59**. |
| FR-6 | The system must calculate and display time in hours and minutes (e.g., "3h 42m"). |
| FR-7 | All time tracking must be performed locally without any external API calls or AI services. |

### 4.2 Menu Bar Icon

| ID | Requirement |
|----|-------------|
| FR-8 | The app must display a **playful icon** in the macOS menu bar at all times when running. |
| FR-9 | The icon must change based on proximity to the daily limit: |
| | • **Happy/Relaxed face** 😊 — More than 1 hour remaining before limit |
| | • **Warning/Concerned face** 😬 — Within 1 hour of limit |
| | • **Exhausted/Stressed face** 😵 — Limit exceeded (humorous, not alarming) |
| FR-10 | Icon transitions must be smooth and not disrupt the user's focus. |
| FR-11 | The icon should optionally display the current time tracked (e.g., "3h") next to or below the face icon (user preference). |

### 4.3 Menu Bar Dropdown

| ID | Requirement |
|----|-------------|
| FR-12 | Clicking the menu bar icon must open a dropdown panel. |
| FR-13 | The dropdown must display: |
| | • **Today's total vibe coding time** (e.g., "Today: 3h 42m") |
| | • **Daily limit and remaining time** (e.g., "Limit: 4h · 18m remaining") |
| | • **Mini weekly summary** showing the last 7 days as a simple bar chart or list |
| FR-14 | The dropdown must include a **"View History"** button to access detailed historical data. |
| FR-15 | The dropdown must include a **"Settings"** button/gear icon to access configuration. |
| FR-16 | The dropdown must include a **"Quit"** option. |

### 4.4 Daily Limits Configuration

| ID | Requirement |
|----|-------------|
| FR-17 | The system must allow users to set **separate daily limits for each day of the week**. |
| FR-18 | Default limits must be: |
| | • **Weekdays (Mon–Fri):** 4 hours |
| | • **Weekends (Sat–Sun):** 2 hours |
| FR-19 | Limits must be adjustable in **15-minute increments** from 0 to 12 hours. |
| FR-20 | Limit changes must take effect immediately for the current day. |

### 4.5 Historical Data & Visualization

| ID | Requirement |
|----|-------------|
| FR-21 | The system must store daily vibe coding records **indefinitely** (until manually cleared by user). |
| FR-22 | Each daily record must include: |
| | • **Date** |
| | • **Total time** |
| | • **Breakdown by application** (e.g., Cursor: 2h 30m, Antigravity: 45m, Terminal: 1h 12m) |
| | • **Hourly activity data** (which hours of the day had coding activity) |
| FR-23 | The history view must display: |
| | • **Daily totals** in a list or calendar format |
| | • **Per-app breakdown** for each day |
| | • **Hourly activity chart** showing when coding occurred throughout the day |
| FR-24 | The system must allow users to **export** historical data (CSV or JSON format). |
| FR-25 | The system must allow users to **clear** historical data (with confirmation). |

### 4.6 System Integration

| ID | Requirement |
|----|-------------|
| FR-26 | The app must launch automatically on system startup (optional, user-configurable). |
| FR-27 | The app must continue tracking when the user switches between desktops/spaces. |
| FR-28 | The app must handle system sleep/wake gracefully (pause tracking during sleep, resume on wake). |
| FR-29 | The app must persist data locally (e.g., SQLite, JSON file, or macOS UserDefaults). |

## 5. Non-Goals (Out of Scope)

The following are explicitly **not** part of this initial release:

- ❌ **Blocking or restricting access** to coding apps when limit is exceeded
- ❌ **Notifications or alerts** (the icon change is the only indicator)
- ❌ **Cloud sync** or multi-device data sharing
- ❌ **Tracking non-coding apps** (browsers, Slack, etc.)
- ❌ **Pomodoro timer** or break reminder functionality
- ❌ **AI-powered insights** or suggestions
- ❌ **iOS/iPadOS companion app**
- ❌ **Team/organizational features**

## 6. Design Considerations

### 6.1 Menu Bar Icon Design

The icon should be **playful and expressive** while fitting the macOS menu bar aesthetic. Instead of using standard emoji, consider these creative directions:

**🔄 Design Update (V1.1):** The design evolved from owl icons to **expressive eye icons** for better menu bar visibility and clarity. Eyes are simpler, scale better at small sizes, and clearly convey the three emotional states (alert, concerned, exhausted) without excessive detail.

**✨ Original V1 Decision: Going with the Owl concept** - The owl initially aligned perfectly with the "Vibe Watch" name and developer culture (late-night coding), has expressive features that work well at small sizes, and provides an intuitive visual progression through the three states. However, testing showed that owl details were too complex for menu bar display, leading to the simplified eye icon approach.

#### Recommended Icon Concepts:

**Option 1: Watch Character/Mascot**
- A friendly wristwatch or stopwatch character with different expressions
- Well within limit: Wide awake eyes, energetic pose
- Warning: Slightly worried expression, sweat drop
- Over limit: Tired/sleepy eyes, yawning

**Option 2: Clock with Personality**
- Analog clock face with anthropomorphic features
- Well within limit: Bright, smiling clock hands
- Warning: Clock hands forming a concerned expression
- Over limit: Clock hands drooping down tiredly, maybe with "Zzz"

**Option 3: Animal Timer Buddy** ⭐ *Selected for V1*
- Consider animals associated with time/work patterns:
  - **Owl** ✅ *V1 Choice*: Wise coding companion (alert → concerned → sleepy)
    - **Alert state**: Wide open eyes, upright posture, bright and focused
    - **Concerned state**: Slightly narrowed eyes, subtle worry lines, one eye slightly bigger
    - **Sleepy/Exhausted state**: Half-closed droopy eyes, tilted head, "zzz" or yawning
  - **Cat**: Playful energy tracker (energetic → cautious → napping)
  - **Hamster/wheel**: Activity metaphor (running happily → slowing → exhausted)

**Option 4: Progress Ring with Face**
- Circular progress indicator showing time remaining with a face in the center
- Visual double-duty: shows both emotion and progress at a glance

#### Technical Icon Requirements:
- Must be legible at 16x16 and 22x22 pixels (standard menu bar sizes)
- Should support both light and dark macOS menu bar themes
- Consider SF Symbols as base with custom overlay for expressions
- Recommend **0.3-second fade transition** between states (smooth but not distracting)

#### Design Resources & V1.1 Implementation (Current):

**Eye Icon Implementation:**
- **Current Design**: Simple, expressive eye icons showing three emotional states
- **Icon Files**:
  - `alert.png` - Wide open, alert eyes (>1h remaining)
  - `concerned.png` - Worried/concerned eyes (<1h remaining)
  - `exhausted.png` - Tired/sleepy eyes (over limit)
- **Technical Specs**:
  - Format: PNG with transparent background
  - Size: Square format (preserves aspect ratio at menu bar size)
  - Color: Monochrome/template images (auto-adapt to light/dark menu bars)
  - Menu bar size: 18×18 pixels
- **Benefits**: Clearer visibility at small sizes, simpler design, better menu bar integration

#### Original V1 Owl Design (Historical):

**Owl Icon Sources (for V1):**
- **Flaticon Owl Collections**: 
  - Search "owl emotions" or "owl sleeping" for consistent icon sets
  - Recommended: Look for sets with all three states in matching style
  - License: Free for personal/commercial with attribution (or Premium for no attribution)
  
- **The Noun Project**: 
  - Search "owl alert", "owl worried", "owl sleeping"
  - Typically offers consistent design language across similar icons
  - License options available

- **Custom Owl Icon Specifications for Designer/Developer:**
  - Style: Minimalist, friendly, not overly detailed
  - Size: Design at 64x64px, export at 16x16, 32x32, 64x64 (for Retina)
  - Format: SVG preferred for scalability, PNG fallback
  - Color: Monochrome design that works in both light/dark menu bars
  - States needed:
    1. **Alert Owl**: Wide circular eyes, upright ear tufts, facing forward
    2. **Concerned Owl**: One eye slightly larger, subtle sweat drop or worry line
    3. **Sleepy Owl**: Half-closed eyes, tilted head, optional "zzz"

**General Resources:**
- [SF Symbols](https://developer.apple.com/sf-symbols/) for native macOS integration
- [Badgeify](https://badgeify.app) for menu bar icon implementation
- Consider commissioning a designer on Fiverr/Upwork for a consistent 3-icon owl set if free options don't match

| State | Visual Concept | Color Suggestion |
|-------|----------------|------------------|
| Happy (>1h remaining) | Energetic/alert expression, bright eyes | Green tint or neutral |
| Warning (<1h remaining) | Concerned expression, subtle alert indicator | Yellow/amber tint |
| Exhausted (over limit) | Tired/sleepy expression, yawning, droopy eyes | Red tint (subtle, not alarming) |

### 6.2 Dropdown Panel Design

- Clean, minimal design consistent with macOS system UI
- Use SF Symbols where appropriate
- Weekly summary should be a compact horizontal bar chart
- Settings should open in a separate, larger window

### 6.3 History View Design

- Consider a calendar heat-map view (similar to GitHub contribution graph)
- Hourly breakdown could be a 24-hour timeline with colored blocks
- Per-app breakdown as horizontal stacked bars or pie chart

## 7. Technical Considerations

### 7.1 Technology Stack Suggestions

- **Language:** Swift (native macOS development)
- **Framework:** SwiftUI for UI, AppKit for menu bar integration
- **Data Storage:** SQLite (via GRDB or similar) or Core Data for historical records

### 7.2 macOS Commands for Detection

**Detecting running applications:**
```bash
# List running apps
osascript -e 'tell application "System Events" to get name of every process where background only is false'

# Or using pgrep
pgrep -l "Cursor|Terminal|Antigravity"
```

**Detecting system idle time:**
```bash
# Returns idle time in nanoseconds
ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print $NF/1000000000; exit}'
```

### 7.3 Polling Interval

- Check app status and idle time every **30 seconds** to balance accuracy with system resource usage
- Accumulate active time in memory, persist to storage every **5 minutes**

### 7.4 App Detection Notes

- "Antigravity" — Process name verified (Google's IDE)
- Terminal — Default macOS Terminal app
- Cursor — Verify process name (likely `Cursor` or `Cursor Helper`)

## 8. Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **Tracking Accuracy** | ±2 minutes per hour | Compare with manual time tracking over 1 week |
| **User Awareness** | User checks menu bar icon 3+ times per day | Optional anonymous usage analytics (opt-in) |
| **Limit Adherence** | User stays within limit 70% of days | Historical data analysis |
| **App Stability** | Zero crashes per week | Crash reporting |
| **Resource Usage** | <1% CPU, <50MB RAM | Activity Monitor profiling |

## 9. Open Questions

### ✅ All Questions Resolved

1. **Cursor process name**: ✅ **RESOLVED** - Process name is "Cursor" (capital C, lowercase "ursor")

2. **Multiple displays**: ✅ **RESOLVED** - YES, track time if coding apps are on secondary display while browsing on primary, as long as user is active and app is running

3. **Icon design**: ✅ **RESOLVED** - V1.1 uses custom eye icons (simplified from original owl concept for better menu bar visibility)

4. **Data location**: ✅ **RESOLVED** - Store in `~/Library/Application Support/VibeWatch/` WITHOUT iCloud backup
   - Standard macOS app location
   - Better performance (no sync overhead)
   - User privacy (data stays local)
   - Manual export to CSV/JSON available for backup
   - iCloud backup can be V2 feature if users request it

5. **Configurable apps**: ✅ **RESOLVED** - V1: Hardcoded tracking for Cursor, Antigravity, Terminal only
   - V2 Feature: Allow users to add/remove custom apps via Settings UI
   - This keeps V1 simple and focused

---

**PRD Status**: ✅ **COMPLETE** - All requirements defined, all questions resolved

*Document created: January 3, 2026*  
*Last updated: January 3, 2026*  
*Status: Approved — Ready for Implementation*

