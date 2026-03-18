# ShellForge

**The AI-native SSH terminal for iOS.** Built for people who live in the terminal and want their phone to be a first-class citizen.

## v1.0 Features

- **AI-Native Terminal** — Inline AI: explain errors, translate natural language to commands, suggest fixes
- **Visual tmux Manager** — See sessions as a grid, tap to attach, preview pane content
- **One-Tap Connect** — Home screen widgets, auto-tmux-reattach, zero-friction server access
- **Colour Themes** — Solarized Dark, Dracula, Nord, Monokai
- **Keyboard Accessory Bar** — Ctrl, Alt, Esc, Tab, arrows, pipe, tilde
- **Multiple Concurrent Sessions** — Swipe to switch between terminals
- **OSC 52 Clipboard Sync** — Server to iPhone clipboard
- **Haptic Feedback** — Native iOS feel

## Tech Stack

- **SwiftUI** (iOS 17+)
- **SwiftTerm** — Terminal emulator engine (MIT)
- **swift-nio-ssh** — SSH transport (Apache 2.0, Apple-maintained)
- **SwiftData** — Host/key persistence
- **iOS Keychain** — Credential storage
- **WidgetKit** — Home screen widgets

## Acknowledgements

ShellForge is forked from [SwiftTermApp](https://github.com/migueldeicaza/SwiftTermApp) by Miguel de Icaza (MIT license). Terminal emulation powered by [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm).

## License

MIT — see [LICENSE](LICENSE)
