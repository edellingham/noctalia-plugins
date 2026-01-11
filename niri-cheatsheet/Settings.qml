import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root
  property var pluginApi: null

  implicitHeight: settingsColumn.implicitHeight

  ColumnLayout {
    id: settingsColumn
    anchors.fill: parent
    spacing: Style.marginM

    // Custom keybinds file path
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginXS

      NText {
        text: pluginApi?.tr("settings.custom_path_label") || "Custom Keybindings File"
        font.pointSize: Style.fontSizeS
        font.weight: Font.Medium
        color: Color.mOnSurface
      }

      NText {
        text: pluginApi?.tr("settings.custom_path_hint") || "Path to JSON file with custom keybindings (supports ~ for home)"
        font.pointSize: Style.fontSizeXS
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }

      NTextField {
        id: customPathField
        Layout.fillWidth: true
        placeholderText: "~/.config/niri/custom-keybinds.json"
        text: pluginApi?.pluginSettings?.customKeybindsPath || "~/.config/niri/custom-keybinds.json"
        onTextChanged: {
          if (pluginApi) {
            pluginApi.pluginSettings.customKeybindsPath = text;
            pluginApi.saveSettings();
          }
        }
      }
    }

    // Toggle switches
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        NText {
          text: pluginApi?.tr("settings.show_niri_bindings") || "Show Niri Bindings"
          font.pointSize: Style.fontSizeS
          font.weight: Font.Medium
          color: Color.mOnSurface
        }

        NText {
          text: pluginApi?.tr("settings.show_niri_hint") || "Display keybindings from Niri config"
          font.pointSize: Style.fontSizeXS
          color: Color.mOnSurfaceVariant
        }
      }

      Switch {
        checked: pluginApi?.pluginSettings?.showNiriBindings !== false
        onCheckedChanged: {
          if (pluginApi) {
            pluginApi.pluginSettings.showNiriBindings = checked;
            pluginApi.saveSettings();
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        NText {
          text: pluginApi?.tr("settings.show_custom_bindings") || "Show Custom Bindings"
          font.pointSize: Style.fontSizeS
          font.weight: Font.Medium
          color: Color.mOnSurface
        }

        NText {
          text: pluginApi?.tr("settings.show_custom_hint") || "Display keybindings from custom JSON file"
          font.pointSize: Style.fontSizeXS
          color: Color.mOnSurfaceVariant
        }
      }

      Switch {
        checked: pluginApi?.pluginSettings?.showCustomBindings !== false
        onCheckedChanged: {
          if (pluginApi) {
            pluginApi.pluginSettings.showCustomBindings = checked;
            pluginApi.saveSettings();
          }
        }
      }
    }

    // JSON Format Help
    Rectangle {
      Layout.fillWidth: true
      Layout.topMargin: Style.marginM
      color: Color.mSurfaceVariant
      radius: Style.radiusM
      implicitHeight: helpColumn.implicitHeight + Style.marginM * 2

      ColumnLayout {
        id: helpColumn
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginS

        NText {
          text: pluginApi?.tr("settings.json_format_title") || "Custom JSON Format"
          font.pointSize: Style.fontSizeS
          font.weight: Font.Bold
          color: Color.mPrimary
        }

        NText {
          Layout.fillWidth: true
          text: pluginApi?.tr("settings.json_format_example") ||
                '{\n  "categories": [\n    {\n      "title": "My Apps",\n      "binds": [\n        { "keys": "Super + T", "desc": "Terminal" },\n        { "keys": "Super + B", "desc": "Browser" }\n      ]\n    }\n  ]\n}'
          font.family: "monospace"
          font.pointSize: Style.fontSizeXS
          color: Color.mOnSurfaceVariant
          wrapMode: Text.Wrap
        }
      }
    }

    // Refresh button
    NButton {
      Layout.alignment: Qt.AlignRight
      Layout.topMargin: Style.marginM
      text: pluginApi?.tr("settings.refresh_button") || "Refresh Keybindings"
      onClicked: {
        if (pluginApi) {
          pluginApi.pluginSettings.cheatsheetData = [];
          pluginApi.saveSettings();
        }
      }
    }
  }
}
