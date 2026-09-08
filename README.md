# omarchy-network-priority

A headless [Omarchy](https://omarchy.org/) shell service that enforces one rule:
**Ethernet > Wi-Fi > GSM.**

Whenever a wired Ethernet connection is up, both Wi-Fi and mobile broadband
(GSM) are disabled automatically. This is enforced continuously, not just
once on connect — if a GSM connection profile has `autoconnect=yes` (the
common default) and NetworkManager/ModemManager brings it back up on its own
while Ethernet is still active, this service turns it back off.

No bar icon, no UI. It just runs.

## Install

```
omarchy plugin add https://github.com/Thomster/omarchy-network-priority.git
```

## Requirements

- NetworkManager (`nmcli`)
- Optional: ModemManager (`mmcli`) if you have a GSM/mobile broadband modem —
  the service checks for one but does nothing GSM-related if none exists.

## Related

Pairs well with [omarchy-gsm-status](https://github.com/Thomster/omarchy-gsm-status)
for a bar icon showing GSM signal/mode and a manual connect/disconnect toggle,
but neither depends on the other.

## How this came to be

This is a personal customization for my own Omarchy setup, built with the
help of [Claude Code](https://claude.com/claude-code) (Anthropic's AI coding
agent). I use it daily on my own machine, but I'm not a professional plugin
developer — please read through the source before installing, especially
anything that touches system or network state, and open an issue if
something looks off.

## License

MIT
