module.exports = grammar({
  name: 'CoCo',

  rules: {
      // grammar rules go in here
      source_file: $ => $.text,
      text: _ => /(.|\n)+/,
  }
});