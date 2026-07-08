<p align="center">
  <img src="docs/assets/icon-256.png" width="128" alt="CleanMac icon">
</p>

<h1 align="center">CleanMac</h1>

CleanMac is a fresh macOS menu bar app shell for a custom system cleanup tool.

## Build

Requires macOS 14+ and Xcode 26+.

```bash
./script/build_and_run.sh
```

Core package checks:

```bash
cd CleanMacCore
swift test
```

## Project

- `CleanMac/` contains the macOS SwiftUI app.
- `CleanMacCore/` contains reusable core logic.
- `script/build_and_run.sh` builds and launches the app from a local build folder.

## License

[MIT](LICENSE)
