{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.pre-commit-hooks = {
    url = "github:cachix/pre-commit-hooks.nix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };
  inputs.systems.url = "github:nix-systems/default";

  outputs = {
    self,
    nixpkgs,
    systems,
    flake-utils,
    pre-commit-hooks,
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
                inherit (beamPackages) elixir-ls;
              })
            ];
          })
      );
  in {
    devShells = eachSystem (pkgs:
      with pkgs; {
        default = mkShell {
          buildInputs = [
            erlang
            elixir
            elixir-ls
          ];

          inherit (self.checks.${system}.pre-commit-check) shellHook;

          ERL_AFLAGS = "-kernel shell_history enabled";
        };
      });

    checks = eachSystem (pkgs: {
      pre-commit-check = pre-commit-hooks.lib.${pkgs.system}.run {
        src = ./.;
        hooks = {
          mix-format.enable = true;
          credo = {
            enable = true;
            stages = [
              "push"
            ];
          };
          dialyzer = {
            enable = true;
            stages = [
              "commit"
            ];
          };
          mix-test = {
            enable = true;
            stages = [
              "push"
            ];
          };
        };
      };
    });
  };
}
