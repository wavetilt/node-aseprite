const fs = require('fs');
const YAML = require('yaml');

const KaitaiStructCompiler = require('kaitai-struct-compiler');
const compiler = new KaitaiStructCompiler();

console.log('Kaitai Struct Compiler Version:', compiler.version);
console.log('Kaitai Struct Compiler Build date:', compiler.buildDate);
console.log('Kaitai Struct Compiler Supported languages:', compiler.languages.join(', '));

const ksyYaml = fs.readFileSync('aseprite.ksy', 'utf-8');
const ksy = YAML.parse(ksyYaml);
compiler.compile('javascript', ksy, null, false).then(files => {
	console.log('Generated:', ...Object.keys(files));

	if (!files['Aseprite.js']) {
		throw new Error('Did not generated expected file: Aseprite.js');
	}

	console.log('Writing aseprite.js...');
	fs.writeFileSync('aseprite.js', files['Aseprite.js']);

	console.log('DONE');
});
