// CoCo language syntax highlighting for Prism.js
// Register as prism-coco.js and load in Nextra via next.config.js

(function (Prism) {
  Prism.languages.coco = {
    'comment': [
      {
        pattern: /\/\*[\s\S]*?\*\//,
        greedy: true,
      },
      {
        pattern: /\/\/.*/,
        greedy: true,
      },
    ],
    'string': {
      pattern: /"[^"]*"/,
      greedy: true,
    },
    'keyword': {
      pattern: /\b(?:main|function|call|return|if|then|else|fi|while|do|od|repeat|until)\b/,
    },
    'type': {
      pattern: /\b(?:int|float|bool|void)\b/,
    },
    'boolean': {
      pattern: /\b(?:true|false)\b/,
    },
    'operator': {
      pattern:
        /(==|!=|<=|>=|<|>|\+=|-=|\*=|\/=|%=|\^=|&&|\|\||\+\+|--|\+|-|\*|\/|%|\^|=)/,
    },
    'punctuation': /[{}[\](),.:;]/,
    'number': {
      pattern: /-?\d+(?:\.\d+)?/,
    },
    'function': {
      pattern: /\b[a-zA-Z][a-zA-Z\d_]*\s*(?=\()/,
    },
    'variable': {
      pattern: /\b[a-zA-Z][a-zA-Z\d_]*\b/,
    },
  };
})(Prism);
