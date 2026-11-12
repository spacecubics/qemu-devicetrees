{
  description = "QEMU device trees for the SC-OBC boards";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          boards = map (nixpkgs.lib.removeSuffix ".dts") (
            builtins.filter (f: builtins.match "board-scobc-.*\\.dts" f != null) (
              builtins.attrNames (builtins.readDir ./.)
            )
          );
          targets = builtins.concatMap (b: [
            "LATEST/SINGLE_ARCH/${b}.dtb"
            "LATEST/MULTI_ARCH/${b}.dtb"
          ]) boards;
        in
        {
          scobc-dtbs = pkgs.stdenv.mkDerivation {
            pname = "scobc-qemu-devicetrees";
            version = self.shortRev or self.dirtyShortRev or "unknown";
            src = self;

            nativeBuildInputs = [
              pkgs.dtc
              pkgs.python3
            ];

            makeFlags = [ "GCC=${pkgs.stdenv.cc}/bin/cc" ];
            buildFlags = targets;

            installPhase = ''
              runHook preInstall
              mkdir -p $out
              for d in SINGLE_ARCH MULTI_ARCH; do
                mkdir -p $out/$d
                cp LATEST/$d/*.dtb $out/$d/
              done
              runHook postInstall
            '';
          };

          default = self.packages.${system}.scobc-dtbs;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.dtc
              pkgs.gnumake
              pkgs.python3
            ];
          };
        }
      );
    };
}
