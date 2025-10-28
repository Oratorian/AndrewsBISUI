#!/usr/bin/env python3
"""
Flask API Server for AndrewsBISUI
Scrapes Wowhead BiS pages and returns item IDs as JSON
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import re
import requests
from urllib.parse import unquote

app = Flask(__name__)
CORS(app)  # Enable CORS for cross-origin requests

def scrape_wowhead_items(url):
    """
    Scrape item IDs with slots from a Wowhead BiS gear guide URL

    Supports hash anchors to select specific BiS tables:
    - #bis-items-overall (default)
    - #bis-items-sanlayn (Death Knight hero talent)
    - #bis-items-deathbringer (Death Knight hero talent)
    - #bis-items-raid
    - #bis-items-mythic-plus

    Returns a list of dicts with 'slot' and 'id' keys
    Example: [{'slot': 'Head', 'id': 237628}, {'slot': 'Trinket (Alternative)', 'id': 242396}, ...]
    """
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Sec-Fetch-User': '?1',
            'Cache-Control': 'max-age=0',
        }

        response = requests.get(url, headers=headers, timeout=15, allow_redirects=True)
        response.raise_for_status()

        # Check if we got redirected
        if response.url != url:
            pass  # Silently handle redirects

        html = response.text

        # The BiS table is inside a JavaScript WH.markup.printHtml("...") call
        # Extract the content from inside that JavaScript string
        markup_match = re.search(r'WH\.markup\.printHtml\("(.+?)"\s*,\s*"guide-body"', html, re.DOTALL)
        if markup_match:
            # Extract the BBCode content from the JavaScript string
            bbcode_content = markup_match.group(1)
            print(f"Extracted {len(bbcode_content)} chars of BBCode content from JavaScript")

            # The JavaScript string has escaped characters - unescape them
            bbcode_content = bbcode_content.replace(r'\/', '/')
            bbcode_content = bbcode_content.replace(r'\"', '"')

            # Extract the correct table based on URL hash
            # Common hash values:
            # - #bis-items-overall (default for most classes) -> first table
            # - #bis-items-sanlayn (Death Knight hero talent) -> first table
            # - #bis-items-deathbringer (Death Knight hero talent) -> second table
            # - #bis-items-raid, #bis-items-mythic-plus -> additional tables

            table_index = 0  # Default to first table (usually "Overall")

            if '#bis-items-deathbringer' in url.lower():
                table_index = 1
                print("Extracting second table (Deathbringer)")
            elif '#bis-items-sanlayn' in url.lower():
                table_index = 0
                print("Extracting first table (San'layn)")
            elif '#bis-items-overall' in url.lower():
                table_index = 0
                print("Extracting first table (Overall)")
            elif '#bis-items-raid' in url.lower():
                table_index = 2
                print("Extracting third table (Raid)")
            elif '#bis-items-mythic-plus' in url.lower() or '#bis-items-mythic+' in url.lower():
                table_index = 3
                print("Extracting fourth table (Mythic+)")
            else:
                print("No hash specified, extracting first table (Overall)")

            # Find all [table]...[/table] sections
            all_tables = re.findall(r'\[table[^\]]*\](.*?)\[/table\]', bbcode_content, re.DOTALL)
            print(f"Found {len(all_tables)} tables in BBCode")

            if table_index < len(all_tables):
                bbcode_content = all_tables[table_index]
                print(f"Extracted table {table_index + 1}: {len(bbcode_content)} chars")
            elif len(all_tables) > 0:
                bbcode_content = all_tables[0]
                print(f"Requested table {table_index + 1} not found, using first table")
        else:
            print("Could not find WH.markup.printHtml content")
            bbcode_content = html  # Fallback to raw HTML

        # Pattern matches: [td]SlotName[/td][td]...[item=12345 bonus=...]...[/td]
        # Need to handle optional [b] bold tags around slot names, [color=...] tags, and any other content before [item=
        # Slot names can include: letters, spaces, digits (for "Ring 1", "Trinket 2"), parentheses (for "Trinket (alt)")
        # Note: We don't match [tr] prefix because rows may or may not include it
        table_row_pattern = r'\[td\](?:\[b\])?([ A-Za-z\d\s()]+?)(?:\[/b\])?\[/td\]\[td\].*?\[item=(\d+)'

        matches = re.findall(table_row_pattern, bbcode_content, re.DOTALL)

        print(f"Found {len(matches)} item rows in BiS table")
        if matches:
            print(f"First 3 matches: {matches[:3]}")

        items_with_slots = []

        # Map Wowhead slot names to our slot names
        slot_name_map = {
            'Head': 'Head',
            'Neck': 'Neck',
            'Shoulders': 'Shoulders',
            'Cloak': 'Cloak',
            'Chest': 'Chest',
            'Wrist': 'Wrists',
            'Wrists': 'Wrists',
            'Gloves': 'Hands',
            'Hands': 'Hands',
            'Belt': 'Waist',
            'Waist': 'Waist',
            'Legs': 'Legs',
            'Boots': 'Feet',
            'Feet': 'Feet',
            'Ring': 'Finger 1',  # First ring found
            'Ring 1': 'Finger 1',
            'Ring 2': 'Finger 2',
            'Trinket': 'Trinket 1',  # First trinket found
            'Trinket 1': 'Trinket 1',
            'Trinket 2': 'Trinket 2',
            'Weapon': 'Main Hand',
            'Main Hand': 'Main Hand',
            'Off Hand': 'Off Hand',
            'Offhand': 'Off Hand',
        }

        ring_count = 0
        trinket_count = 0

        for slot_name, item_id in matches:
            slot_name = slot_name.strip()

            # Track if this is an alternative item
            is_alternative = False
            base_slot_name = slot_name

            # Handle alternative/backup slots (e.g., "Trinket (alt)", "Alternative")
            if '(alt)' in slot_name.lower():
                is_alternative = True
                # Extract the base slot name (e.g., "Trinket" from "Trinket (alt)")
                base_slot_name = re.sub(r'\s*\(alt\)', '', slot_name, flags=re.IGNORECASE).strip()
            elif slot_name.lower() == 'alternative':
                # This is typically for weapons - use the previous weapon slot
                is_alternative = True
                base_slot_name = 'Weapon'

            # Handle multiple rings/trinkets
            if base_slot_name == 'Ring':
                if is_alternative:
                    mapped_slot = 'Finger (Alternative)'
                else:
                    ring_count += 1
                    mapped_slot = f'Finger {ring_count}'
            elif base_slot_name == 'Trinket':
                if is_alternative:
                    mapped_slot = 'Trinket (Alternative)'
                else:
                    trinket_count += 1
                    mapped_slot = f'Trinket {trinket_count}'
            elif base_slot_name == 'Weapon':
                if is_alternative:
                    mapped_slot = 'Main Hand (Alternative)'
                else:
                    mapped_slot = slot_name_map.get(base_slot_name, base_slot_name)
            else:
                mapped_slot = slot_name_map.get(base_slot_name, base_slot_name)
                if is_alternative:
                    mapped_slot = f'{mapped_slot} (Alternative)'

            # Add all items, including alternatives
            items_with_slots.append({
                'slot': mapped_slot,
                'id': int(item_id)
            })
            print(f"Added: {mapped_slot} -> {item_id}")

        return items_with_slots

    except Exception as e:
        return []

def scrape_wowhead_enchants(url):
    """
    Scrape enchant IDs from a Wowhead enchants guide URL
    Returns list of enchant spell IDs (one per slot)
    """
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Sec-Fetch-User': '?1',
            'Cache-Control': 'max-age=0',
        }

        response = requests.get(url, headers=headers, timeout=15, allow_redirects=True)
        response.raise_for_status()

        # Check if we got redirected
        if response.url != url:
            pass  # Silently handle redirects

        html = response.text

        # Extract ALL tables (not just the first one)
        # This handles cases where weapon enchants are in a separate table (e.g., Frost DK)
        all_tables = re.findall(r'<table[^>]*>(.*?)</table>', html, re.DOTALL | re.IGNORECASE)

        if not all_tables:
            return []

        # Parse each row to extract slot and enchant ID
        enchants_with_slots = []

        # Define valid enchantable slots (exclude consumables like flasks, potions, food, etc.)
        valid_enchant_slots = {
            'Weapon', 'Main Hand', 'Off Hand', 'Cloak', 'Chest', 'Bracers', 'Wrists',
            'Legs', 'Boots', 'Hands', 'Ring', 'Ring - Regular', 'Ring - Cursed',
            'Shattering Blade', 'Two-Hand', 'All other builds'  # DK weapon build names
        }

        # Process all tables
        for table_html in all_tables:
            # Split table into rows
            rows = re.findall(r'<tr>(.*?)</tr>', table_html, re.DOTALL | re.IGNORECASE)

            for i, row in enumerate(rows):
                # Skip header rows (contains <b>Slot</b>, <b>Build</b>, <b>Runeforge</b>, etc.)
                if '<b>Slot</b>' in row or '<b>Best' in row or '<b>Build</b>' in row or '<b>Runeforge</b>' in row:
                    continue

                # Extract all <td> cells from the row
                cells = re.findall(r'<td[^>]*>(.*?)</td>', row, re.DOTALL | re.IGNORECASE)

                if len(cells) < 2:
                    continue

                # First cell is the slot/build name
                slot_cell = cells[0]
                slot_name = re.sub(r'<[^>]+>', '', slot_cell).strip()

                # Skip empty slot names or non-enchant slots (flasks, potions, food, gems, etc.)
                if not slot_name or slot_name not in valid_enchant_slots:
                    continue

                # Second cell contains the enchant links
                enchant_cell = cells[1]

                # Split cell by <br> to get individual enchant options
                enchant_options = re.split(r'<br\s*/?>', enchant_cell, flags=re.IGNORECASE)

                # Collect ALL enchant options with their context (Hero Talent, ST/AoE, etc.)
                enchant_list = []

                for option in enchant_options:
                    # Look for spell ID or item ID
                    spell_match = re.search(r'spell[=/](\d{5,7})', option)
                    item_match = re.search(r'item[=/](\d{5,7})', option)

                    enchant_id = None
                    if spell_match:
                        enchant_id = int(spell_match.group(1))
                    elif item_match:
                        enchant_id = int(item_match.group(1))

                    if not enchant_id:
                        continue

                    # Extract context from parentheses like "(Deathbringer ST)" or "(San'layn)"
                    # Pattern: </a> ( ... text ... ) at end of line
                    context = ""
                    context_match = re.search(r'</a>\s*\((.*?)\)\s*$', option, re.DOTALL)
                    if context_match:
                        raw_context = context_match.group(1)
                        # Clean up: remove HTML tags, &nbsp;, normalize whitespace
                        context = re.sub(r'<[^>]+>', '', raw_context)  # Remove HTML tags
                        context = re.sub(r'&nbsp;', ' ', context)  # Replace &nbsp; with space
                        context = re.sub(r'\s+', ' ', context).strip()  # Normalize whitespace

                    enchant_list.append({
                        'id': enchant_id,
                        'context': context
                    })

                if not enchant_list:
                    continue

                # Store all enchant options for this slot
                enchants_with_slots.append({
                    'slot': slot_name,
                    'enchants': enchant_list  # List of {id, context} objects
                })

        return enchants_with_slots

    except Exception as e:
        return []

def generate_enchant_url(bis_url):
    """
    Convert a BiS gear URL to an enchants URL
    Example: .../bis-gear -> .../enchants-gems-pve-tank
    """
    # Replace bis-gear with enchants pattern
    if 'bis-gear' in bis_url:
        # Determine if it's tank, healer, or dps from URL or default to general
        if 'tank' in bis_url.lower():
            return bis_url.replace('bis-gear', 'enchants-gems-pve-tank')
        elif 'heal' in bis_url.lower():
            return bis_url.replace('bis-gear', 'enchants-gems-pve-healer')
        else:
            return bis_url.replace('bis-gear', 'enchants-gems-pve-dps')
    return None

@app.route('/')
def home():
    """Home page with role selection"""
    return """
    <html>
    <head>
        <title>Andrews BiS & Enchantment UI - Scraper</title>
        <meta charset="UTF-8">
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: 'Segoe UI', Arial, sans-serif;
                background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
                color: #e0e0e0;
                min-height: 100vh;
                padding: 20px;
            }

            .container {
                max-width: 900px;
                margin: 0 auto;
            }

            .header {
                text-align: center;
                padding: 40px 20px;
                background: linear-gradient(135deg, #0f3460 0%, #16213e 100%);
                border-radius: 10px;
                border: 2px solid #ffd700;
                box-shadow: 0 0 30px rgba(255, 215, 0, 0.3);
                margin-bottom: 30px;
            }

            h1 {
                color: #ffd700;
                font-size: 2.5em;
                text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
                margin-bottom: 10px;
            }

            .subtitle {
                color: #a0a0a0;
                font-size: 1.1em;
            }

            .card {
                background: rgba(22, 33, 62, 0.8);
                border: 2px solid #533e2d;
                border-radius: 10px;
                padding: 30px;
                margin-bottom: 20px;
                box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
            }

            .card h2 {
                color: #ffd700;
                margin-bottom: 20px;
                font-size: 1.5em;
            }

            .input-group {
                margin-bottom: 20px;
            }

            label {
                display: block;
                color: #ffd700;
                margin-bottom: 8px;
                font-weight: bold;
            }

            input[type="text"] {
                width: 100%;
                padding: 12px;
                background: rgba(15, 52, 96, 0.8);
                border: 2px solid #533e2d;
                border-radius: 5px;
                color: #fff;
                font-size: 1em;
                transition: all 0.3s;
            }

            input[type="text"]:focus {
                outline: none;
                border-color: #ffd700;
                box-shadow: 0 0 10px rgba(255, 215, 0, 0.3);
            }

            .btn {
                padding: 12px 30px;
                background: linear-gradient(135deg, #ffd700 0%, #ffed4e 100%);
                color: #1a1a2e;
                border: 2px solid #b8960b;
                border-radius: 5px;
                font-size: 1.1em;
                font-weight: bold;
                cursor: pointer;
                transition: all 0.3s;
                text-transform: uppercase;
                letter-spacing: 1px;
            }

            .btn:hover {
                background: linear-gradient(135deg, #ffed4e 0%, #ffd700 100%);
                box-shadow: 0 0 20px rgba(255, 215, 0, 0.5);
                transform: translateY(-2px);
            }

            .btn:active {
                transform: translateY(0);
            }

            .role-buttons {
                display: flex;
                gap: 15px;
                justify-content: center;
                margin-top: 20px;
            }

            .btn-role {
                flex: 1;
                padding: 20px;
                font-size: 1.2em;
                border-radius: 8px;
                transition: all 0.3s;
            }

            .btn-tank {
                background: linear-gradient(135deg, #c77e23 0%, #ffa500 100%);
                border-color: #8b5a00;
            }

            .btn-tank:hover {
                background: linear-gradient(135deg, #ffa500 0%, #c77e23 100%);
                box-shadow: 0 0 20px rgba(255, 165, 0, 0.5);
            }

            .btn-dps {
                background: linear-gradient(135deg, #c41e3a 0%, #ff3355 100%);
                border-color: #8b0000;
            }

            .btn-dps:hover {
                background: linear-gradient(135deg, #ff3355 0%, #c41e3a 100%);
                box-shadow: 0 0 20px rgba(255, 51, 85, 0.5);
            }

            .btn-healer {
                background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%);
                border-color: #1e7e34;
            }

            .btn-healer:hover {
                background: linear-gradient(135deg, #27ae60 0%, #2ecc71 100%);
                box-shadow: 0 0 20px rgba(46, 204, 113, 0.5);
            }

            .btn-copy {
                padding: 8px 20px;
                background: linear-gradient(135deg, #4a90e2 0%, #357abd 100%);
                color: white;
                border: 2px solid #2c5f8d;
                margin-left: 10px;
            }

            .btn-copy:hover {
                background: linear-gradient(135deg, #357abd 0%, #4a90e2 100%);
            }

            #result {
                background: rgba(15, 52, 96, 0.6);
                border: 2px solid #533e2d;
                border-radius: 5px;
                padding: 20px;
                margin-top: 20px;
                display: none;
            }

            #result.success {
                border-color: #4CAF50;
                background: rgba(76, 175, 80, 0.1);
            }

            #result.error {
                border-color: #f44336;
                background: rgba(244, 67, 54, 0.1);
            }

            .result-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 15px;
                padding-bottom: 15px;
                border-bottom: 1px solid #533e2d;
            }

            .result-title {
                color: #ffd700;
                font-size: 1.2em;
                font-weight: bold;
            }

            .item-count {
                color: #4CAF50;
                font-size: 1.1em;
            }

            .item-ids {
                background: rgba(0, 0, 0, 0.3);
                padding: 15px;
                border-radius: 5px;
                font-family: 'Courier New', monospace;
                color: #4CAF50;
                font-size: 1.1em;
                word-break: break-all;
                line-height: 1.6;
            }

            .loading {
                text-align: center;
                color: #ffd700;
                font-size: 1.2em;
            }

            .info-section {
                background: rgba(15, 52, 96, 0.4);
                border-left: 4px solid #ffd700;
                padding: 15px;
                margin-top: 20px;
                border-radius: 5px;
            }

            .info-section h3 {
                color: #ffd700;
                margin-bottom: 10px;
            }

            .info-section p {
                color: #b0b0b0;
                line-height: 1.6;
            }

            code {
                background: rgba(0, 0, 0, 0.3);
                padding: 3px 8px;
                border-radius: 3px;
                color: #4a90e2;
                font-family: 'Courier New', monospace;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>⚔️ Andrews BiS & Enchantment UI Scraper ⚔️</h1>
                <p class="subtitle">Extract Best-in-Slot & Enchantment IDs from Wowhead guides</p>
            </div>

            <div class="card">
                <h2>🔍 Scrape Wowhead Guide</h2>
                <div class="input-group">
                    <label for="bisUrl">Wowhead BiS Gear URL:</label>
                    <input type="text" id="bisUrl" placeholder="https://www.wowhead.com/guide/classes/.../bis-gear"
                           value="https://www.wowhead.com/guide/classes/priest/discipline/bis-gear">
                </div>

                <div class="input-group">
                    <label>Select Role for Enchants:</label>
                    <div class="role-buttons">
                        <button class="btn btn-role btn-tank" onclick="scrapeRole('tank')">
                            🛡️ Tank
                        </button>
                        <button class="btn btn-role btn-dps" onclick="scrapeRole('dps')">
                            ⚔️ DPS
                        </button>
                        <button class="btn btn-role btn-healer" onclick="scrapeRole('healer')">
                            ✨ Healer
                        </button>
                    </div>
                </div>

                <div id="result">
                    <div class="result-header">
                        <span class="result-title" id="result-title">Results</span>
                        <span class="item-count" id="item-count"></span>
                    </div>
                    <div class="item-ids" id="item-ids"></div>
                    <button class="btn btn-copy" onclick="copyToClipboard(event)">📋 Copy Import String</button>
                </div>
            </div>

            <div class="card">
                <h2>📖 How to Use</h2>
                <div class="info-section">
                    <h3>Step 1: Find a Wowhead Guide</h3>
                    <p>Go to Wowhead and find a Best-in-Slot gear guide for your class and spec.</p>
                    <p style="margin-top: 8px; font-size: 0.95em;">💡 <strong>Tip:</strong> If the guide has multiple tabs (e.g., San'layn, Deathbringer for Death Knight or Overall, Raid and Mythic+), <strong>click the tab you want</strong> on Wowhead first. This will update the URL with the correct hash anchor automatically!</p>
                </div>
                <div class="info-section">
                    <h3>Step 2: Paste the URL</h3>
                    <p>Copy the URL from your browser (after selecting the correct tab) and paste it in the input field above.</p>
                    <p style="margin-top: 8px; font-size: 0.95em;">Example: <code>https://www.wowhead.com/guide/classes/death-knight/blood/bis-gear#bis-items-sanlayn</code></p>
                    <p style="margin-top: 5px; font-size: 0.9em;">Don't worry if there's no hash - the scraper will use the first table by default.</p>
                </div>
                <div class="info-section">
                    <h3>Step 3: Select Role & Scrape</h3>
                    <p>Click your role button (Tank, DPS, or Healer) to scrape both gear and enchants, then use the "Copy Import String" button.</p>
                </div>
                <div class="info-section">
                    <h3>Step 4: Import to Addon</h3>
                    <p>In WoW, type <code>/bis import</code> and paste the import string when prompted.</p>
                </div>
            </div>
        </div>

        <script>
            let currentImportString = '';

            async function scrapeRole(role) {
                const bisUrl = document.getElementById('bisUrl').value;
                const result = document.getElementById('result');
                const resultTitle = document.getElementById('result-title');
                const itemCount = document.getElementById('item-count');
                const itemIds = document.getElementById('item-ids');

                if (!bisUrl || !bisUrl.includes('bis-gear')) {
                    alert('Please enter a valid BiS gear URL containing "bis-gear"');
                    return;
                }

                result.style.display = 'block';
                result.className = '';
                resultTitle.textContent = 'Loading...';
                itemCount.textContent = '';
                itemIds.innerHTML = '<div class="loading">⏳ Scraping BiS Gear & Enchants for ' + role.toUpperCase() + '...</div>';

                try {
                    const url = '/scrape-full?url=' + encodeURIComponent(bisUrl) + '&role=' + role;
                    const response = await fetch(url);
                    const data = await response.json();

                    if (data.success) {
                        currentImportString = data.import_string;
                        result.className = 'success';
                        resultTitle.textContent = '✅ Success!';
                        itemCount.textContent = `Found ${data.gear_count} items + ${data.enchant_count} enchants`;
                        itemIds.textContent = data.import_string;
                    } else {
                        result.className = 'error';
                        resultTitle.textContent = '❌ Error';
                        itemCount.textContent = '';
                        itemIds.textContent = data.error;
                    }
                } catch (e) {
                    result.className = 'error';
                    resultTitle.textContent = '❌ Error';
                    itemCount.textContent = '';
                    itemIds.textContent = 'Failed to connect to server: ' + e.message;
                }
            }

            function copyToClipboard(event) {
                const text = currentImportString;
                const btn = event.target;

                if (!text) {
                    alert('No data to copy! Please scrape items first by clicking a role button.');
                    return;
                }

                // Try modern clipboard API
                if (navigator.clipboard && navigator.clipboard.writeText) {
                    navigator.clipboard.writeText(text).then(() => {
                        const originalText = btn.textContent;
                        btn.textContent = '✓ Copied!';
                        btn.style.background = 'linear-gradient(135deg, #4CAF50 0%, #45a049 100%)';

                        setTimeout(() => {
                            btn.textContent = originalText;
                            btn.style.background = '';
                        }, 2000);
                    }).catch(err => {
                        console.error('Clipboard error:', err);
                        fallbackCopy(text, btn);
                    });
                } else {
                    // Fallback for older browsers
                    fallbackCopy(text, btn);
                }
            }

            function fallbackCopy(text, btn) {
                // Create temporary textarea
                const textarea = document.createElement('textarea');
                textarea.value = text;
                textarea.style.position = 'fixed';
                textarea.style.opacity = '0';
                document.body.appendChild(textarea);
                textarea.select();

                try {
                    const successful = document.execCommand('copy');
                    if (successful) {
                        const originalText = btn.textContent;
                        btn.textContent = '✓ Copied!';
                        btn.style.background = 'linear-gradient(135deg, #4CAF50 0%, #45a049 100%)';

                        setTimeout(() => {
                            btn.textContent = originalText;
                            btn.style.background = '';
                        }, 2000);
                    } else {
                        alert('Failed to copy. Please select and copy manually.');
                    }
                } catch (err) {
                    console.error('Fallback copy failed:', err);
                    alert('Failed to copy. Please select and copy manually.');
                }

                document.body.removeChild(textarea);
            }
        </script>
    </body>
    </html>
    """

@app.route('/scrape')
def scrape():
    """API endpoint to scrape Wowhead BiS pages"""
    url = request.args.get('url', '')

    if not url:
        return jsonify({
            'success': False,
            'error': 'No URL provided. Use ?url=YOUR_WOWHEAD_URL'
        }), 400

    # Decode URL if needed
    url = unquote(url)

    # Validate it's a Wowhead URL
    if 'wowhead.com' not in url:
        return jsonify({
            'success': False,
            'error': 'Only Wowhead URLs are supported'
        }), 400

    # Scrape the items
    items = scrape_wowhead_items(url)

    if not items:
        return jsonify({
            'success': False,
            'error': 'No items found on that page. Make sure it\'s a BiS guide URL.'
        }), 404

    return jsonify({
        'success': True,
        'count': len(items),
        'items': items,
        'source_url': url
    })

@app.route('/scrape-full')
def scrape_full():
    """API endpoint to scrape both BiS gear and enchants based on role"""
    url = request.args.get('url', '')
    role = request.args.get('role', 'dps').lower()

    if not url:
        return jsonify({
            'success': False,
            'error': 'No URL provided. Use ?url=YOUR_WOWHEAD_URL&role=tank|dps|healer'
        }), 400

    # Decode URL if needed
    url = unquote(url)

    # Validate it's a Wowhead URL
    if 'wowhead.com' not in url:
        return jsonify({
            'success': False,
            'error': 'Only Wowhead URLs are supported'
        }), 400

    # Validate role
    if role not in ['tank', 'dps', 'healer']:
        return jsonify({
            'success': False,
            'error': 'Role must be tank, dps, or healer'
        }), 400

    # Scrape BiS gear
    gear_items = scrape_wowhead_items(url)
    if not gear_items:
        return jsonify({
            'success': False,
            'error': 'No gear items found on that page. Make sure it\'s a BiS guide URL.'
        }), 404

    # Scrape enchants - construct URL by replacing bis-gear with enchants-gems-pve-{role}
    enchant_url = url.replace('bis-gear', f'enchants-gems-pve-{role}')
    enchants_with_slots = scrape_wowhead_enchants(enchant_url)

    # Allow BiS gear without enchants
    if not enchants_with_slots:
        pass  # Silently continue without enchants

    # Create import string format: "BIS##slot:id;slot:id;;ENCHANT##slot:id;slot:id"
    parts = []

    # Add BiS gear items with slots
    if gear_items:
        bis_items = []
        for item in gear_items:
            bis_items.append(f"'{item['slot']}':{item['id']}")
        parts.append("BIS##" + ";".join(bis_items))

    # Add enchants with slots (multiple enchants per slot separated by |)
    # Format: 'slot':id~context|id~context
    if enchants_with_slots:
        enchant_items = []
        for enchant in enchants_with_slots:
            # Build enchant options as id~context pairs, joined by |
            enchant_options = []
            for enc in enchant['enchants']:
                if enc['context']:
                    enchant_options.append(f"{enc['id']}~{enc['context']}")
                else:
                    enchant_options.append(str(enc['id']))

            enchant_str = "|".join(enchant_options)
            enchant_items.append(f"'{enchant['slot']}':{enchant_str}")
        parts.append("ENCHANT##" + ";".join(enchant_items))

    import_string = ";;".join(parts)

    return jsonify({
        'success': True,
        'gear_count': len(gear_items),
        'enchant_count': len(enchants_with_slots),
        'gear_items': gear_items,
        'enchants': enchants_with_slots,
        'import_string': import_string,
        'gear_url': url,
        'enchant_url': enchant_url,
        'role': role
    })

@app.route('/scrape-both')
def scrape_both():
    """API endpoint to scrape both BiS gear and enchants from separate URLs"""
    bis_url = request.args.get('bisUrl', '')
    enchants_url = request.args.get('enchantsUrl', '')

    if not bis_url:
        return jsonify({
            'success': False,
            'error': 'No BiS URL provided'
        }), 400

    # Decode URLs if needed
    bis_url = unquote(bis_url)
    enchants_url = unquote(enchants_url) if enchants_url else ''

    # Validate BiS URL
    if 'wowhead.com' not in bis_url:
        return jsonify({
            'success': False,
            'error': 'Only Wowhead URLs are supported'
        }), 400

    # TESTING: Disable BiS gear scraping for now
    # gear_items = scrape_wowhead_items(bis_url)
    # if not gear_items:
    #     return jsonify({
    #         'success': False,
    #         'error': 'No gear items found on BiS page. Make sure it\'s a BiS guide URL.'
    #     }), 404
    gear_items = []  # Temporarily disabled

    # Scrape enchants if URL provided
    enchants = []
    if enchants_url and 'wowhead.com' in enchants_url:
        enchants = scrape_wowhead_enchants(enchants_url)

    if not enchants:
        return jsonify({
            'success': False,
            'error': 'No enchants found. Make sure the enchants URL is correct.'
        }), 404

    # Create import string format: "GEAR:item1,item2,...|ENCHANTS:spell1,spell2,..."
    gear_string = ','.join(map(str, gear_items))
    enchant_string = ','.join(map(str, enchants)) if enchants else ''

    if gear_string and enchant_string:
        import_string = f"GEAR:{gear_string}|ENCHANTS:{enchant_string}"
    elif enchant_string:
        import_string = f"ENCHANTS:{enchant_string}"
    else:
        import_string = f"GEAR:{gear_string}"

    return jsonify({
        'success': True,
        'gear_count': len(gear_items),
        'enchant_count': len(enchants),
        'gear_items': gear_items,
        'enchants': enchants,
        'import_string': import_string,
        'gear_url': bis_url,
        'enchant_url': enchants_url if enchants_url else None
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
