const Aseprite = require('./aseprite');
const KaitaiStream = require('kaitai-struct/KaitaiStream');

function parse(content) {
	const ase = new Aseprite(new KaitaiStream(content));
	return ase;
}

exports.parse = parse;

exports.default = exports;
