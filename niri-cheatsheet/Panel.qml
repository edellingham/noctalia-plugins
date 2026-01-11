import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
  id: root
  property var pluginApi: null
  property var rawCategories: pluginApi?.pluginSettings?.cheatsheetData || []
  property var categories: rawCategories
  property var column0Items: []
  property var column1Items: []
  property var column2Items: []

  onRawCategoriesChanged: {
    categories = rawCategories;
    updateColumnItems();
  }

  onCategoriesChanged: {
    updateColumnItems();
  }

  function updateColumnItems() {
    var assignments = distributeCategories();
    column0Items = buildColumnItems(assignments[0]);
    column1Items = buildColumnItems(assignments[1]);
    column2Items = buildColumnItems(assignments[2]);
  }

  property real contentPreferredWidth: 1400
  property real contentPreferredHeight: 850
  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: false
  readonly property bool panelAnchorHorizontalCenter: true
  readonly property bool panelAnchorVerticalCenter: true
  anchors.fill: parent
  property var allLines: []
  property bool isLoading: false

  onPluginApiChanged: { if (pluginApi) checkAndGenerate(); }
  Component.onCompleted: { if (pluginApi) checkAndGenerate(); }

  function checkAndGenerate() {
    if (root.rawCategories.length === 0) {
      isLoading = true;
      allLines = [];
      catProcess.running = true;
    }
  }

  Process {
    id: catProcess
    command: ["sh", "-c", "cat ~/.config/niri/config.kdl"]
    running: false

    stdout: SplitParser {
      onRead: data => {
        root.allLines.push(data);
      }
    }

    onExited: (exitCode, exitStatus) => {
      isLoading = false;
      if (exitCode === 0 && root.allLines.length > 0) {
        var fullContent = root.allLines.join("\n");
        parseAndSave(fullContent);
        root.allLines = [];
      } else {
        errorText.text = pluginApi?.tr("panel.error_read_file") || "Could not read Niri config";
        errorView.visible = true;
      }
    }
  }

  function parseAndSave(text) {
    var lines = text.split('\n');
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
      "power-off-monitors": "System"
    };

    var categoryBinds = {};
    var inBindsBlock = false;
    var braceDepth = 0;

    for (var i = 0; i < lines.length; i++) {
      var trimmedLine = lines[i].trim();
      if (trimmedLine.startsWith("//")) continue;

      if (trimmedLine.match(/^binds\s*\{/)) {
        inBindsBlock = true;
        braceDepth = 1;
        continue;
      }

      if (!inBindsBlock) continue;

      for (var c = 0; c < trimmedLine.length; c++) {
        if (trimmedLine[c] === '{') braceDepth++;
        else if (trimmedLine[c] === '}') braceDepth--;
      }

      if (braceDepth <= 0) {
        inBindsBlock = false;
        continue;
      }

      var bindMatch = trimmedLine.match(/^([A-Za-z0-9+_-]+)\s*\{\s*([^}]+)\s*\}/);
      if (bindMatch) {
        var keyCombo = bindMatch[1];
        var actionPart = bindMatch[2].trim();
        var actionMatch = actionPart.match(/^([a-z-]+)/);
        var action = actionMatch ? actionMatch[1] : "unknown";
        var descMatch = trimmedLine.match(/\/\/\s*(.+)$/);
        var description = descMatch ? descMatch[1].trim() : formatAction(actionPart);
        var formattedKeys = formatKeyCombo(keyCombo);
        var category = categoryMap[action] || "Other";

        if (!categoryBinds[category]) {
          categoryBinds[category] = [];
        }
        categoryBinds[category].push({ "keys": formattedKeys, "desc": description });
      }
    }

    var cats = [];
    var categoryOrder = ["Applications", "Window Management", "Focus", "Window Movement",
                         "Window Sizing", "Workspaces", "Monitors", "Screenshot", "System", "Other"];
    for (var j = 0; j < categoryOrder.length; j++) {
      var catName = categoryOrder[j];
      if (categoryBinds[catName] && categoryBinds[catName].length > 0) {
        cats.push({ "title": catName, "binds": categoryBinds[catName], "source": "niri" });
      }
    }

    if (cats.length > 0) {
      pluginApi.pluginSettings.cheatsheetData = cats;
      pluginApi.saveSettings();
    } else {
      errorText.text = pluginApi?.tr("panel.no_bindings") || "No keybindings found in config";
      errorView.visible = true;
    }
  }

  function formatKeyCombo(keyCombo) {
    var parts = keyCombo.split("+");
    var formatted = [];
    for (var i = 0; i < parts.length; i++) {
      var part = parts[i].trim();
      if (part === "Mod" || part === "Super") formatted.push("Super");
      else if (part === "Shift") formatted.push("Shift");
      else if (part === "Ctrl" || part === "Control") formatted.push("Ctrl");
      else if (part === "Alt") formatted.push("Alt");
      else formatted.push(part.charAt(0).toUpperCase() + part.slice(1));
    }
    return formatted.join(" + ");
  }

  function formatAction(actionPart) {
    var parts = actionPart.split(/\s+/);
    var action = parts[0].replace(/-/g, " ");
    action = action.charAt(0).toUpperCase() + action.slice(1);
    if (parts.length > 1) {
      var args = parts.slice(1).join(" ").replace(/[";]/g, "");
      if (args.length > 0) action += ": " + args;
    }
    return action;
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: Color.mSurface
    radius: Style.radiusL
    clip: true

    Rectangle {
      id: header
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 45
      color: Color.mSurfaceVariant
      radius: Style.radiusL

      RowLayout {
        anchors.centerIn: parent
        spacing: Style.marginS
        NIcon {
          icon: "keyboard"
          pointSize: Style.fontSizeM
          color: Color.mPrimary
        }
        NText {
          text: pluginApi?.tr("panel.title") || "Niri Cheat Sheet"
          font.pointSize: Style.fontSizeM
          font.weight: Font.Bold
          color: Color.mPrimary
        }
      }

      // Refresh button
      Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: Style.marginM
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 30
        radius: 15
        color: refreshArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"

        NIcon {
          anchors.centerIn: parent
          icon: "refresh-cw"
          pointSize: 12
          color: Color.mOnSurfaceVariant
        }

        MouseArea {
          id: refreshArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            pluginApi.pluginSettings.cheatsheetData = [];
            pluginApi.saveSettings();
            checkAndGenerate();
          }
        }
      }
    }

    NText {
      id: loadingText
      anchors.centerIn: parent
      text: pluginApi?.tr("panel.loading") || "Loading..."
      visible: root.isLoading
      font.pointSize: Style.fontSizeL
      color: Color.mOnSurface
    }

    ColumnLayout {
      id: errorView
      anchors.centerIn: parent
      visible: false
      spacing: Style.marginM
      NIcon {
        icon: "alert-circle"
        pointSize: 48
        Layout.alignment: Qt.AlignHCenter
        color: Color.mError
      }
      NText {
        id: errorText
        text: pluginApi?.tr("panel.no_data") || "No data"
        font.pointSize: Style.fontSizeM
        color: Color.mOnSurface
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
      }
      NButton {
        text: pluginApi?.tr("panel.refresh_button") || "Refresh"
        Layout.alignment: Qt.AlignHCenter
        onClicked: {
          errorView.visible = false;
          pluginApi.pluginSettings.cheatsheetData = [];
          pluginApi.saveSettings();
          checkAndGenerate();
        }
      }
    }

    RowLayout {
      id: mainLayout
      visible: root.categories.length > 0 && !root.isLoading
      anchors.top: header.bottom
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: Style.marginM
      spacing: Style.marginS

      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignTop
        spacing: 2
        Repeater {
          model: root.column0Items
          Loader {
            Layout.fillWidth: true
            sourceComponent: modelData.type === "header" ? headerComponent :
                           (modelData.type === "spacer" ? spacerComponent : bindComponent)
            property var itemData: modelData
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignTop
        spacing: 2
        Repeater {
          model: root.column1Items
          Loader {
            Layout.fillWidth: true
            sourceComponent: modelData.type === "header" ? headerComponent :
                           (modelData.type === "spacer" ? spacerComponent : bindComponent)
            property var itemData: modelData
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignTop
        spacing: 2
        Repeater {
          model: root.column2Items
          Loader {
            Layout.fillWidth: true
            sourceComponent: modelData.type === "header" ? headerComponent :
                           (modelData.type === "spacer" ? spacerComponent : bindComponent)
            property var itemData: modelData
          }
        }
      }
    }
  }

  Component {
    id: headerComponent
    RowLayout {
      spacing: Style.marginXS
      Layout.topMargin: Style.marginM
      Layout.bottomMargin: 4
      NIcon {
        icon: itemData.source === "custom" ? "star" : "circle-dot"
        pointSize: 10
        color: itemData.source === "custom" ? Color.mTertiary : Color.mPrimary
      }
      NText {
        text: itemData.title
        font.pointSize: 11
        font.weight: Font.Bold
        color: itemData.source === "custom" ? Color.mTertiary : Color.mPrimary
      }
    }
  }

  Component {
    id: spacerComponent
    Item {
      height: 10
      Layout.fillWidth: true
    }
  }

  Component {
    id: bindComponent
    RowLayout {
      spacing: Style.marginS
      height: 22
      Layout.bottomMargin: 1
      Flow {
        Layout.preferredWidth: 220
        Layout.alignment: Qt.AlignVCenter
        spacing: 3
        Repeater {
          model: itemData.keys.split(" + ")
          Rectangle {
            width: keyText.implicitWidth + 10
            height: 18
            color: getKeyColor(modelData)
            radius: 3
            NText {
              id: keyText
              anchors.centerIn: parent
              text: modelData
              font.pointSize: modelData.length > 12 ? 7 : 8
              font.weight: Font.Bold
              color: Color.mOnPrimary
            }
          }
        }
      }
      NText {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        text: itemData.desc
        font.pointSize: 9
        color: Color.mOnSurface
        elide: Text.ElideRight
      }
    }
  }

  function getKeyColor(keyName) {
    if (keyName === "Super") return Color.mPrimary;
    if (keyName === "Ctrl") return Color.mSecondary;
    if (keyName === "Shift") return Color.mTertiary;
    if (keyName === "Alt") return "#FF6B6B";
    if (keyName.startsWith("XF86")) return "#4ECDC4";
    if (keyName === "Print") return "#95E1D3";
    if (keyName.match(/^[0-9]$/)) return "#A8DADC";
    if (keyName.includes("Mouse")) return "#F38181";
    return Color.mPrimaryContainer || "#6C757D";
  }

  function buildColumnItems(categoryIndices) {
    var result = [];
    if (!categoryIndices) return result;

    for (var i = 0; i < categoryIndices.length; i++) {
      var catIndex = categoryIndices[i];
      if (catIndex >= categories.length) continue;

      var cat = categories[catIndex];
      result.push({ type: "header", title: cat.title, source: cat.source || "niri" });

      for (var j = 0; j < cat.binds.length; j++) {
        result.push({
          type: "bind",
          keys: cat.binds[j].keys,
          desc: cat.binds[j].desc
        });
      }

      if (i < categoryIndices.length - 1) {
        result.push({ type: "spacer" });
      }
    }
    return result;
  }

  function distributeCategories() {
    var weights = [];
    var totalWeight = 0;
    for (var i = 0; i < categories.length; i++) {
      var weight = 1 + categories[i].binds.length + 1;
      weights.push(weight);
      totalWeight += weight;
    }

    var columns = [[], [], []];
    var columnWeights = [0, 0, 0];

    for (var i = 0; i < categories.length; i++) {
      var minCol = 0;
      for (var c = 1; c < 3; c++) {
        if (columnWeights[c] < columnWeights[minCol]) {
          minCol = c;
        }
      }
      columns[minCol].push(i);
      columnWeights[minCol] += weights[i];
    }

    return columns;
  }
}
