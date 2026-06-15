'use client'

import { useState, useCallback } from 'react'
import { run as runCoCo } from '../lib/coco/lib/coco_lib.js'

const DEFAULT_CODE = `main {
    call printInt(1 + 2 * 3 ^ 4);
    call println();

    a = 10;
    b = 20;
    if (a < b) then
        call printInt(b - a);
    else
        call printInt(a - b);
    fi;
    call println();

    i = 0;
    while (i < 5) do
        call printInt(i);
        i++;
    od;
    call println();
}.`

export default function CoCoPlayground() {
  const [code, setCode] = useState(DEFAULT_CODE)
  const [output, setOutput] = useState('')
  const [error, setError] = useState('')

  const run = useCallback(() => {
    setError('')
    const result = runCoCo(code)
    if (result.startsWith('Error:')) {
      setError(result)
      setOutput('')
    } else {
      setOutput(result)
    }
  }, [code])

  return (
    <div style={{ margin: '1.5rem 0', border: '1px solid #e5e7eb', borderRadius: '8px', overflow: 'hidden' }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 0 }}>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '8px 12px', background: '#f3f4f6', borderBottom: '1px solid #e5e7eb'
        }}>
          <span style={{ fontSize: '14px', fontWeight: 600, color: '#374151' }}>CoCo Playground</span>
          <button
            onClick={run}
            style={{
              padding: '4px 16px', fontSize: '13px', fontWeight: 500,
              background: '#3b82f6', color: 'white', border: 'none',
              borderRadius: '4px', cursor: 'pointer'
            }}
          >
            Run
          </button>
        </div>

        <textarea
          value={code}
          onChange={e => setCode(e.target.value)}
          spellCheck={false}
          style={{
            width: '100%', minHeight: '200px', padding: '12px',
            fontFamily: 'monospace', fontSize: '14px', lineHeight: '1.5',
            border: 'none', outline: 'none', resize: 'vertical',
            background: '#1e1e2e', color: '#cdd6f4'
          }}
        />

        {(output || error) && (
          <div style={{
            padding: '12px', fontFamily: 'monospace', fontSize: '14px',
            borderTop: '1px solid #e5e7eb', background: error ? '#fef2f2' : '#f0fdf4',
            color: error ? '#991b1b' : '#166534', whiteSpace: 'pre-wrap', wordBreak: 'break-all'
          }}>
            {error || output}
          </div>
        )}
      </div>
    </div>
  )
}
