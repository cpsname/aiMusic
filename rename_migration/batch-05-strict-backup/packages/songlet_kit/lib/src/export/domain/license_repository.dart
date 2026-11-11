import 'dart:typed_data';

import 'package:meta/meta.dart';

/// The commercial license of one work (PRD F09 / §9.1): the PDF plus the
/// identifiers shown on the download page (docs/ui P11). [id] and [issuedAt]
/// come from the `X-License-Id` / `X-License-Issued-At` response headers
/// (contract extension); older servers omit them.
@immutable
class LicenseDocument {
  const LicenseDocument({required this.pdf, this.id, this.issuedAt});

  final Uint8List pdf;
  final String? id;
  final DateTime? issuedAt;
}

/// `GET /v1/license/{job_id}` — refused with `DOWNLOAD_LOCKED` for free
/// accounts and refunded purchases (PRD §8.4), which is what gates downloads.
abstract interface class LicenseRepository {
  Future<LicenseDocument> license(String jobId);
}
