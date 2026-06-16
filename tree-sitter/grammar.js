module.exports = grammar({
  name: 'CoCo',

  word: $ => $.identifier,

  extras: $ => [
    /\s/,
    $.comment,
  ],

  inline: $ => [
    $._type,
    $._return_type,
  ],

  rules: {
    source_file: $ => seq(
      $.computation,
      optional('.'),
    ),

    computation: $ => seq(
      repeat($.function_declaration),
      'main',
      repeat($.variable_declaration),
      repeat($.function_declaration),
      '{',
      $.statement_sequence,
      '}',
      '.',
    ),

    // ── Comments ──────────────────────────────────────────────

    comment: _ => token(choice(
      seq('//', /.*/),
      seq('/*', /[^*]*\*+([^/*][^*]*\*+)*/, '/'),
    )),

    // ── Identifiers & Literals ──────────────────────────────

    identifier: _ => /[a-zA-Z][a-zA-Z0-9_]*/,

    integer_literal: _ => token(/[0-9]+/),
    float_literal: _ => token(/[0-9]+\.[0-9]+/),
    boolean_literal: _ => choice('true', 'false'),

    // ── Types ───────────────────────────────────────────────

    _type: _ => choice('bool', 'int', 'float'),

    type_declaration: $ => seq(
      $._type,
      repeat(seq('[', field('size', $.integer_literal), ']')),
    ),

    parameter_type: $ => seq(
      $._type,
      repeat(seq('[', ']')),
    ),

    _return_type: $ => choice(
      'void',
      $._type,
    ),

    // ── Declarations ────────────────────────────────────────

    variable_declaration: $ => seq(
      field('type', $.type_declaration),
      field('name', $.identifier),
      repeat(seq(',', field('name', $.identifier))),
      ';',
    ),

    parameter_declaration: $ => seq(
      field('type', $.parameter_type),
      field('name', $.identifier),
    ),

    formal_parameters: $ => seq(
      '(',
      optional(seq(
        $.parameter_declaration,
        repeat(seq(',', $.parameter_declaration)),
      )),
      ')',
    ),

    function_body: $ => seq(
      '{',
      repeat($.variable_declaration),
      $.statement_sequence,
      '}',
      ';',
    ),

    function_declaration: $ => seq(
      'function',
      field('name', $.identifier),
      $.formal_parameters,
      ':',
      field('return_type', $._return_type),
      $.function_body,
    ),

    // ── Statements ──────────────────────────────────────────

    statement_sequence: $ => repeat1(seq($.statement, ';')),

    statement: $ => choice(
      $.assignment_statement,
      $.function_call,
      $.if_statement,
      $.while_statement,
      $.repeat_statement,
      $.return_statement,
    ),

    assignment_statement: $ => seq(
      field('left', $.designator),
      choice(
        seq(
          field('operator', choice('=', '+=', '-=', '*=', '/=', '%=', '^=')),
          field('right', $.expression),
        ),
        field('operator', choice('++', '--')),
      ),
    ),

    function_call: $ => seq(
      'call',
      field('name', $.identifier),
      '(',
      optional(seq(
        $.expression,
        repeat(seq(',', $.expression)),
      )),
      ')',
    ),

    if_statement: $ => seq(
      'if',
      field('condition', $.parenthesized_expression),
      'then',
      field('consequence', $.statement_sequence),
      optional(seq(
        'else',
        field('alternative', $.statement_sequence),
      )),
      'fi',
    ),

    while_statement: $ => seq(
      'while',
      field('condition', $.parenthesized_expression),
      'do',
      field('body', $.statement_sequence),
      'od',
    ),

    repeat_statement: $ => seq(
      'repeat',
      field('body', $.statement_sequence),
      'until',
      field('condition', $.parenthesized_expression),
    ),

    return_statement: $ => seq(
      'return',
      optional(field('value', $.expression)),
    ),

    // ── Expressions ─────────────────────────────────────────

    expression: $ => $.relational_expression,

    relational_expression: $ => choice(
      prec.left(seq(
        field('left', $.additive_expression),
        field('operator', choice('==', '!=', '<', '<=', '>', '>=')),
        field('right', $.additive_expression),
      )),
      $.additive_expression,
    ),

    additive_expression: $ => choice(
      prec.left(seq(
        field('left', $.additive_expression),
        field('operator', choice('+', '-', 'or')),
        field('right', $.multiplicative_expression),
      )),
      $.multiplicative_expression,
    ),

    multiplicative_expression: $ => choice(
      prec.left(seq(
        field('left', $.multiplicative_expression),
        field('operator', choice('*', '/', '%', 'and')),
        field('right', $.power_expression),
      )),
      $.power_expression,
    ),

    power_expression: $ => choice(
      prec.right(seq(
        field('left', $.unary_expression),
        '^',
        field('right', $.power_expression),
      )),
      $.unary_expression,
    ),

    unary_expression: $ => choice(
      prec(1, seq(
        field('operator', '-'),
        field('argument', $.unary_expression),
      )),
      prec(1, seq(
        field('operator', 'not'),
        field('argument', $.unary_expression),
      )),
      $.primary_expression,
    ),

    primary_expression: $ => choice(
      $.integer_literal,
      $.float_literal,
      $.boolean_literal,
      $.designator,
      $.function_call,
      $.parenthesized_expression,
    ),

    designator: $ => seq(
      field('name', $.identifier),
      repeat(seq('[', field('index', $.expression), ']')),
    ),

    parenthesized_expression: $ => seq(
      '(',
      $.expression,
      ')',
    ),
  },
});
