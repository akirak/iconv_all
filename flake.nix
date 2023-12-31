{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.pre-commit-hooks = {
    url = "github:cachix/pre-commit-hooks.nix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };
  inputs.systems.url = "github:nix-systems/default";
  inputs.next-ls.url = "github:elixir-tools/next-ls";

  outputs = {
    self,
    nixpkgs,
    systems,
    flake-utils,
    pre-commit-hooks,
    ...
  } @ inputs: let
    # Set the Erlang version
    erlangVersion = "erlang_25";
    # Set the Elixir version
    elixirVersion = "elixir_1_14";

    inherit (nixpkgs.lib) optional optionals;

    eachSystem = f:
      nixpkgs.lib.genAttrs (import systems) (
        system: let
          pkgs = nixpkgs.legacyPackages.${system};

          erlang = pkgs.beam.interpreters.${erlangVersion};
          beamPackages = pkgs.beam.packages.${erlangVersion};
          elixir = beamPackages.${elixirVersion};
        in
          f (import nixpkgs {
            inherit system;
            overlays = [
              (_: prev: {
                inherit erlang elixir;
                # inherit (beamPackages) elixir-ls;
                next-ls = inputs.next-ls.packages.${system}.default;
              })
            ];
          })
      );
  in {
    packages = eachSystem (
      pkgs: {
        inherit (pkgs) elixir;
      }
    );

    devShells = eachSystem (pkgs:
      with pkgs; {
        default = mkShell {
          buildInputs =
            [
              erlang
              elixir
              # elixir-ls
              next-ls
            ]
            ++ lib.optional stdenv.isLinux inotify-tools
            ++ (
              lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
                CoreFoundation
                CoreServices
              ])
            );

          inherit (self.checks.${system}.pre-commit-check) shellHook;

          ERL_AFLAGS = "-kernel shell_history enabled";
        };
      });

    checks = eachSystem (pkgs: {
      pre-commit-check = pre-commit-hooks.lib.${pkgs.system}.run {
        src = ./.;
        hooks = {
          mix-format.enable = true;
        };
      };
    });
  };
}
