'use client'

import { useEffect, useRef, useState } from 'react'

// ── Tree-sitter highlight capture patterns ──────────────────

const HIGHLIGHT_QUERY = `
[
  "main" "function" "if" "then" "else" "fi"
  "while" "do" "od" "repeat" "until" "call" "return"
] @keyword

[
  "bool" "int" "float" "void"
] @type.builtin

[
  "and" "or" "not"
] @keyword.operator

[
  "true" "false"
] @boolean

(integer_literal) @number
(float_literal) @number
(comment) @comment

[
  "(" ")" "{" "}" "[" "]" ";" "." "," ":"
] @punctuation.delimiter

[
  "=" "+=" "-=" "*=" "/=" "%=" "^="
  "++" "--"
  "+" "-" "*" "/" "%" "^"
  "==" "!=" "<" "<=" ">" ">="
] @operator

(function_declaration name: (identifier) @function)
(function_call name: (identifier) @function.call)
(variable_declaration name: (identifier) @variable)
(parameter_declaration name: (identifier) @variable.parameter)
(designator name: (identifier) @variable)
`

const CAPTURE_CLASS = {
  'keyword': 'coco-kw',
  'type.builtin': 'coco-type',
  'keyword.operator': 'coco-kw',
  'boolean': 'coco-bool',
  'number': 'coco-num',
  'comment': 'coco-cmt',
  'punctuation.delimiter': 'coco-punct',
  'operator': 'coco-op',
  'variable': 'coco-var',
  'variable.parameter': 'coco-var',
  'function': 'coco-fn',
  'function.call': 'coco-fn',
}

// ── Runtime tree-sitter loader (bypasses bundler) ───────────

let _parserSingleton = null
let _querySingleton = null

async function loadTreeSitter() {
  if (_parserSingleton) return _parserSingleton

  // Fetch web-tree-sitter.js from the public directory and import
  // via blob URL so Turbopack never sees the import.
  const resp = await fetch('/web-tree-sitter.js')
  const code = await resp.text()
  const blob = new Blob([code], { type: 'text/javascript' })
  const url = URL.createObjectURL(blob)
  const { default: Parser, Language } = await new Function('spec', 'return import(spec)')(url)
  URL.revokeObjectURL(url)

  await Parser.init()
  const parser = new Parser()
  const language = await Language.load('/tree-sitter-coco.wasm')
  parser.setLanguage(language)
  _querySingleton = language.query(HIGHLIGHT_QUERY)
  _parserSingleton = parser
  return parser
}

// ── Highlight builder ───────────────────────────────────────

function buildHtml(code) {
  const tree = _parserSingleton.parse(code)
  const captures = _querySingleton.captures(tree.rootNode)

  const highlights = []
  for (const cap of captures) {
    highlights.push({
      start: cap.node.startIndex,
      end: cap.node.endIndex,
      cls: CAPTURE_CLASS[cap.name] || '',
    })
  }

  highlights.sort((a, b) => {
    if (a.start !== b.start) return a.start - b.start
    return (b.end - b.start) - (a.end - a.start)
  })

  const resolved = []
  for (const h of highlights) {
    const last = resolved[resolved.length - 1]
    if (last && h.start < last.end) continue
    resolved.push(h)
  }

  let out = ''
  let pos = 0
  for (const h of resolved) {
    if (h.start > pos) out += esc(code.slice(pos, h.start))
    if (h.end > h.start) out += `<span class="${h.cls}">${esc(code.slice(h.start, h.end))}</span>`
    pos = h.end
  }
  if (pos < code.length) out += esc(code.slice(pos))
  return out
}

function esc(s) {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

// ── Component ───────────────────────────────────────────────

export default function CoCoEditor({ code, onChange }) {
  const textareaRef = useRef(null)
  const preRef = useRef(null)
  const [html, setHtml] = useState('')

  // Load parser once
  useEffect(() => {
    loadTreeSitter().catch(() => {})
  }, [])

  // Highlight on code changes
  useEffect(() => {
    if (!_parserSingleton || !_querySingleton) {
      setHtml(esc(code))
      return
    }
    let cancelled = false
    const work = () => {
      try {
        const result = buildHtml(code)
        if (!cancelled) setHtml(result)
      } catch (_) {
        if (!cancelled) setHtml(esc(code))
      }
    }
    // Defer to next frame for responsiveness
    const id = requestAnimationFrame(work)
    return () => { cancelled = true; cancelAnimationFrame(id) }
  }, [code])

  const handleScroll = () => {
    if (textareaRef.current && preRef.current) {
      preRef.current.scrollTop = textareaRef.current.scrollTop
      preRef.current.scrollLeft = textareaRef.current.scrollLeft
    }
  }

  const handleKeyDown = (e) => {
    if (e.key === 'Tab') {
      e.preventDefault()
      const ta = textareaRef.current
      if (!ta) return
      const start = ta.selectionStart
      const end = ta.selectionEnd
      const newCode = code.slice(0, start) + '  ' + code.slice(end)
      onChange(newCode)
      requestAnimationFrame(() => {
        ta.selectionStart = ta.selectionEnd = start + 2
      })
    }
  }

  return (
    <div className="coco-editor">
      <textarea
        ref={textareaRef}
        value={code}
        onChange={(e) => onChange(e.target.value)}
        onScroll={handleScroll}
        onKeyDown={handleKeyDown}
        spellCheck={false}
        autoComplete="off"
        autoCorrect="off"
        autoCapitalize="off"
        className="coco-editor-textarea"
      />
      <pre ref={preRef} className="coco-editor-highlight" aria-hidden="true">
        <code dangerouslySetInnerHTML={{ __html: html || esc(code) || ' ' }} />
      </pre>
      <style jsx>{`
        .coco-editor {
          position: relative;
          min-height: 200px;
        }
        .coco-editor-highlight,
        .coco-editor-textarea {
          margin: 0;
          padding: 12px;
          font-family: 'JetBrains Mono', 'Fira Code', 'Cascadia Code', monospace;
          font-size: 14px;
          line-height: 1.5;
          white-space: pre;
          overflow: auto;
          border: none;
          outline: none;
          word-wrap: normal;
        }
        .coco-editor-highlight {
          position: absolute;
          inset: 0;
          pointer-events: none;
          background: #1e1e2e;
          color: #cdd6f4;
        }
        .coco-editor-textarea {
          position: relative;
          width: 100%;
          min-height: 200px;
          resize: vertical;
          color: transparent;
          caret-color: #f5e0dc;
          background: transparent;
          z-index: 1;
        }
        .coco-editor-textarea::selection {
          background: rgba(100, 140, 220, 0.35);
        }

        /* Tokens */
        :global(.coco-kw)      { color: #cba6f7; font-weight: 600; }
        :global(.coco-type)    { color: #89b4fa; }
        :global(.coco-bool)    { color: #fab387; }
        :global(.coco-num)     { color: #fab387; }
        :global(.coco-cmt)     { color: #6c7086; font-style: italic; }
        :global(.coco-punct)   { color: #bac2de; }
        :global(.coco-op)      { color: #94e2d5; }
        :global(.coco-var)     { color: #cdd6f4; }
        :global(.coco-fn)      { color: #89b4fa; }
      `}</style>
    </div>
  )
}
