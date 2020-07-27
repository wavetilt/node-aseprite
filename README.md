# node-aseprite

Node.js implementation of Aseprite file format parsing using Kaitai struct definitions.

## Installation

```console
$ npm install --save aseprite
```

## Usage

```javascript
const Aseprite = require('aseprite');

const fs = require('fs');
const contents = fs.readFileSync('my-sprite.ase');

const ase = Aseprite.parse(contents);

// Optionally, remove all of the meta properties from the object if you don't need them.
// Required if you want to serialize to JSON.
const cleanAse = Aseprite.clean(Aseprite.parse(contents));

// Dump it to the console
console.log(require('util').inspect(cleanAse, {depth: null, colors: true}));
```

# License
Copyright &copy; 2020, Wavetilt LLC. Released under the [MIT License](LICENSE).
