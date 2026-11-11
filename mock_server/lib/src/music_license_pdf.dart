import 'dart:convert';
import 'dart:typed_data';

/// Songlet commercial-license text (PRD §9.1). The scope sentence is kept on a
/// single line so it can be matched verbatim in the uncompressed PDF.
const String licenseScope =
    'personal, social media, advertising, podcasts; '
    'not registrable as an exclusive copyright work';
const String licenseAttribution =
    'Generated with Google Lyria 3 · contains SynthID watermark · AI generated';

/// Builds a small, valid single-page PDF 1.4 (Helvetica, WinAnsi, one
/// uncompressed content stream, exact xref offsets) — no dependencies.
Uint8List buildLicensePdf({
  required String jobId,
  required DateTime generatedAt,
  required DateTime issuedAt,
  required String model,
}) {
  final lines = <(String font, double size, String text)>[
    ('F2', 22, 'Songlet commercial license'),
    ('F1', 10, ''),
    ('F1', 11, 'MusicJob ID (interaction id): $jobId'),
    ('F1', 11, 'Generated: ${_iso(generatedAt)}'),
    ('F1', 11, 'Model: $model'),
    ('F1', 11, 'License issued: ${_iso(issuedAt)}'),
    ('F1', 10, ''),
    ('F2', 12, 'Scope'),
    ('F1', 9.5, licenseScope),
    ('F1', 10, ''),
    ('F1', 10, licenseAttribution),
    ('F1', 10, ''),
    (
      'F1',
      9,
      'The generated work belongs to the licensee under the Gemini API terms.',
    ),
    ('F1', 9, 'Songlet grants this license for the job above only.'),
  ];

  final content = StringBuffer('BT\n50 740 Td\n');
  var first = true;
  for (final (font, size, text) in lines) {
    if (!first) content.write('0 -${(size * 1.6).toStringAsFixed(1)} Td\n');
    first = false;
    content.write('/$font $size Tf\n(${_escape(text)}) Tj\n');
  }
  content.write('ET\n');
  final stream = latin1.encode(content.toString());

  final objects = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
        '/Resources << /Font << /F1 4 0 R /F2 5 0 R >> >> /Contents 6 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
        '/Encoding /WinAnsiEncoding >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold '
        '/Encoding /WinAnsiEncoding >>',
    '', // 6: content stream, written below
    '<< /Title (Songlet commercial license ${_escape(jobId)}) '
        '/Producer (Songlet mock server) >>',
  ];

  final out = BytesBuilder();
  final offsets = <int>[];
  void write(String s) => out.add(latin1.encode(s));

  write('%PDF-1.4\n');
  out.add(const [0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A]); // binary marker
  for (var i = 0; i < objects.length; i++) {
    offsets.add(out.length);
    final n = i + 1;
    if (n == 6) {
      write('6 0 obj\n<< /Length ${stream.length} >>\nstream\n');
      out.add(stream);
      write('endstream\nendobj\n');
    } else {
      write('$n 0 obj\n${objects[i]}\nendobj\n');
    }
  }
  final xrefAt = out.length;
  write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
  for (final o in offsets) {
    write('${o.toString().padLeft(10, '0')} 00000 n \n');
  }
  write(
    'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R /Info 7 0 R >>\n'
    'startxref\n$xrefAt\n%%EOF\n',
  );
  return out.toBytes();
}

String _iso(DateTime t) => '${t.toUtc().toIso8601String().split('.').first}Z';

/// PDF literal-string escaping; non-Latin-1 characters degrade to `?`.
String _escape(String s) {
  final sb = StringBuffer();
  for (final r in s.runes) {
    if (r == 0x28 || r == 0x29 || r == 0x5C) {
      sb.write('\\${String.fromCharCode(r)}');
    } else if (r < 0x20 || r > 0xFF) {
      sb.write('?');
    } else {
      sb.writeCharCode(r);
    }
  }
  return sb.toString();
}
