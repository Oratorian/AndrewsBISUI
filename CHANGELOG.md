# Changelog

All notable changes to AndrewsBISUI will be documented in this file.

## [1.1.0] - 2025-01-29

### Added
- **Alternative items support** - Handles "Trinket (Alternative)", "Finger (Alternative)", etc.
  - Purple-themed display section at bottom of character panel
  - Category labels showing item type (Trinket, Finger, Weapon)
  - Smart equipped detection across all valid slots
  - Can replace any item in that category

- **Enhanced .toc file**
  - Colored title: Gold/Green/Blue text
  - Custom icon (purple book) instead of red "?"
  - Localized descriptions (German, Spanish, French)
  - Metadata for CurseForge/WoWInterface

- **Improved Wowhead scraping**
  - Fixed regex to handle bold tags `[b]...[/b]` in slot names
  - Fixed support for numbered slots (Ring 1, Ring 2, Trinket 1, Trinket 2)
  - Hash anchor support for hero talents and content types
  - Handles all classes universally

- **Comprehensive documentation**
  - Completely rewritten README with visual guides
  - Step-by-step import instructions
  - UI interaction guide with ASCII art
  - Troubleshooting tables
  - Icon creation guide for CurseForge

### Fixed
- Data persistence bug where BiS data wouldn't load after `/reload`
  - Now properly detects spec in PLAYER_ENTERING_WORLD
  - Reloads data when spec changes from default to actual spec

- Trinket/Ring equipped detection
  - Now checks both ring slots and both trinket slots
  - Prevents false "[In Inventory]" when equipped in alternate slot

- Frost Death Knight weapon enchants
  - Dynamic detection based on Shattering Blade talent
  - Auto-detects two-handed vs dual-wield
  - Shows correct enchants: Razorice/Fallen Crusader/Stoneskin Gargoyle
  - Fixed Off Hand enchant icon not displaying

- Discipline Priest and other class support
  - Fixed regex pattern to handle `[b]` bold tags around slot names
  - Added support for digits in slot names
  - Works with all Wowhead guide formats

### Changed
- API server now returns items with slot information
  - Format: `{"id": 237709, "slot": "Head"}`
  - Alternative items marked: `{"id": 242396, "slot": "Trinket (Alternative)", "isAlternative": true}`

- Removed all debug output from production code
  - Cleaner chat output
  - Better performance

- Improved API documentation
  - Clearer instructions about hash anchors
  - User-friendly: "Just click the tab you want on Wowhead"

## [1.0.0] - Initial Release

### Features
- Basic BiS gear import from Wowhead
- Character panel with 16 gear slots
- Per-spec storage
- Enchant tracking
- Progress tracking
- Frost DK weapon enchant support
