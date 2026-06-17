# CoCo Language Documentation Site

Built with [Nextra](https://nextra.site/).

## Getting Started

```bash
cd website
npm install
npm run dev
```

The site will be available at `http://localhost:3000`.

## Build

```bash
npm run build
```

Output goes to `website/out/` (static export).

## Structure

```
website/
├── pages/
│   ├── index.mdx              # Landing page
│   ├── language/              # Language reference
│   │   ├── overview.mdx
│   │   ├── lexical.mdx
│   │   ├── grammar.mdx
│   │   ├── types.mdx
│   │   ├── expressions.mdx
│   │   ├── statements.mdx
│   │   ├── functions.mdx
│   │   ├── arrays.mdx
│   │   └── io.mdx
│   ├── examples/              # Runnable examples
│   │   ├── basics.mdx
│   │   ├── control-flow.mdx
│   │   └── functions.mdx
│   └── compiler/              # Compiler internals
│       ├── pipeline.mdx
│       └── dlx.mdx
├── lib/
│   ├── coco-prism.js          # Prism syntax highlighting
│   └── coco.tmLanguage.json   # TextMate grammar (for Shiki)
├── theme.config.jsx
├── next.config.js
└── package.json
```

## Syntax Highlighting

CoCo code blocks use ` ```coco ` fences. The highlighting is provided by a
custom Prism grammar in `lib/coco-prism.js`. A TextMate grammar is also
available in `lib/coco.tmLanguage.json` for VS Code / Shiki integration.

## Interactive Playground

The interactive playground uses the js_of_ocaml-compiled OCaml parser
(see `../jsoo/`). The build pipeline is:

1. `dune build ./jsoo/coco_js.bc.js` — compiles OCaml to JS
2. Copy output to `web/public/lib/coco/` — the playground loads it at runtime
3. The playground calls `cocoRun()` (parse + AST dump) or `cocoTokenize()` (lexer)

Run the full pipeline with `npm run build` (the `prebuild` script handles OCaml compilation).
