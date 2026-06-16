const binding = require('node-gyp-build')(__dirname);
const Language = binding.Language;

const Parser = binding.Parser;

module.exports = {
  Language,
  Parser,
};
