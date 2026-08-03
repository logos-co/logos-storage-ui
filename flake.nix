{
  description = "Storage UI plugin for the Logos application";

  inputs = {
    logos-module-builder.url = "github:logos-co/logos-module-builder";
    nix-bundle-lgx.url = "github:logos-co/nix-bundle-lgx";
    storage_module.url = "github:logos-co/logos-storage-module?ref=v2.0.1";
    # Used by preview.sh only, pinned to the revision the module builder uses.
    logos-design-system.follows = "logos-module-builder/logos-design-system";
  };

  outputs = inputs@{ logos-module-builder, logos-design-system, ... }:
    let
      module = logos-module-builder.lib.mkLogosQmlModule {
        src = ./.;
        configFile = ./metadata.json;
        flakeInputs = inputs;
      };
    in
    module // {
      # QML import path for preview.sh. The packaged design system embeds its
      # QML into static libs, which the qml runtime cannot load, so the preview
      # reads the loose sources.
      designSystemQml = "${logos-design-system}/src/qml";
    };
}
