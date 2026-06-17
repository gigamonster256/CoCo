## CoCo — OCaml Compiler & Playground

This directory contains the OCaml source for the CoCo language compiler,
compiled to JavaScript via [js_of_ocaml](https://ocsigen.org/js_of_ocaml/)
and consumed by the Nextra documentation site.

### Build

Requires OCaml 4.14+ with `js_of_ocaml`:

```bash
opam install js_of_ocaml
dune build
```

Or use the Nix shell:

```bash
nix-shell
dune build @test/runtest    # run tests
dune build ./jsoo/coco_js.bc.js   # build JS output
```

### Modules

| Module | Description |
|--------|-------------|
| `token` | Token types and formatting |
| `parser` | Parser combinator library |
| `scanner` | Lexer / tokenizer |
| `ast` | Abstract syntax tree types |
| `coco_parser` | Recursive descent parser |
| `ast_pp` | AST pretty-printer |
| `symbol_table` | Type and scope tracking |
| `coco_js` | js_of_ocaml JavaScript bindings |

### Integration with Website

The compiled JS module is copied into `web/public/lib/coco/` and loaded
by the playground component. Run the full web build with:

```bash
cd web && npm run build
```
