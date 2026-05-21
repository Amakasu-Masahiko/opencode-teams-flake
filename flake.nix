{
  description = "OpenCode with team PRs (#12730, #12731, #12732)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";

    opencode-src = builtins.fetchTarball {
      url = "https://github.com/anomalyco/opencode/archive/39145b99e883935541c0580b2c5088e14b4413c4.tar.gz";
      sha256 = "0wf4xh3lr3ih7pkp47iclnb859a6q4kss319kwsnk04ffqkaygbn";
    };

    teamsPatch = ./teams.patch;

    overlay = final: prev: {
      opencode = prev.opencode.overrideAttrs (old: {
        src = opencode-src;
        version = "1.1.56-team";
        patches = [ teamsPatch ];
        buildPhase = ''
          runHook preBuild

          cd ./packages/opencode
          bun --bun ./script/build.ts --single --skip-install
          bun --bun ./script/schema.ts config.json

          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall

          install -Dm755 dist/opencode-*/bin/opencode $out/bin/opencode
          wrapProgram $out/bin/opencode \
           --prefix PATH : ${
            final.lib.makeBinPath [
              final.ripgrep
            ]
          }

          install -Dm644 config.json $out/share/opencode/config.json

          runHook postInstall
        '';
        node_modules = old.node_modules.overrideAttrs (oldNm: {
          src = opencode-src;
          patches = [ teamsPatch ];
          buildPhase = ''
            runHook preBuild

            export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
            bun install \
              --cpu="*" \
              --no-frozen-lockfile \
              --filter ./ \
              --filter ./packages/app \
              --filter ./packages/desktop \
              --filter ./packages/opencode \
              --filter ./packages/shared \
              --ignore-scripts \
              --no-progress \
              --os="*"

            bun --bun ./nix/scripts/canonicalize-node-modules.ts
            bun --bun ./nix/scripts/normalize-bun-binaries.ts

            runHook postBuild
          '';
          outputHash = "sha256-9ZzVMkh52MHBHtOh42ZnFK4TxtY4PI3gPc0gBvC8OVM=";
        });
      });
    };
  in {
    packages.${system}.default = (import nixpkgs {
      system = system;
      overlays = [ overlay ];
    }).opencode;
  };
}
