# AndrewsBISUI

A comprehensive World of Warcraft addon for tracking Best-in-Slot (BiS) gear with automatic import from Wowhead guides.

![Version](https://img.shields.io/badge/version-1.1.0-blue)
![WoW](https://img.shields.io/badge/WoW-11.0.2-orange)
![License](https://img.shields.io/badge/license-Free-green)

## ✨ Features

### 📥 **Smart Import System**
- **One-click import** from Wowhead BiS guides (all classes supported!)
- **Automatic slot detection** with proper mapping
- **Alternative items support** (e.g., "Trinket (Alternative)" for backup options)
- **Hero talent support** (San'layn vs Deathbringer for Death Knight, etc.)
- **Enchant tracking** with context (Deathbringer ST, San'layn AoE, etc.)

### 🎯 **Visual Gear Tracking**
- **Interactive character panel** showing all 16 gear slots
- **Real-time equipped detection** (shows green when you have the item)
- **Progress tracking** (e.g., "15/16 items (93%)")
- **Alternative items display** with purple theme and category labels
- **Item icons** with quality colors and hover tooltips

### 🔧 **Powerful Features**
- **Per-spec storage** - Different BiS sets for each specialization
- **Multiple sets** - Save different BiS lists (Raid, M+, PvP, etc.)
- **Frost DK weapon enchants** - Dynamic detection based on talents and weapon type
- **Ctrl+Click** to open Encounter Journal and search for item source
- **Shift+Click** to link items in chat
- **Hold Shift** to view all enchant tooltips at once

### 🎨 **Modern UI**
- **Resizable window** with saved position and size
- **UI scale slider** for personalization
- **Purple-themed alternative items** section
- **Color-coded progress** (gold for in-progress, green for complete)
- **Dark theme** with gold accents

## How to Use

### In-Game Commands

| Command | Description |
|---------|-------------|
| `/bis` or `/bis show` | Open the BiS character panel |
| `/bis import` | Open the import window to add new BiS data |
| `/bis clear` | Clear all BiS data for current spec |
| `/bis help` | Show all available commands |

### Importing BiS Gear

#### Step-by-Step Guide

1. **Find your Wowhead guide**
   - Visit [Wowhead](https://www.wowhead.com/) and navigate to your class/spec BiS guide
   - Example: `https://www.wowhead.com/guide/classes/priest/discipline/bis-gear`

2. **Select the correct tab** (if applicable)
   - Some guides have multiple tabs (San'layn vs Deathbringer, Raid vs M+, etc.)
   - Click the tab you want - this updates the URL with a hash anchor automatically
   - Example: `#bis-items-sanlayn` or `#bis-items-raid`

3. **In-game: Open import window**
   - Type `/bis import` to open the import dialog

4. **Paste the Wowhead URL**
   - Copy the URL from your browser
   - Paste it into the "Wowhead URL" field
   - Click "Generate API URL"

5. **Open the API URL**
   - The addon will generate an API URL
   - Copy it and open it in your web browser
   - Select your role (Tank, DPS, or Healer) for enchants

6. **Copy the import string**
   - The API will display an import string (format: `BIS##...;;ENCHANT##...`)
   - Click "Copy Import String" button

7. **Import into addon**
   - Paste the import string back into the addon's import window
   - Click "Import Items"

8. **Done!**
   - Your BiS items will appear in the character panel
   - Items are automatically saved per-spec

#### What Gets Imported

- **Gear**: All 16 slots (Head, Neck, Shoulders, etc.)
- **Alternative items**: Backup options like "Trinket (Alternative)"
- **Enchants**: Slot-specific enchants with context (hero talent, ST/AoE)
- **Slot mapping**: Automatically maps Wowhead slots to addon slots

#### Hero Talent & Content Type Support

The scraper automatically handles different BiS tables:
- `#bis-items-overall` - Default BiS list
- `#bis-items-sanlayn` - San'layn hero talent (Death Knight)
- `#bis-items-deathbringer` - Deathbringer hero talent (Death Knight)
- `#bis-items-raid` - Raid-specific gear
- `#bis-items-mythic-plus` - Mythic+ specific gear

If no hash is specified, the first table (usually "Overall") is used.

## 🖥️ Setting Up the API Server

The addon requires an API server to scrape Wowhead pages because WoW addons cannot make direct HTTP requests for security reasons.

### Quick Start (Local)

```bash
# 1. Install Python 3.8+ from https://www.python.org/downloads/

# 2. Install dependencies
pip install -r requirements.txt

# 3. Start the server
python api_server.py

# 4. Server runs at http://localhost:5000
```

The addon is pre-configured to use `localhost:5000` by default, so no configuration needed!

### Web Interface

Open `http://localhost:5000` in your browser for a user-friendly interface:
- Paste Wowhead URLs directly
- Select your role (Tank/DPS/Healer)
- Get instant import strings
- No need to use the in-game import dialog

### Deployment (Guild/Group Use)

For sharing with guild members, deploy to a hosting service:

| Service | Cost | Ease | Notes |
|---------|------|------|-------|
| **Railway** | Free tier | ⭐⭐⭐ | Easiest deployment, auto-builds |
| **Heroku** | Free tier | ⭐⭐ | Popular, reliable |
| **DigitalOcean** | $5/month | ⭐⭐ | Full control, VPS |
| **Fly.io** | Free tier | ⭐⭐⭐ | Modern, fast |

After deployment, update the API URL in-game:
```lua
-- Edit this line in AndrewsBISUI.lua (around line 10)
ABIS.Config = {
    apiURL = "https://your-server.railway.app/scrape"
}
```

## 📊 Understanding the UI

### Character Panel

The main UI shows your BiS gear organized by slot:

```
┌────────────────────────────────────────────┐
│  Andrews BiS UI                     [X]    │
├────────────────────────────────────────────┤
│                                            │
│  LEFT COLUMN      RIGHT COLUMN             │
│  ┌─┐ Head         ┌─┐ Legs                │
│  ┌─┐ Neck         ┌─┐ Boots               │
│  ┌─┐ Shoulders    ┌─┐ Ring 1              │
│  ┌─┐ Cloak        ┌─┐ Ring 2              │
│  ┌─┐ Chest        ┌─┐ Trinket 1           │
│  ┌─┐ Wrists       ┌─┐ Trinket 2           │
│  ┌─┐ Hands        ┌─┐ Main Hand           │
│  ┌─┐ Waist        ┌─┐ Off Hand            │
│                                            │
│  Hold Shift to view all enchant tooltips  │
│  Alternative Items: [🟣] [🟣] [🟣]        │
│                    Trinket Finger Weapon   │
│  Progress: 15/16 items (93%)               │
│  [Import] [Clear] [Close]                  │
└────────────────────────────────────────────┘
```

### Item States

- **Green border**: Item is equipped
- **White border**: Item not equipped
- **Purple border**: Alternative item
- **"[In Inventory]"**: Item is in your bags
- **"[Equipped]"**: Item is currently equipped

### Alternative Items Section

Purple-themed items displayed separately at the bottom:
- **Generic replacements**: Can replace any item in that category
- **Example**: "Trinket (Alternative)" works for either Trinket 1 or Trinket 2
- **Hover tooltip**: Shows which slots it can replace
- **Equipped detection**: Checks all valid slots (both trinkets, both rings, etc.)

### Enchants

Each slot shows recommended enchants:
- **Multiple options**: Displays all alternatives (e.g., Razorice vs Stoneskin)
- **Context labels**: Shows when to use (e.g., "Deathbringer ST", "San'layn AoE")
- **Frost DK weapon enchants**: Automatically switches based on talents and weapon type
- **Hold Shift**: View all enchant tooltips simultaneously

### Interactions

| Action | Result |
|--------|--------|
| **Hover** item | Show detailed tooltip |
| **Click** item | Nothing (prevents accidental actions) |
| **Shift+Click** item | Link item in chat |
| **Ctrl+Click** item | Open Encounter Journal and search for source |
| **Hold Shift** | Show all enchant tooltips at once |

## 🔧 Troubleshooting

### API Server Issues

| Problem | Solution |
|---------|----------|
| **"HTTP requests not available"** | Ensure API server is running at `localhost:5000` |
| **Server won't start** | Install dependencies: `pip install -r requirements.txt` |
| **Port 5000 in use** | Change port in `api_server.py` (last line) and update addon config |

### Import Issues

| Problem | Solution |
|---------|----------|
| **"No items found"** | Verify URL is a BiS guide (contains `/guide/classes/`), not gear planner |
| **Wrong items imported** | Make sure you clicked the correct tab on Wowhead before copying URL |
| **Missing alternative items** | These are intentional - not all guides have alternatives |
| **Items show as "?"** | Hover over them to load item data from WoW servers |

### Data Issues

| Problem | Solution |
|---------|----------|
| **Data lost after `/reload`** | Should auto-save per-spec. If not, report as bug |
| **Wrong spec showing** | Use `/bis clear` and re-import for current spec |
| **Multiple sets** | Each import creates a new timestamped set (not yet switchable in UI) |

### Enchant Issues

| Problem | Solution |
|---------|----------|
| **No enchants showing** | Guide may not have enchants table, or enchant URL wasn't provided |
| **Wrong DK weapon enchants** | Frost DK enchants auto-detect talents - change talents to update |
| **Enchant tooltips not showing** | Hold Shift key to view all enchants at once |

## 🎯 Special Class Features

### Frost Death Knight
- **Automatic weapon enchant detection**
- Checks for Shattering Blade talent
- Detects two-handed vs dual-wield
- Shows correct enchants: Razorice/Fallen Crusader/Stoneskin Gargoyle

### All Classes with Hero Talents
- Import different sets for each hero talent path
- URL hash support: `#bis-items-sanlayn`, `#bis-items-deathbringer`
- Each import is spec-specific and saved separately

## 📁 File Structure

```
AndrewsBISUI/
├── AndrewsBISUI.toc       # Addon metadata (version, icon, etc.)
├── AndrewsBISUI.lua       # Main addon code (~2000 lines)
├── api_server.py          # Flask scraper (handles Wowhead parsing)
├── requirements.txt       # Python dependencies (Flask, requests, etc.)
├── README.md              # This documentation
├── CLAUDE.md              # Project instructions for AI assistance
├── CREATE_ICON.md         # Icon creation guide for CurseForge
├── ICON_OPTIONS.md        # Alternative icon suggestions
└── Ace3/                  # UI library (optional, for future enhancements)
```

## 🤝 Contributing

Contributions welcome! Areas for improvement:

**Addon**
- Multi-set switching UI (currently saves all imports but can't switch)
- Gem recommendations display
- Socket status tracking
- Export to shopping list format

**API Server**
- Support for more guide formats (alternative websites)
- Caching for faster repeated scrapes
- Gem data extraction
- Alternative language support

**Both**
- Gear upgrade path suggestions
- Integration with SimulationCraft
- In-game notes per item
- Share sets with guild members

## 📜 License

Free to use and modify for personal and guild use.

## 🙏 Credits

- **Wowhead** for BiS guides and data
- **Flask** for the Python web framework
- **Ace3** for UI components (optional dependency)

## 📞 Support

- **Issues**: Report bugs on GitHub
- **Feature Requests**: Open an issue with your idea
- **Questions**: Check this README first, then ask in issues

---

**Made with ❤️ for the WoW community**
