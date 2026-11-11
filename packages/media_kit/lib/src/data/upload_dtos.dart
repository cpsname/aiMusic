import '../domain/upload_models.dart';
import 'json_coerce.dart';

String _contentKindWire(UploadContentKind kind) => switch (kind) {
      UploadContentKind.image => 'image',
      UploadContentKind.video => 'video',
      UploadContentKind.audio => 'audio',
      UploadContentKind.document => 'document',
    };

String _accessLevelWire(UploadAccessLevel level) => switch (level) {
      UploadAccessLevel.private => 'private',
      UploadAccessLevel.unlisted => 'unlisted',
      UploadAccessLevel.public => 'public',
    };

/// Body for `POST /v1/uploads/sign`.
Map<String, Object?> signRequestJson(UploadSpec spec) => <String, Object?>{
      'mime_type': spec.mimeType,
      'size': spec.sizeBytes,
      'filename': spec.filename,
      'file_hash': spec.fileHash,
      'access_level': _accessLevelWire(spec.accessLevel),
      if (spec.contentKind != null)
        'content_type': _contentKindWire(spec.contentKind!),
    };

/// Parses the (envelope-unwrapped) `sign` response body into a [UploadTicket].
UploadTicket ticketFromJson(Map<String, Object?> json) => UploadTicket(
      bid: asString(json['bid']),
      putUrl: asString(json['put_url']),
      publicUrl: asString(json['public_url']),
      key: asString(json['key']),
      dedupHit: asBool(json['dedup_hit']),
      expiresAt: asEpoch(json['expires_at']),
    );

/// Body for `POST /v1/uploads/finalize`.
Map<String, Object?> finalizeRequestJson(String bid) => <String, Object?>{
      'bid': bid,
    };

/// Parses the (envelope-unwrapped) `finalize` response (the Asset DTO).
UploadedAsset assetFromJson(Map<String, Object?> json) => UploadedAsset(
      bid: asString(json['bid']),
      url: asString(json['url']),
      fileName: asString(json['file_name']),
      fileSize: asInt(json['file_size']),
      mimeType: asString(json['mime_type']),
      contentType: asString(json['content_type']),
      accessLevel: asString(json['access_level'], fallback: 'private'),
      tags: asStringList(json['tags']),
      groupName: asString(json['group_name']),
      dedupHit: asBool(json['dedup_hit']),
      expiresAt: asEpoch(json['expires_at']),
      createdAt: asEpoch(json['created_at']),
    );
