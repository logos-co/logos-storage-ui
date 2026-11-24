{
  description = "Storage UI plugin for the Logos application";

  # Logos binary cache.
  nixConfig = {
    extra-substituters = [ "https://cache.nix.logos.co/public" ];
    extra-trusted-public-keys = [ "public:zaDAOkd+E3cQyFm9J7qejQYd9HoLJc1SJvnk68hNWeI=" ];
  };

  inputs = {
    logos-module-builder.url = "github:logos-co/logos-module-builder";
    nix-bundle-lgx.url = "github:logos-co/nix-bundle-lgx";
    storage_module.url = "github:logos-co/logos-storage-module/cc38c91c2cf80db32b9667ca272be40485a070ca";
  };

  outputs = inputs@{ logos-module-builder, ... }:
    logos-module-builder.lib.mkLogosQmlModule {
      src = ./.;
      configFile = ./metadata.json;
      flakeInputs = inputs;
    };
}
