{ pkgs ? import <nixpkgs> { } }:

with pkgs;

mkShell rec {
  nativeBuildInputs = [
    pkg-config
  ];
  buildInputs = [
    cargo rustc rust-analyzer rustfmt
  ];
  LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;
}
