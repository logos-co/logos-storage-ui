# logos-storage-ui

## How to Build

### Using Nix (Recommended)

#### Build the app

```bash
# Build the app
nix build 
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