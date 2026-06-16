'use client'

import { useEffect, useRef, useState } from 'react'

// ── Capture name → CSS class mapping ─────────────────────────

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

  // 1. Load web-tree-sitter runtime via blob URL (bypasses Turbopack)
  const code = await fetch('/web-tree-sitter.js').then(r => r.text())
  const blob = new Blob([code], { type: 'text/javascript' })
  const url = URL.createObjectURL(blob)
  const { Parser, Language } = await new Function('spec', 'return import(spec)')(url)
  URL.revokeObjectURL(url)

  await Parser.init({
    locateFile: () => '/web-tree-sitter.wasm',
  })

  // 2. Load CoCo grammar WASM
  const parser = new Parser()
  const language = await Language.load('/tree-sitter-coco.wasm')
  parser.setLanguage(language)

  // 3. Load highlight query from the tree-sitter project definition
  const queryText = await fetch('/highlights.scm').then(r => r.text())
  _querySingleton = language.query(queryText)
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
  const [html, setHtml] = useState('')
  const [tsReady, setTsReady] = useState(false)
  const [tsError, setTsError] = useState(null)

  useEffect(() => {
    loadTreeSitter()
      .then(() => setTsReady(true))
      .catch((e) => { setTsReady(false); setTsError(e.message) })
  }, [])

  useEffect(() => {
    if (!tsReady || !_querySingleton) {
      setHtml(esc(code))
      return
    }
    let cancelled = false
    const id = requestAnimationFrame(() => {
      try {
        const result = buildHtml(code)
        if (!cancelled) setHtml(result)
      } catch (_) {
        if (!cancelled) setHtml(esc(code))
      }
    })
    return () => { cancelled = true; cancelAnimationFrame(id) }
  }, [code, tsReady])

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
    <div style={{ display: 'flex', flexDirection: 'column', gap: 0 }}>
      <textarea
        ref={textareaRef}
        value={code}
        onChange={(e) => onChange(e.target.value)}
        onKeyDown={handleKeyDown}
        spellCheck={false}
        autoComplete="off"
        autoCorrect="off"
        autoCapitalize="off"
        style={{
          width: '100%', minHeight: '180px', padding: '12px',
          fontFamily: "'JetBrains Mono','Fira Code','Cascadia Code',monospace",
          fontSize: '14px', lineHeight: '1.5', tabSize: 2,
          border: 'none', outline: 'none', resize: 'vertical',
          background: '#1e1e2e', color: '#cdd6f4',
          boxSizing: 'border-box',
        }}
      />

      <div style={{
        fontSize: '11px', color: '#585b70', padding: '3px 12px',
        background: '#181825', borderTop: '1px solid #313244',
        borderBottom: '1px solid #313244',
        fontFamily: 'system-ui, sans-serif',
      }}>
        syntax-highlighted output (tree-sitter)
      </div>

      <pre style={{
        margin: 0, padding: '12px',
        fontFamily: "'JetBrains Mono','Fira Code','Cascadia Code',monospace",
        fontSize: '14px', lineHeight: '1.5',
        background: '#181825', color: '#cdd6f4',
        overflow: 'auto', maxHeight: '260px',
        whiteSpace: 'pre', wordWrap: 'normal',
        tabSize: 2, MozTabSize: 2,
        fontVariantLigatures: 'none',
      }}>
        <code
          dangerouslySetInnerHTML={{ __html: html || esc(code) || ' ' }}
          style={{
            fontFamily: 'inherit', fontSize: 'inherit', lineHeight: 'inherit',
            fontVariantLigatures: 'none',
          }}
        />
      </pre>

      <style>{`
        .coco-kw    { color: #cba6f7; font-weight: 600; }
        .coco-type  { color: #89b4fa; }
        .coco-bool  { color: #fab387; }
        .coco-num   { color: #fab387; }
        .coco-cmt   { color: #6c7086; font-style: italic; }
        .coco-punct { color: #bac2de; }
        .coco-op    { color: #94e2d5; }
        .coco-var   { color: #cdd6f4; }
        .coco-fn    { color: #89b4fa; }
      `}</style>
    </div>
  )
}
