const Aseprite = require('./aseprite');
const KaitaiStream = require('kaitai-struct/KaitaiStream');

const cleanProps = [
	'_io',
	'_parent',
	'_root',
	'_dataView',
	'_byteLength'
];

function parse(content) {
	const ase = new Aseprite(new KaitaiStream(content));
	return ase;
}

function clean(obj) {
	if (typeof obj === 'object' && obj !== null) {
		if (Array.isArray(obj)) {
			for (const v of obj) {
				clean(v);
			}
		} else {
			for (const prop of cleanProps) {
				delete obj[prop];
			}

			for (const key of Object.keys(obj)) {
				clean(obj[key]);
			}
		}
	}

	return obj;
}

exports.parse = parse;
exports.clean = clean;

exports.default = exports;
