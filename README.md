# logos-storage-ui

A QML + C++ backend UI module for the [Logos](https://logos.co) platform that provides a decentralized storage interface built on top of [`logos-storage-module`](https://github.com/logos-co/logos-storage-module).

Built with [`logos-module-builder`](https://github.com/logos-co/logos-module-builder) using the `mkLogosQmlModule` pattern (QML frontend + C++ backend with Qt Remote Objects).

## Features

- Onboarding wizard (UPnP or manual port forwarding)
- Upload and download files via the Logos network
- Monitor storage node status, peers, and space usage
- Download manifests and manage stored content
- Debug panel with JSON config editor and logs
- Configuration persistence across restarts

## How to Run

### Standalone (recommended for development)

```bash
# Run directly
nix run

# With local workspace overrides
nix run --override-input storage_module path:../logos-storage-module \
        --override-input storage_module/logos-module-builder path:../logos-module-builder
```

The standalone app starts Logos Core, loads `capability_module` and `storage_module`, then launches the QML UI via an isolated `ui-host` process.

### In Basecamp

Build the `.lgx` package and install it:

```bash
# Build LGX
nix build .#lgx

# Install into Basecamp's plugin directory
lgpm --ui-plugins-dir ~/Library/Application\ Support/Logos/LogosBasecampDev/plugins \
     install --file result/*.lgx
```

Or from the workspace:

```bash
ws bundle logos-storage-ui --auto-local
```

### Build Targets

```bash
nix build            # default — combined plugin + QML output
nix build .#lgx      # .lgx package for distribution
nix build .#install  # lgpm-installed output (modules/ + plugins/)
nix run              # standalone app with storage_module
nix develop          # enter development shell
```

## Module Structure

```
logos-storage-ui/
├── flake.nix                  # mkLogosQmlModule
├── metadata.json              # Module config (ui_qml type)
├── CMakeLists.txt             # logos_module() macro
└── src/
    ├── StorageBackend.rep     # RemoteObject interface
    ├── StorageBackend.h/cpp   # Business logic (extends StorageBackendSimpleSource)
    ├── StorageUIPlugin.h/cpp  # Thin plugin entry point
    ├── StorageInterface.h     # Plugin interface marker
    └── qml/
        └── Main.qml           # QML frontend (+ sub-views)
```

## Configuration

After onboarding, settings are saved to a platform-specific location:

| OS      | Path                                             |
|---------|--------------------------------------------------|
| Linux   | `~/.config/Logos/LogosStorage.conf`              |
| macOS   | `~/Library/Preferences/Logos.LogosStorage.plist` |
| Windows | `HKCU\Software\Logos\LogosStorage` (Registry)    |

The active configuration is stored in `${HOME}/.logos_storage/config.json`. You can edit values there directly. Running onboarding again will override onboarding-related values.

The debug panel also provides a JSON editor for runtime configuration tweaks. Restart the Storage Module to apply changes.

## Troubleshooting

Logos Storage requires your node to be reachable from the internet. You must open two ports on your router:

1. **Discovery** — UDP, defaults to `8090`. Used for discovery and DHT operations.
2. **libp2p listen port** — TCP, defaults to `8500`. Used for data transfer and peer connections.

### Node has no peers

The node starts but never connects. Typically caused by the discovery port being occupied by another process. Ensure port `8090` is free, or change it in the advanced configuration.

### UPnP not working

UPnP relies on router support. Many routers disable it by default. Enable UPnP on your router or switch to port forwarding.

### Manual port forwarding

Ensure both UDP and TCP ports are forwarded on your router.

## Dependencies

| Dependency | Purpose |
|---|---|
| Qt6 Core, RemoteObjects, Declarative | UI framework + IPC |
| [`logos-module-builder`](https://github.com/logos-co/logos-module-builder) | Build system (mkLogosQmlModule) |
| [`logos-storage-module`](https://github.com/logos-co/logos-storage-module) | Storage backend module |

## Related Repositories

| Repository | Role |
|---|---|
| [`logos-storage-module`](https://github.com/logos-co/logos-storage-module) | Storage backend — this UI's required dependency |
| [`logos-module-builder`](https://github.com/logos-co/logos-module-builder) | Module build system |
| [`logos-liblogos`](https://github.com/logos-co/logos-liblogos) | Logos Core platform |
