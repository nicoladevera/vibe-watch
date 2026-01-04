# Scripts

Development and utility scripts for Vibe Watch.

## process_icons.py

Processes eye icon images for use in the menu bar.

**Features:**
- Auto-detects and removes checkered/gray backgrounds
- Makes icons square to prevent vertical stretching in the menu bar
- Crops to remove excess transparent space
- Centers eye content with transparent padding

**Usage:**
```bash
# From repository root
python3 scripts/process_icons.py
```

**Input:** Processes original icon files from `Sources/VibeWatch/Resources/`:
- `alert-original.png`
- `concerned-original.png`
- `exhausted-original.png`

**Output:** Generates processed icons:
- `alert.png`
- `concerned.png`
- `exhausted.png`

**Requirements:**
```bash
pip3 install Pillow
```
