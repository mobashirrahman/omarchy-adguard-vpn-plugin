import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// AdGuard VPN bar widget. Left-click connects (to the last used location) or
// disconnects; right-click opens a searchable picker over every AdGuard VPN
// location so a specific country/city can be chosen. Uses Color.accent
// instead of the default active/urgent color so "connected" doesn't read as
// a warning.
BarWidget {
  id: root
  moduleName: "mobashirrahman.adguardvpn"

  readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/omarchy/plugins/mobashirrahman.adguardvpn/scripts"

  property string statusText: "󰖂 …"
  property string statusTooltip: "AdGuard VPN"
  property bool connected: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  Process {
    id: statusProc
    command: ["bash", "-lc", root.scriptsDir + "/vpn-status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var data = {}
        try { data = JSON.parse(text) } catch (e) {}
        root.statusText = data.text || root.statusText
        root.statusTooltip = data.tooltip || "AdGuard VPN"
        root.connected = (data.class || "") === "active"
      }
    }
  }

  Timer {
    interval: Math.max(2, Number(root.setting("refreshIntervalSec", 5))) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.statusText
    tooltipText: root.statusTooltip
    active: root.connected
    activeColor: Color.accent
    horizontalMargin: 7.5
    verticalPadding: 6
    fontSize: 12

    onPressed: function(b) {
      if (!root.bar) return
      if (b === Qt.RightButton) root.bar.run(root.scriptsDir + "/vpn-select-location")
      else root.bar.run(root.scriptsDir + "/vpn-toggle")
    }
  }
}
