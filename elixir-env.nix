{
  runCommand,
  makeWrapper,
  elixir,
  mixDeps,
  beamPackages,
  lib,
}: let
  installMixDeps = depName: depAttrs: ''
    depPath="''${MIX_DEPS_PATH}/${depName}"
    depSrc="${depAttrs}/src"
    if [[ -d "$depSrc" ]]
    then
      ln -s "$depSrc" "$depPath"
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

    makeWrapper ${elixir}/bin/mix $out/bin/mix \
       --prefix PATH : "${elixir}" \
       --prefix PATH : "${beamPackages.hex}" \
       --set LC_ALL "C.UTF-8" \
       --set HEX_OFFLINE 1 \
       --set MIX_ENV dev \
       --set MIX_HOME "''${MIX_HOME}" \
       --set HEX_HOME "''${HEX_HOME}" \
       --set MIX_DEPS_PATH "''${MIX_DEPS_PATH}"
  ''
