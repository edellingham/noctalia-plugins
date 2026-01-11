# Setting Up Your Personal Noctalia Plugin Repository

Follow these steps to create your own plugin source repository.

## Quick Setup

### 1. Create a new GitHub repository

Create a new repo on GitHub (e.g., `my-noctalia-plugins`)

### 2. Clone and set up

```bash
# Clone your new repo
git clone https://github.com/YOUR_USERNAME/my-noctalia-plugins
cd my-noctalia-plugins

# Copy the plugin files (from this directory)
cp -r /path/to/niri-cheatsheet .

# Move registry.json to root
mv niri-cheatsheet/registry.json .

# Edit registry.json - update YOUR_NAME and YOUR_USERNAME/YOUR_REPO
nano registry.json

# Remove this setup file
rm niri-cheatsheet/SETUP_YOUR_REPO.md
```

### 3. Update registry.json

Edit the `registry.json` in your repo root:

```json
{
  "version": 1,
  "plugins": [
    {
      "id": "niri-cheatsheet",
      "name": "Keybind Cheatsheet (Niri)",
      "version": "1.0.0",
      "author": "YOUR_ACTUAL_NAME",
      "description": "Dynamic keyboard shortcuts cheatsheet for Niri compositor.",
      "repository": "https://github.com/YOUR_USERNAME/my-noctalia-plugins",
      "minNoctaliaVersion": "3.6.0",
      "license": "MIT",
      "tags": ["Bar", "Panel", "Productivity"],
      "lastUpdated": "2026-01-11T00:00:00Z"
    }
  ]
}
```

### 4. Push to GitHub

```bash
git add .
git commit -m "Add niri-cheatsheet plugin"
git push
```

### 5. Add to Noctalia

In Noctalia Shell settings, add your repository as a custom plugin source:

```
https://github.com/YOUR_USERNAME/my-noctalia-plugins
```

## Final Structure

Your repository should look like:

```
my-noctalia-plugins/
├── registry.json           # At the root!
└── niri-cheatsheet/
    ├── manifest.json
    ├── Main.qml
    ├── Panel.qml
    ├── BarWidget.qml
    ├── Settings.qml
    ├── README.md
    └── i18n/
        ├── en.json
        ├── de.json
        └── ... (other languages)
```

## Adding More Plugins

To add more plugins later:

1. Create a new plugin directory
2. Add the plugin entry to `registry.json`
3. Push changes

That's it! Noctalia will pull plugins from your repository.
