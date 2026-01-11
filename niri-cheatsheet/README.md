# Keybind Cheatsheet (Niri)

A dynamic keyboard shortcuts cheatsheet plugin for [Niri](https://github.com/YaLTeR/niri) compositor. Automatically reads and displays keybindings from your Niri configuration file, and supports custom keybindings via a JSON file.

## Features

- Automatically parses keybindings from `~/.config/niri/config.kdl`
- Support for custom keybindings via JSON file
- Color-coded key display (Super, Ctrl, Shift, Alt)
- Multi-column responsive layout
- Categories organized by action type
- IPC support for toggling via commands
- Full i18n support (13 languages)

## Installation

Install via the Noctalia plugin manager or add the plugin manually to your Noctalia configuration.

## Configuration

### Niri Config

The plugin automatically reads keybindings from `~/.config/niri/config.kdl`. For best results, add inline comments to describe your keybindings:

```kdl
binds {
    Mod+Return { spawn "alacritty"; } // Open terminal
    Mod+D { spawn "wofi" "--show=drun"; } // App launcher
    Mod+Q { close-window; } // Close window
    Mod+F { fullscreen-window; } // Toggle fullscreen
}
```

### Custom Keybindings

You can also define custom keybindings in a JSON file. By default, the plugin looks for `~/.config/niri/custom-keybinds.json`:

```json
{
  "categories": [
    {
      "title": "My Applications",
      "binds": [
        { "keys": "Super + T", "desc": "Open terminal" },
        { "keys": "Super + B", "desc": "Open browser" },
        { "keys": "Super + E", "desc": "Open file manager" }
      ]
    },
    {
      "title": "Custom Scripts",
      "binds": [
        { "keys": "Super + Shift + S", "desc": "Screenshot tool" },
        { "keys": "Super + Shift + P", "desc": "Color picker" }
      ]
    }
  ]
}
```

### Settings

Access plugin settings to configure:

- **Custom Keybindings File**: Path to your custom JSON file (supports `~` for home directory)
- **Show Niri Bindings**: Toggle display of keybindings from Niri config
- **Show Custom Bindings**: Toggle display of keybindings from JSON file

## Usage

### Bar Widget

Click the keyboard icon in your status bar to open the cheatsheet panel.

### IPC Commands

You can toggle the cheatsheet via IPC:

```bash
# Toggle the cheatsheet panel
noctalia ipc "plugin:niri-cheatsheet" toggle

# Refresh keybindings
noctalia ipc "plugin:niri-cheatsheet" refresh
```

## Key Categories

The plugin automatically categorizes keybindings based on their actions:

- **Applications**: spawn commands
- **Window Management**: close-window, consume-window, expel-window, center-column
- **Focus**: focus-column, focus-window
- **Window Movement**: move-column, move-window
- **Window Sizing**: set-column-width, maximize-column, fullscreen-window
- **Workspaces**: focus-workspace
- **Monitors**: focus-monitor, move-column-to-monitor, move-workspace-to-monitor
- **Screenshot**: screenshot, screenshot-screen, screenshot-window
- **System**: quit, power-off-monitors
- **Other**: Any unrecognized actions

## Supported Languages

- English (en)
- German (de)
- Spanish (es)
- French (fr)
- Italian (it)
- Japanese (ja)
- Dutch (nl)
- Polish (pl)
- Portuguese (pt)
- Russian (ru)
- Turkish (tr)
- Ukrainian (uk-UA)
- Chinese Simplified (zh-CN)

## Requirements

- Noctalia Shell 3.6.0 or higher
- Niri compositor

## License

MIT
