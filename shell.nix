{
  pkgs ? import <nixpkgs> { },
}:
let
  opkgs = pkgs.ocamlPackages;
in
pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.nodejs # nextjs app and tree-sitter
    pkgs.tree-sitter
    pkgs.emscripten # tree-sitter wasm build
  ];
  buildInputs = [
    opkgs.dune_3
    opkgs.ocaml
    opkgs.findlib
    opkgs.ocamlformat
    opkgs.utop
    opkgs.ocaml-lsp
    opkgs.melange
    opkgs.ppxlib
    opkgs.ppx_expect
    opkgs.ppx_deriving
  ];
}
