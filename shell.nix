{
  pkgs ? import <nixpkgs> { },
}:
let
  opkgs = pkgs.ocamlPackages;
in
pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.nodejs
    pkgs.treefmt
    pkgs.nixfmt
    pkgs.oxfmt
  ];
  buildInputs = [
    opkgs.dune_3
    opkgs.ocaml
    opkgs.findlib
    opkgs.ocamlformat
    opkgs.utop
    opkgs.ocaml-lsp
    opkgs.js_of_ocaml
    opkgs.js_of_ocaml-ppx
    opkgs.ppxlib
    opkgs.ppx_expect
    opkgs.ppx_deriving
  ];
}
