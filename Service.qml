import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Headless: enforces Ethernet > Wi-Fi > GSM. No UI, no bar icon. Runs
// independently of any panel/widget that displays network or GSM status --
// it duplicates a minimal GSM connectivity check rather than depending on
// another plugin's internal state, so it works standalone.
Item {
  id: root

  property var shell: null

  function findWiredDevice() {
    var devices = (Networking.devices ? Networking.devices.values : []) || []
    var fallback = null
    for (var i = 0; i < devices.length; i++) {
      var device = devices[i]
      if (!device || device.type !== DeviceType.Wired) continue
      if (device.connected) return device
      if (!fallback) fallback = device
    }
    return fallback
  }

  readonly property var wiredDevice: findWiredDevice()
  readonly property bool ethernetActive: !!(wiredDevice && wiredDevice.connected)
  readonly property bool wifiRadioOn: Networking.wifiEnabled

  // GSM has no Quickshell.Networking device type, so its connected state is
  // polled from nmcli directly -- just enough to know whether it's up and
  // what to bring down, not the richer signal/mode detail a GSM info widget
  // would want.
  property string gsmDeviceState: ""
  property string gsmConnectionName: ""
  readonly property bool gsmConnected: gsmDeviceState === "connected"

  readonly property string gsmStatusScript:
    "nmcli -t -f TYPE,STATE device status | awk -F: '$1==\"gsm\"{print $2; f=1} END{if(!f) print \"\"}'; " +
    "nmcli -t -f TYPE,NAME connection show | awk -F: '$1==\"gsm\"{print $2; exit}'"

  function refreshGsmStatus() {
    if (gsmStatusProc.running) return
    gsmStatusProc.running = true
  }

  function updateGsmStatus(raw) {
    var lines = String(raw || "").split("\n")
    root.gsmDeviceState = lines[0] || ""
    root.gsmConnectionName = lines[1] || ""
  }

  function disableGsm() {
    if (gsmConnectionName === "" || gsmActionProc.running) return
    gsmActionProc.command = ["nmcli", "connection", "down", gsmConnectionName]
    gsmActionProc.running = true
  }

  // Ethernet outranks both radios. This has to be a continuously held
  // invariant, not a one-shot reaction to a derived "which one is active"
  // property -- GSM connection profiles are typically autoconnect=yes, so
  // NetworkManager/ModemManager can bring GSM back up on its own (e.g. after
  // the modem re-registers) with nothing else changing. Watching the radios'
  // own live/polled state, rather than a summary property, means any of them
  // flipping on re-triggers enforcement.
  function enforceEthernetPriority() {
    if (!ethernetActive) return
    if (Networking.wifiEnabled) Networking.wifiEnabled = false
    if (gsmConnected) disableGsm()
  }

  onEthernetActiveChanged: enforceEthernetPriority()
  onGsmConnectedChanged: enforceEthernetPriority()
  onWifiRadioOnChanged: enforceEthernetPriority()

  Process {
    id: gsmStatusProc
    command: ["bash", "-c", root.gsmStatusScript]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateGsmStatus(text)
    }
  }

  Process {
    id: gsmActionProc
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { waitForEnd: true }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshGsmStatus()
  }
}
