## Melange — CoCo Interactive Components

This directory contains the OCaml source for the CoCo language's interactive
web components. These are compiled to JavaScript via
[Melange](https://melange.re/) and consumed by the Nextra documentation site.

### Build

Requires OCaml 4.14+ with `melange` and `melange.ppx`:

```bash
opam install melange
dune build @mel
```

Output JavaScript appears in `_build/default/melange/lib/output/`.

### Modules

| Module | Description |
|--------|-------------|
| `Coco_scanner` | Token types, lexeme-to-kind mapping |
| `Coco_types` | Type system (int, float, bool, void, arrays) |
| `Coco_interpreter` | Runtime values and operations |

### Integration with Website

The compiled JS modules are copied into `website/lib/coco/` and imported
by React components for the interactive playground.
