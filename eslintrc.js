module.exports = {
  "root": true,
  "extends":"eslint:recommended",
  "rules": {
    "indent": ["error", 4],
    "linebreak-style": ["error", "unix"],
    "quotes": ["error", "double"],
    "semi": ["error", "always"],
 
    // override default rules
    "comma-dangle": ["error", "always"],
    "no-cond-assign": ["error", "always"],

    // disable rules from base configurations
    "no-console": "off"
    
  }
  
}
