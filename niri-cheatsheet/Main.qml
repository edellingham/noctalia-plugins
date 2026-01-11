import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null

  // Logger helper functions
  function logDebug(msg) {
    if (typeof Logger !== 'undefined') Logger.d(msg);
    else console.log(msg);
  }

  function logInfo(msg) {
    if (typeof Logger !== 'undefined') Logger.i(msg);
    else console.log(msg);
  }

  function logWarn(msg) {
    if (typeof Logger !== 'undefined') Logger.w(msg);
    else console.warn(msg);
  }

  function logError(msg) {
    if (typeof Logger !== 'undefined') Logger.e(msg);
    else console.error(msg);
  }

  property var niriCategories: []
  property var customCategories: []
  property bool niriLoaded: false
  property bool customLoaded: false

  onPluginApiChanged: {
    if (pluginApi) {
      logInfo("NiriCheatsheet: pluginApi loaded, starting generator");
      runGenerator();
    }
  }

  Component.onCompleted: {
    if (pluginApi) {
      logDebug("NiriCheatsheet: Component.onCompleted, starting generator");
      runGenerator();
    }
  }

  function runGenerator() {
    logDebug("NiriCheatsheet: === START GENERATOR ===");
    niriCategories = [];
    customCategories = [];
    niriLoaded = false;
    customLoaded = false;

    var homeDir = process.environment["HOME"];
    if (!homeDir) {
      logError("NiriCheatsheet: ERROR - cannot get $HOME");
      saveToDb([{
        "title": pluginApi?.tr("main.error") || "ERROR",
        "binds": [{ "keys": "ERROR", "desc": pluginApi?.tr("main.cannot_get_home") || "Cannot get $HOME" }]
      }]);
      return;
    }

    // Load Niri config if enabled
    if (pluginApi?.pluginSettings?.showNiriBindings !== false) {
      loadNiriConfig(homeDir);
    } else {
      niriLoaded = true;
    }

    // Load custom keybindings if enabled
    if (pluginApi?.pluginSettings?.showCustomBindings !== false) {
      loadCustomKeybinds(homeDir);
    } else {
      customLoaded = true;
    }
  }

  function loadNiriConfig(homeDir) {
    var filePath = homeDir + "/.config/niri/config.kdl";
    var cmd = "cat " + filePath;

    logDebug("NiriCheatsheet: Loading Niri config from " + filePath);
    var proc = process.create("bash", ["-c", cmd]);

    proc.finished.connect(function() {
      logDebug("NiriCheatsheet: Niri config process finished. ExitCode: " + proc.exitCode);

      if (proc.exitCode !== 0) {
        logWarn("NiriCheatsheet: Could not read Niri config: " + proc.stderr);
        niriLoaded = true;
        checkAndMerge();
        return;
      }

      var content = proc.stdout;
      if (content.length > 0) {
        parseNiriConfig(content);
      } else {
        logWarn("NiriCheatsheet: Niri config is empty");
      }
      niriLoaded = true;
      checkAndMerge();
    });
  }

  function loadCustomKeybinds(homeDir) {
    var customPath = pluginApi?.pluginSettings?.customKeybindsPath || "~/.config/niri/custom-keybinds.json";
    customPath = customPath.replace("~", homeDir);

    var cmd = "cat " + customPath;
    logDebug("NiriCheatsheet: Loading custom keybinds from " + customPath);

    var proc = customProcess.create("bash", ["-c", cmd]);

    proc.finished.connect(function() {
      logDebug("NiriCheatsheet: Custom keybinds process finished. ExitCode: " + proc.exitCode);

      if (proc.exitCode !== 0) {
        logDebug("NiriCheatsheet: No custom keybinds file found (this is optional)");
        customLoaded = true;
        checkAndMerge();
        return;
      }

      var content = proc.stdout;
      if (content.length > 0) {
        parseCustomKeybinds(content);
      }
      customLoaded = true;
      checkAndMerge();
    });
  }

  function parseNiriConfig(text) {
    logDebug("NiriCheatsheet: Parsing Niri config");
    var lines = text.split('\n');
    var categories = [];

    // Category mappings for Niri actions
    var categoryMap = {
      "spawn": "Applications",
      "close-window": "Window Management",
      "focus-column": "Focus",
      "focus-window": "Focus",
      "focus-workspace": "Workspaces",
      "move-column": "Window Movement",
      "move-window": "Window Movement",
      "consume-window": "Window Management",
      "expel-window": "Window Management",
      "set-column-width": "Window Sizing",
      "switch-preset-column-width": "Window Sizing",
      "maximize-column": "Window Sizing",
      "fullscreen-window": "Window Sizing",
      "center-column": "Window Management",
      "focus-monitor": "Monitors",
      "move-column-to-monitor": "Monitors",
      "move-workspace-to-monitor": "Monitors",
      "screenshot": "Screenshot",
      "screenshot-screen": "Screenshot",
      "screenshot-window": "Screenshot",
      "quit": "System",
      "power-off-monitors": "System",
      "toggle-debug-tint": "Debug"
    };

    var categoryBinds = {};
    var inBindsBlock = false;
    var braceDepth = 0;
    var currentLine = "";

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      var trimmedLine = line.trim();

      // Skip comments
      if (trimmedLine.startsWith("//")) continue;

      // Detect binds block start
      if (trimmedLine.match(/^binds\s*\{/)) {
        inBindsBlock = true;
        braceDepth = 1;
        continue;
      }

      if (!inBindsBlock) continue;

      // Track brace depth
      for (var c = 0; c < trimmedLine.length; c++) {
        if (trimmedLine[c] === '{') braceDepth++;
        else if (trimmedLine[c] === '}') braceDepth--;
      }

      // Exit binds block when depth returns to 0
      if (braceDepth <= 0) {
        inBindsBlock = false;
        continue;
      }

      // Parse keybinding lines
      // Format: Mod+Key { action "arg"; } or with comments // description
      var bindMatch = trimmedLine.match(/^([A-Za-z0-9+_-]+)\s*\{\s*([^}]+)\s*\}/);
      if (bindMatch) {
        var keyCombo = bindMatch[1];
        var actionPart = bindMatch[2].trim();

        // Extract action name
        var actionMatch = actionPart.match(/^([a-z-]+)/);
        var action = actionMatch ? actionMatch[1] : "unknown";

        // Check for inline comment description
        var descMatch = trimmedLine.match(/\/\/\s*(.+)$/);
        var description = descMatch ? descMatch[1].trim() : formatAction(actionPart);

        // Format key combo for display
        var formattedKeys = formatKeyCombo(keyCombo);

        // Determine category
        var category = categoryMap[action] || "Other";

        if (!categoryBinds[category]) {
          categoryBinds[category] = [];
        }

        categoryBinds[category].push({
          "keys": formattedKeys,
          "desc": description
        });
      }
    }

    // Convert to categories array
    var categoryOrder = ["Applications", "Window Management", "Focus", "Window Movement",
                         "Window Sizing", "Workspaces", "Monitors", "Screenshot", "System", "Debug", "Other"];

    for (var j = 0; j < categoryOrder.length; j++) {
      var catName = categoryOrder[j];
      if (categoryBinds[catName] && categoryBinds[catName].length > 0) {
        categories.push({
          "title": catName,
          "binds": categoryBinds[catName],
          "source": "niri"
        });
      }
    }

    logDebug("NiriCheatsheet: Found " + categories.length + " categories from Niri config");
    niriCategories = categories;
  }

  function formatKeyCombo(keyCombo) {
    // Convert Niri key format to display format
    var parts = keyCombo.split("+");
    var formatted = [];

    for (var i = 0; i < parts.length; i++) {
      var part = parts[i].trim();
      if (part === "Mod" || part === "Super") {
        formatted.push("Super");
      } else if (part === "Shift") {
        formatted.push("Shift");
      } else if (part === "Ctrl" || part === "Control") {
        formatted.push("Ctrl");
      } else if (part === "Alt") {
        formatted.push("Alt");
      } else {
        // Regular key - capitalize first letter
        formatted.push(part.charAt(0).toUpperCase() + part.slice(1));
      }
    }

    return formatted.join(" + ");
  }

  function formatAction(actionPart) {
    // Create human-readable description from action
    var parts = actionPart.split(/\s+/);
    var action = parts[0].replace(/-/g, " ");

    // Capitalize first letter
    action = action.charAt(0).toUpperCase() + action.slice(1);

    // Add arguments if present
    if (parts.length > 1) {
      var args = parts.slice(1).join(" ").replace(/[";]/g, "");
      if (args.length > 0) {
        action += ": " + args;
      }
    }

    return action;
  }

  function parseCustomKeybinds(content) {
    logDebug("NiriCheatsheet: Parsing custom keybinds JSON");
    try {
      var data = JSON.parse(content);
      if (data.categories && Array.isArray(data.categories)) {
        for (var i = 0; i < data.categories.length; i++) {
          data.categories[i].source = "custom";
        }
        customCategories = data.categories;
        logDebug("NiriCheatsheet: Found " + customCategories.length + " custom categories");
      }
    } catch (e) {
      logError("NiriCheatsheet: Failed to parse custom keybinds JSON: " + e);
    }
  }

  function checkAndMerge() {
    if (niriLoaded && customLoaded) {
      var allCategories = niriCategories.concat(customCategories);
      logInfo("NiriCheatsheet: Merged " + allCategories.length + " total categories");
      saveToDb(allCategories);
    }
  }

  Process {
    id: process
    function create(cmd, args) {
      logDebug("NiriCheatsheet: Creating process: " + cmd + " " + args.join(" "));
      command = [cmd].concat(args);
      running = true;
      return this;
    }
  }

  Process {
    id: customProcess
    function create(cmd, args) {
      logDebug("NiriCheatsheet: Creating custom process: " + cmd + " " + args.join(" "));
      command = [cmd].concat(args);
      running = true;
      return this;
    }
  }

  function saveToDb(data) {
    if (pluginApi) {
      pluginApi.pluginSettings.cheatsheetData = data;
      pluginApi.saveSettings();
      logInfo("NiriCheatsheet: SAVED TO DB " + data.length + " categories");
    } else {
      logError("NiriCheatsheet: ERROR - pluginApi is null!");
    }
  }

  IpcHandler {
    target: "plugin:niri-cheatsheet"
    function toggle() {
      logDebug("NiriCheatsheet: IPC toggle called");
      if (pluginApi) {
        runGenerator();
        pluginApi.withCurrentScreen(screen => pluginApi.openPanel(screen));
      }
    }
    function refresh() {
      logDebug("NiriCheatsheet: IPC refresh called");
      if (pluginApi) {
        runGenerator();
      }
    }
  }
}
