# logos-storage-ui setup

This file describes how to set up the project for development with Nix.
At the end of this document, you should be able to build the project using Nix in a toolbox (if SELinux is enabled), with the generated headers available from your host environment.

## OS with SELinux enabled

If you are using Fedora, you are probably not able to install Nix without disabling SELinux. If you do so, you can move to the next section.  
Otherwise, here are the steps to have a working environment using Toolbox.

### Create the toolbox

You need to run the following commands to create the toolbox:

```bash
toolbox create logos-storage
toolbox enter logos-storage
```

### Install Nix and build

```bash
sudo dnf install nix
nix build ".#lib"
```

After the build, the `result` directory should contain two folders: `include` and `lib`.
To make the files in the `include` folder available from the host environment, we need to copy them into our `libs` folder, because the host environment does not have access to the Nix store:

```bash
rsync -aL result/include/ libs/
```

In the `libs` folder, you should now see `logos_sdk.h`.

## OS without SELinux

You need to install Nix and build the library:

```bash
nix build ".#lib"
```

In the `result/include` folder, you should see `logos_sdk.h`.
