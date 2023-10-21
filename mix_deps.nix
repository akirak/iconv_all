{ lib, beamPackages, overrides ? (x: y: {}) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    briefly = buildMix rec {
      name = "briefly";
      version = "0.4.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "02mv9qq7g7dbw2ywcq51aa36prvcrhkzcp5f0q4hvvf4376sy37w";
      };

      beamDeps = [];
    };

    dialyxir = buildMix rec {
      name = "dialyxir";
      version = "1.4.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "00cqwhd1wabwds44jz94rvvr8z8cp12884d3lp69fqkrszb9bdw4";
      };

      beamDeps = [ erlex ];
    };

    erlex = buildMix rec {
      name = "erlex";
      version = "0.2.6";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0x8c1j62y748ldvlh46sxzv5514rpzm809vxn594vd7y25by5lif";
      };

      beamDeps = [];
    };
  };
in self

