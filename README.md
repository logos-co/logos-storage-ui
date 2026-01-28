# logos-storage-ui

## How to Build

### Using Nix (Recommended)

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
# Build only the library (plugin)
nix build '.#lib'

# Build the standalone Qt application
nix build '.#app'
```

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

The compiled artifacts can be found at `result/`

#### SELinux

If you are using Linux with SELinux enabled, you will not be able to install Nix without disabling it. A common workaround is to install Nix inside a Toolbox container. In that case, if you are using Qt Creator, you may also need to configure the project using submodules.

#### Running the Standalone App

After building the app with `nix build`, you can run it:

```bash
# Run the standalone Qt application
./result/bin/logos-storage-ui-app
```

The app will automatically load the required modules (capability_module, storage_module) and the storage_ui Qt plugin. All dependencies are bundled in the Nix store layout.

#### Nix Organization

The nix build system is organized into modular files in the `/nix` directory:
- `nix/default.nix` - Common configuration (dependencies, flags, metadata)
- `nix/lib.nix` - UI plugin compilation
- `nix/app.nix` - Standalone Qt application compilation

### Using submodules

CMake is also configured to work with submodules. This is particularly useful for proper integration with Qt Creator. You only need to fetch the submodules using:

```bash
git submodule update --init --recursive
```

Everything should work straightforwardly. The submodules are also used as a fallback when the dependency folders are not found on the system. It can also be forced by enabling the `LOGOS_STORAGE_MODULE_USE_VENDOR` option.

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

## Development

### Architecture

The project is divided into 3 apps:

1- **StorageUIPlugin**: It uses the root `CMakeLists.txt` and the sources in the `plugin` folder. This is the main UI. It is a plugin because it can be reused in the Logos main app or in a standalone application.

2- **qml**: It uses `plugin/qml/CMakeLists.txt`. It is just a dev application used to run the QML Preview easily. Note that it relies on the `StorageUIPlugin` build folder, so **YOU MUST** build `StorageUIPlugin` before using the QML preview.

3- **LogosStorageUIApp**: It uses `app/CMakeLists.txt`. It is a standalone demo app to showcase the `StorageUIPlugin`.

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

You need to import the 3 apps in Qt Creator.

To import the project into Qt Creator, click on `File -> Open File or Project` and select the `CMakeLists.txt` file. A configuration popup will appear. Make sure you have a **Debug** build configuration pointing to the `build` directory and then click on `Configure project`.

Enable CMake debug logging, add `--log-level=DEBUG` in `Projects` -> `Imported Kits` -> `Build` -> `Additional CMake options`.

Ensure that `clangd` is enabled for your project. Go to `Projects` on the left, then click on `Manage Kits` at the top. Select the `C++` tab and open the last tab, `Clangd`. Check `Use clangd` and, if needed, configure it to use the `clangd` installed on your system.

That’s it. The configuration defined in `CMakeLists.txt` should allow the project to build correctly.

If you encounter any configuration issues, close Qt Creator, remove the `CMakeLists.txt.user` file, and restart Qt Creator to reconfigure the project.

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
