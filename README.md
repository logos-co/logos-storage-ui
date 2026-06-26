# Logos Storage UI

The Logos Storage UI is a file sharing application built on top of the [Logos Storage Module](https://github.com/logos-co/logos-storage-module) to showcase its capabilities.

## How to Run 

Run the app using the standalone runner:

```bash
nix run
```

You can override a dependency by using a local version with `--override-input`. Example:

```
nix run --override-input storage_module/logos-storage git+file:///somewhere/logos-storage-nim?submodules=1
```

## How to Build

### Build the app

```bash
nix build
```

The result will include:
- `/lib/storage_ui_plugin.dylib` (or `.so` on Linux) - The Storage UI plugin

### Build packages

```bash
nix build '.#lgx'
```

### Troubleshooting:

If you encounter the following error during the build process:

```
error: Failed to fetch git repository https://boringssl.googlesource.com/boringssl : error: RPC failed; HTTP 500 curl 22 The requested URL returned error: 500
fatal: unable to write request to remote: Broken pipe
```

This is typically due to Git's HTTP request size limits being too low for large repositories. To resolve this, increase the limits by running the following commands:

```
git config --global http.postBuffer 524288000
git config --global http.maxRequestBuffer 100M
```

After setting these values, retry to build.

### Development Shell

```bash
nix develop
```

**Note:** In zsh, you need to quote the target (e.g., `'.#default'`) to prevent glob expansion.

If you don't have flakes enabled globally, add experimental flags:

```bash
nix build --extra-experimental-features 'nix-command flakes'
```

To enable globally so you don't need these flags for each command, add the following to `~/.config/nix/nix.conf` (create if it doesn't exist):
```ini
experimental-features = nix-command flakes
```

The compiled artifacts can be found at `result/`

### SELinux

If you are using Linux with SELinux enabled, you will not be able to install Nix without disabling it. A common workaround is to install Nix inside a Toolbox container. 

## Guidance 

You can access to the [Storage Module documentation](https://logos-co.github.io/logos-storage-module/latest) to get more context about the Storage Module and its configuration. 

You can also refer to our [UI Guide](docs/ui-guide.md) for information about the usage of the Storage UI.

If you prefer a technical approach, you can refer to our [doctest using automated tests](https://logos-co.github.io/logos-doctest-hub/#logos-storage-module/ubuntu-latest/driving-the-storage-ui-against-this-module).

## Configuration

After onboarding, settings are saved to a file whose location depends on the OS:

| OS      | Path                                             |
|---------|--------------------------------------------------|
| Linux   | `~/.config/Logos/LogosStandalone.conf`           |
| macOS   | `~/Library/Preferences/co.logos.LogosStandalone.plist` |

If you are running this UI inside the Basecamp application, the location of the preferences files will be:

| OS      | Path                                             |
|---------|--------------------------------------------------|
| Linux   | `~/.config/Logos/LogosBasecamp.conf`           |
| macOS   | `~/Library/Preferences/co.logos.LogosBasecamp.plist` |


The settings are saved to the preferences file to preserve the onboarding defaults, but the active configuration is stored in `${HOME}/.logos_storage/config.json`. You can tweak the values there directly. Note that running the onboarding again will override any onboarding-related values.

To restart the onboarding process, simply delete the preferences file and relaunch the application or use the debug panel (ctrl + d) to reset the onboarding state.

The debug panel also provides access to the module's configuration JSON for runtime configuration tweaks. See the module's [API reference](https://logos-co.github.io/logos-storage-module/latest/api_reference.html) for a list of configuration options. To apply changes, restart the Storage Module.


### Nix Organization

The build is driven by `flake.nix` and `metadata.json`, using `mkLogosQmlModule` from `logos-module-builder`. The previous layout with a separate `nix/` directory (`default.nix`, `lib.nix`, `app.nix`) has been replaced by that template.

## Development

For more information on development, see the [development documentation](docs/development.md).

## Requirements

### Build Tools
- CMake (3.16 or later)
- Ninja build system
- pkg-config

### Dependencies
- Qt6 (qtbase)
- Qt6 Widgets (included in qtbase)
- Qt6 Remote Objects (qtremoteobjects)
- logos-liblogos
- logos-cpp-sdk (for header generation)
- logos-storage-module
- logos-capability-module
- zstd
- krb5
- abseil-cpp
