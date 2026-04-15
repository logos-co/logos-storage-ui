# logos-storage-ui

The Logos Storage UI is a file sharing application built on top of the [Logos Storage Module](https://github.com/logos-co/logos-storage-module) to showcase its capabilities.

## How to Build

### Using Nix

#### Build the app

```bash
# Build the app
nix build

# Or explicitly
nix build '.#default'
```

The result will include:
- `/lib/storage_ui.dylib` (or `.so` on Linux) - The Storage UI plugin

#### Build Individual Components

```bash
# Combined plugin + QML view (default package)
nix build

# Build only the C++ plugin library
nix build '.#lib'

# Optional: packaged outputs (see flake)
nix build '.#lgx'
nix build '.#install'
```

There is no separate `.#app` package; the standalone runner is exposed as `nix run` / `apps.default` by `mkLogosQmlModule`.

Troubleshooting:

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

#### Development Shell

```bash
# Enter development shell with all dependencies
nix develop
```

**Note:** In zsh, you need to quote the target (e.g., `'.#default'`) to prevent glob expansion.

If you don't have flakes enabled globally, add experimental flags:

```bash
nix build --extra-experimental-features 'nix-command flakes'
```

To enable globally so you don't need these flag for each command, add the following to `~/.config/nix/nix.conf` (create if it doesn't exist):
```ini
experimental-features = nix-command flakes
```

The compiled artifacts can be found at `result/`

#### SELinux

If you are using Linux with SELinux enabled, you will not be able to install Nix without disabling it. A common workaround is to install Nix inside a Toolbox container. In that case, if you are using Qt Creator, you may also need to configure the project using submodules.

#### Running the Standalone App

After building (`nix build`) or without a prior install step:

```bash
nix run
```

If you prefer running from `result/` after `nix build`:

```bash
./result/bin/logos-storage-ui-app
```

**Case 1.** You are behind a NAT, but your node supports UPnP or NAT-PMP.

In this case, you should use the `Guided` setup option followed by the `UPnP` option, and Logos storage will use that to configure
the network automatically for you.

**Case 2.** You are behind a NAT with no UPnP or NAT-PMP support, but you can set up port forwarding rules manually.

In this case, you should use the `Guided` setup option followed by the `Port Forwarding` option. Logos storage requires one TCP and one UDP
port. The onboarding UI will ask you for which TCP port to use, whereas the UDP port is fixed at 8090. You will need to forward both of
them in your router. In case you cannot forward UDP/8090, see Case 3.

**Case 3.** You need to manually configure the network settings or would like to modify other node configuration options.

In this case, you should use the `Advanced` setup option. This will display a prepopulated configuration JSON which you can then manually edit to suit your needs. See the module's [API reference](https://logos-co.github.io/logos-storage-module/api_reference.html) for a list of configuration options.

After selecting the appropriate option and clicking `Continue`, the connectivity checker will kick in. If the node is reachable, you should
see a message saying "your node is up and reachable". If the node is not reachable, you will need to [troubleshoot](#troubleshooting) your connection.
Alternatively, you can choose to continue anyway, but you will only be able to _download_ files from other nodes.

### Sharing a File

To share a file, locate the upload panel and click on it. This will open a file selector. Select the file you would like to share and click
`Open`. This will upload the file into the node and begin sharing it with other nodes in the network. The Content Identifier (CID) for the
file -- a string like `zDvZRwzm49ZJLzxheYtydzx6AcNVSrf69LriUWjPr1SNLVnaXfj2` -- will be displayed in the upload panel. You can share this
string with other people to allow them to download the file.

### Downloading a File

To download a file, you must first paste the file's CID into the `Fetch manifest` panel and click `Fetch`. This will download the file's metadata from the network.
Once the metadata is downloaded, you will see an entry appearing in the `Manifests` list at the bottom of the UI. To download the file, click on the download
next to the entry and a file selector will open, allowing you to choose where to save the file. Once you select a location, the file will be downloaded.
The download progress widget will show progress in real-time.

### Deleting Files

To stop sharing a file, you can click on the trash bin icon close to the manifest entry corresponding to the file you want to stop sharing. This will delete
the file from the node and interrupt its sharing.

## Configuration

After onboarding, settings are saved to a file whose location depends on the OS:

| OS      | Path                                             |
|---------|--------------------------------------------------|
| Linux   | `~/.config/Logos/LogosStorage.conf`              |
| macOS   | `~/Library/Preferences/Logos.LogosStorage.plist` |
| Windows | `HKCU\Software\Logos\LogosStorage` (Registry)    |

The settings are saved to the preferences file to preserve the onboarding defaults, but the active configuration is stored in `${HOME}/.logos_storage/config.json`. You can tweak the values there directly. Note that running the onboarding again will override any onboarding-related values.

To restart the onboarding process, simply delete the preferences file and relaunch the application.

The debug panel also provides access to the module's configuration JSON for runtime configuration tweaks. See the module's [API reference](https://logos-co.github.io/logos-storage-module/api_reference.html) for a list of configuration options. To apply changes, restart the Storage Module.

## Troubleshooting

Logos Storage requires your node to be reachable from the internet and, to that end, you must open two ports on your router:

1. **Discovery.** UDP, defaults to `8090`. Used for discovery and DHT operations.
2. **libp2p listen port.** TCP, defaults to `8500`. Used for data transfer and peer connections.

Problems in not being able to share files are commonly related to either one (or both) of those ports not being open or available.

### Node has no peers

**Symptom:**
The node starts successfully but never connects to any peer.

**Cause:**
This is typically due to the discovery being unavailable - for instance, if another process is already occupying its port.

**Fix:**
Ensure that no process is using port `8090`, or change the default port value in the advanced configuration.

### UPnP not working

**Symptom:**
You selected UPnP during setup but the node remains unreachable.

**Cause:**
UPnP relies on your router supporting and enabling the UPnP protocol. Many routers have it disabled by default for security reasons.

**Fix:**
Make sure UPnP is enabled on your router or switch to port forwarding config.

### Manual port forwarding

**Symptom:**
You configure the port forwarding with both UDP and TCP ports but the node remains unreachable.

**Cause:**
The ports are not open on your router.

**Fix:**
Make sure port forwarding is enabled for these ports on your router.

#### Nix Organization

The build is driven by `flake.nix` and `metadata.json`, using `mkLogosQmlModule` from `logos-module-builder`. The previous layout with a separate `nix/` directory (`default.nix`, `lib.nix`, `app.nix`) has been replaced by that template.

### Using submodules

CMake is also configured to work with submodules. This is particularly useful for proper integration with Qt Creator. You only need to fetch the submodules using:

```bash
git submodule update --init --recursive
```

Everything should work straightforwardly. The submodules are also used as a fallback when the dependency folders are not found on the system. For the `src/qml` CMake project outside Nix, set `LOGOS_LIBLOGOS_ROOT`, `LOGOS_CPP_SDK_ROOT`, and `LOGOS_STORAGE_ROOT` as required by `src/qml/CMakeLists.txt`.

Note: While this setup is convenient for integration with Qt Creator, it is strongly recommended to use Nix for producing reproducible and deterministic builds.

### Using local dependencies

Another way to build the project is to clone the dependencies into the same parent directory, for example:

```
logos-storage-module
logos-storage-ui
logos-cpp-sdk
logos-liblogos
```

While this setup is less common, it is also supported and works correctly in Qt Creator

## Output Structure

When built with Nix:

**App build (`nix build`):**
```
result/
├── bin/
│   ├── logos-storage-ui-app  # Standalone Qt application
│   ├── logos_host           # Logos host executable (for plugins)
│   └── logoscore            # Logos core executable
├── lib/
│   ├── liblogos_core.dylib  # Logos core library
│   └── liblogos_sdk.dylib   # Logos SDK library
├── modules/
│   ├── capability_module_plugin.dylib
│   └── storage_module_plugin.dylib
└── storage_ui.dylib            # Qt plugin (loaded by app)
```

Exact paths and file names follow the current `mkLogosQmlModule` / standalone harness outputs; inspect `result/` after a successful build.

## Development

### Architecture

The project is divided into two CMake entry points:

1. **StorageUIPlugin**: It uses the root `CMakeLists.txt` and the sources under `src/`. This is the main UI. It is a plugin because it can be reused in the Logos main app or in a standalone application.

2. **qml**: It uses `src/qml/CMakeLists.txt`. It is a dev application used to run the QML preview easily. Note that it relies on the `StorageUIPlugin` build folder, so **YOU MUST** build `StorageUIPlugin` before using the QML preview.

There is no longer a separate third app under `app/` — the standalone demo flow is satisfied by `nix run` together with `mkLogosQmlModule`'s bundled output.

### Qt Creator (for development)

Qt Creator provides a great development experience for Qt. To ensure proper integration, it is recommended to either configure the project using submodules or clone the dependencies independently into the same parent directory. Nix *may* work with Qt Creator, but only after an initial build has been run.

#### Installation

##### Install from the repository (recommended)

If your package manager provides `qtcreator`, this is the easiest way to start. You will need to install some dependencies with it.
Note that you should install and run it from a Toolbox, otherwise you may face `glx` errors:

```bash
sudo dnf install cmake ninja clangd qtcreator gcc
```

##### Install from the installer

An alternative is to use the [Qt installer](https://www.qt.io/development/download-qt-installer).

Ensure that you already have the build tools installed (see the previous section), or let the installer install them for you (default behavior).

### Configuration

You need to import the CMake projects for the plugin (`CMakeLists.txt` at the repo root) and for `src/qml` into Qt Creator.

To import the project into Qt Creator, click on `File -> Open File or Project` and select the `CMakeLists.txt` file. A configuration popup will appear. Make sure you have a **Debug** build configuration pointing to the `build` directory and then click on `Configure project`.

Enable CMake debug logging, add `--log-level=DEBUG` in `Projects` -> `Imported Kits` -> `Build` -> `Additional CMake options`.

Ensure that `clangd` is enabled for your project. Go to `Projects` on the left, then click on `Manage Kits` at the top. Select the `C++` tab and open the last tab, `Clangd`. Check `Use clangd` and, if needed, configure it to use the `clangd` installed on your system.

Then go to `Projects `-> `qml` -> `Build` -> `Build Environment`. Click Add to create a new variable, set the name to `QML_IMPORT_TYPE`, and set the value to the absolute path of your QML build directory (for example, /path/to/your/project/src/qml/build/qml).

That's it. The configuration defined in `CMakeLists.txt` should allow the project to build correctly.

If you encounter any configuration issues, close Qt Creator, remove the `CMakeLists.txt.user` file, and restart Qt Creator to reconfigure the project.

### Tips

Here are some tips that may help during development:

1. If you use the `Ctrl+B` shortcut to build, make sure the correct project is selected. Right-click on it and choose `Set as Active Project`.
2. If you encounter build errors, a possible fix is to nuke the build folder and rebuild from scratch.
3. Do not call storage module functions from within a callback.

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
