{
    description = "A single-key launcher for Linux";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
        utils.url = "github:numtide/flake-utils";
    };

    outputs = inputs: 
        let
            inherit (inputs) self nixpkgs utils;
            platforms = [
                "x86_64-linux"
                "aarch64-linux"
            ];

            version = "0.1.0";

            mkSkl = pkgs:
                let
                    system = pkgs.stdenv.hostPlatform.system;
                in
                    pkgs.stdenv.mkDerivation {
                        pname = "skl";
                        inherit version;

                        nativeBuildInputs = with pkgs; [
                            odin
                            sdl3
                            sdl3-ttf
                            mold
                        ];

                        buildInputs = with pkgs; [
                            odin
                            sdl3
                            sdl3-ttf
                            makeWrapper
                        ];

                        src = ./.;

                        buildPhase = ''
                        runHook preBuild

                        odin build . -o:speed -linker:mold -microarch:native -out:skl

                        runHook postBuild
                        '';

                        installPhase = ''
                        runHook preInstall

                        mkdir -p $out/bin
                        cp skl $out/bin/skl-unwrapped

                        makeWrapper $out/bin/skl-unwrapped $out/bin/skl \
                        --prefix LD_LIBRARY_PATH : "${
                            nixpkgs.lib.makeLibraryPath [
                                pkgs.sdl3
                                pkgs.sdl3-ttf
                            ]
                        }"

                        runHook postInstall
                        '';

                        meta = {
                            description = "A single-key launcher for Linux";
                            homepage = "https://github.com/souzaware/skl";
                            mainProgram = "skl";
                        };
                    };
        in
            utils.lib.eachDefaultSystem (system:
                let 
                    pkgs = nixpkgs.legacyPackages.${system};
                in
                    {
                    packages = {
                        skl = mkSkl pkgs;
                        default = self.packages.${system}.skl;
                    };

                    devShell = pkgs.mkShell {
                        buildInputs = with pkgs; [
                            odin
                            sdl3
                            sdl3-ttf
                        ];
                    };
                });
}
