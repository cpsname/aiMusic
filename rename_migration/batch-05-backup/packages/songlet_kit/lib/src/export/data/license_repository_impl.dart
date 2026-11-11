import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:infra_core/infra_core.dart';

import '../domain/license_repository.dart';

/// `GET /v1/license/{job_id}` (PDF bytes). The success body is not an
/// envelope; an error body is a JSON envelope inside the byte response, decoded
/// here into the typed [ApiError] the rest of the chain expects.
class LicenseRepositoryImpl implements LicenseRepository {
  LicenseRepositoryImpl(this._apiDio);

  final Dio _apiDio;

  @override
  Future<LicenseDocument> license(String jobId) async {
    try {
      final response = await _apiDio.get<List<int>>(
        '/license/$jobId',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data ?? const <int>[]);
      final envelope = _envelope(bytes);
      if (envelope != null && !envelope.isSuccess) throw envelope.toApiError();
      return LicenseDocument(
        pdf: bytes,
        id: response.headers.value(licenseIdHeader),
        issuedAt: _issuedAt(response.headers.value(licenseIssuedAtHeader)),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final envelope = data is List<int> ? _envelope(data) : null;
      if (envelope != null && !envelope.isSuccess) {
        throw e.copyWith(error: envelope.toApiError());
      }
      rethrow;
    }
  }

  static const String licenseIdHeader = 'x-license-id';
  static const String licenseIssuedAtHeader = 'x-license-issued-at';

  /// ISO-8601 or Unix milliseconds.
  static DateTime? _issuedAt(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final ms = int.tryParse(raw);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true) : DateTime.tryParse(raw)?.toUtc();
  }

  static ApiEnvelope? _envelope(List<int> bytes) {
    if (bytes.isEmpty || bytes.first != 0x7b) return null; // '{'
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      return ApiEnvelope.looksLikeEnvelope(decoded)
          ? ApiEnvelope.fromMap(decoded as Map)
          : null;
    } on FormatException {
      return null;
    }
  }
}
