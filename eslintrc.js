module.exports = {
  "extends":"eslint:recommended",
  "env": {
    "es6": true,
    "browser": true,
    "node": true,
    "jquery": true,
    "mocha": true,
    "jasmine": true,
  },
  "globals": {
    "_": true, // for Underscore
    "$": true, // for JQuery
  },
  "parserOptions": {
    "ecmaVersion": 6,
    "sourceType": "module",
    "ecmaFeatures": {
      "jsx": true,
    },
    "rules": {
      "max-len": [1, 120, 2, {ignoreComments: true}],
      "quote-props": [1, "consistent-as-needed"],
      "no-cond-assign": [2, "except-parens"],
      "radix": 0,
      "space-infix-ops": 0,
      "no-unused-vars": [1, {"vars": "local", "args": "none"}],
      "default-case": 0,
      "no-else-return": 0,
      "no-param-reassign": 0,
      "quotes": 0,
      "indent": [2, 2],
      "linebreak-style": ["error", "unix"],
      "comma-dangle": ["error", {
        "arrays": "only-multiline",
        "objects": "only-multiline",
        "imports": "only-multiline",
        "exports": "only-multiline",
        "functions": "ignore",
      }],
      "no-console": "off",
      "arrow-body-style": [2, "as-needed"],
    }
  }
};
