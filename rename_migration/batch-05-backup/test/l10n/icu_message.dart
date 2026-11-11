/// Parses ICU messages with gen-l10n's default use-escaping: false.
class IcuMessage {
  IcuMessage(this.source) {
    _message(nested: false);
  }
  final String source;
  final Set<String> placeholders = {};
  final Map<String, String> selectors = {};
  int _offset = 0;
  Never _error(String reason) => throw FormatException(reason, source, _offset);
  void _space() {
    while (_offset < source.length && source[_offset].trim().isEmpty) {
      _offset++;
    }
  }

  void _expect(String token) {
    _space();
    if (!source.startsWith(token, _offset)) _error('Expected $token');
    _offset += token.length;
  }

  String _identifier() {
    _space();
    final match = RegExp(
      r'[A-Za-z][A-Za-z0-9_]*',
    ).matchAsPrefix(source, _offset);
    if (match == null) _error('Expected an ASCII ICU identifier');
    _offset = match.end;
    return match[0]!;
  }

  void _message({required bool nested}) {
    while (_offset < source.length) {
      if (source[_offset] == '}') {
        if (!nested) _error('Unexpected closing brace');
        return;
      }
      if (source[_offset] == '{') {
        _argument();
      } else {
        _offset++;
      }
    }
    if (nested) _error('Unclosed branch');
  }

  void _argument() {
    _expect('{');
    final name = _identifier();
    placeholders.add(name);
    _space();
    if (source.startsWith('}', _offset)) {
      _offset++;
      return;
    }
    _expect(',');
    final kind = _identifier();
    if (kind != 'plural' && kind != 'select') {
      _error('Unsupported selector $kind');
    }
    if (selectors[name] != null && selectors[name] != kind) {
      _error('Inconsistent selector for $name');
    }
    selectors[name] = kind;
    _expect(',');
    final cases = <String>{};
    while (true) {
      _space();
      if (_offset >= source.length) _error('Unclosed selector');
      if (source[_offset] == '}') break;
      String selector;
      if (source[_offset] == '=') {
        _offset++;
        final number = RegExp(r'\d+').matchAsPrefix(source, _offset);
        if (number == null || kind != 'plural') {
          _error('Invalid exact plural case');
        }
        _offset = number.end;
        selector = '=${number[0]}';
      } else {
        selector = _identifier();
        if (kind == 'plural' &&
            !{
              'zero',
              'one',
              'two',
              'few',
              'many',
              'other',
            }.contains(selector)) {
          _error('Invalid plural case $selector');
        }
      }
      if (!cases.add(selector)) _error('Duplicate case $selector');
      _expect('{');
      _message(nested: true);
      _expect('}');
    }
    if (!cases.contains('other')) _error('Missing other case');
    _expect('}');
  }
}
