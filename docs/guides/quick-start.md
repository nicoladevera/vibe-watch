# Vibe Watch - Quick Start Guide

## What You Have Now

A fully functional macOS menu bar app that tracks your "vibe coding" time! 👀

## Running the App

### Option 1: Run from Terminal
```bash
cd /Users/nicoladevera/Documents/GitHub/vibe-watch
./.build/release/VibeWatch
```

### Option 2: Build and Run with Swift
```bash
swift run
```

## What the App Does

1. **Tracks Time**: Monitors when Cursor, Antigravity, or Terminal are running and you're actively coding
2. **Smart Detection**: Only counts time when you're actually active (stops counting after 3 minutes of idle time)
3. **Visual Feedback**: Menu bar icon changes based on how close you are to your daily limit
4. **Historical Data**: Stores all your coding sessions in a local SQLite database

## First Time Setup

1. **Launch the app** - Look for the eye icon in your menu bar (top-right)
2. **Click the icon** - You'll see a dropdown with today's stats
3. **Click "Settings"** - Configure your daily limits:
   - Default: 4 hours on weekdays, 2 hours on weekends
   - Adjust any day to your preference
4. **Start coding!** - The app automatically tracks your time

## Menu Bar Icon States

- **👀 Alert Eyes**: You're good! More than 1 hour remaining
- **😬 Concerned Eyes**: Warning! Less than 1 hour remaining
- **😴 Exhausted Eyes**: You've exceeded your limit (but can keep coding)

## Features to Try

### View History
- Click menu bar icon → "View History"
- See all your past coding sessions
- Export data as CSV or JSON
- Clear all data if needed

### Adjust Settings
- Click menu bar icon → "Settings"
- Set different limits for each day of the week
- Adjust idle threshold (default 3 minutes)

### Weekly Summary
- The dropdown shows a mini bar chart of the last 7 days
- Hover to see hours coded each day

## Data Storage

All data is stored locally at:
```
~/Library/Application Support/VibeWatch/vibewatch.sqlite
```

No internet connection required. No telemetry. Your data stays on your machine.

## Known Limitations (V1)

- **Launch at Login**: UI toggle exists but functionality not yet implemented
- **Calendar Heat Map**: History view shows list only (heat map coming soon)
- **Hourly Activity Chart**: Data is tracked but visualization not yet implemented

## Customization Ideas for Later

1. **Add More Apps**: Track VS Code, Xcode, IntelliJ, etc.
2. **Notifications**: Optional reminders when approaching limit
3. **Break Timers**: Suggest breaks after continuous coding
4. **Themes**: Customize colors and icon styles
5. **Icon Variations**: More expressive eye states or animations

## Troubleshooting

### App Not Detecting My IDE
- Check the process name in Activity Monitor
- Update `AppDetector.swift` to match the exact name
- Rebuild: `swift build`

### Time Not Tracking
- Make sure the app is running (check menu bar)
- Verify you're actually using one of the tracked apps
- Check that you're not idle (move mouse/type something)

### Data Not Saving
- Check permissions for `~/Library/Application Support/`
- Look for error messages in Console.app (filter for "VibeWatch")

## Next Steps

Want to customize further? Check out:
- `docs/product/prd.md` - Full product requirements
- `docs/product/tasks.md` - Implementation checklist
- `README.md` - Architecture overview

Happy vibe coding! 👀✨
