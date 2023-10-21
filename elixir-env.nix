{
  runCommand,
  makeWrapper,
  elixir,
  erlang,
  mixDeps,
  beamPackages,
  lib,
}: let
  installMixDeps = depName: depAttrs: ''
    depPath="''${MIX_DEPS_PATH}/${depName}"
    depSrc="${depAttrs}/src"
    if [[ -d "$depSrc" ]]
    then
      mkdir -p "$depPath"
      cp -rp "$depSrc" "$depPath"
    fi
  '';
in
  runCommand "elixir-env" {
    buildInputs = [
      makeWrapper
    ];

    nativeBuildInputs = [
      elixir
      beamPackages.hex
    ] ++ (builtins.attrValues mixDeps);
  } ''
    mkdir -p $out/bin

    mkdir -p $out/share/{mix,hex,deps}

    cp ${./mix.exs} $out/share/mix.exs
    cp ${./mix.lock} $out/share/mix.lock

    MIX_HOME="$out/share/mix"
    HEX_HOME="$out/share/hex"
    MIX_DEPS_PATH="$out/share/deps"

    ${builtins.concatStringsSep "\n" (lib.mapAttrsToList installMixDeps mixDeps)}

    cd $out/share

    LC_ALL=C.UTF-8 MIX_ENV=dev mix deps.compile --no-deps-check

    makeWrapper ${elixir}/bin/mix $out/bin/mix \
       --prefix PATH : "${elixir}" \
       --prefix PATH : "${beamPackages.hex}" \
       --prefix PATH : "${erlang}" \
       --set LC_ALL "C.UTF-8" \
       --set HEX_OFFLINE 1 \
       --set MIX_ENV dev
  ''
