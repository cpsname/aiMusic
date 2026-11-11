import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';

import '../../creation/application/music_creation_providers.dart';
import '../../library/application/music_library_providers.dart';
import '../../platform/application/music_platform_providers.dart';
import '../data/music_license_repository_impl.dart';
import '../domain/music_license_repository.dart';
import 'music_export_service.dart';

final licenseRepositoryProvider = Provider<MusicLicenseRepository>(
  (ref) => MusicLicenseRepositoryImpl(ref.watch(apiDioProvider)),
);

final exportServiceProvider = Provider<MusicExportService>(
  (ref) => MusicExportService(
    audio: ref.watch(audioStoreProvider),
    licenses: ref.watch(licenseRepositoryProvider),
    exporter: ref.watch(fileExporterProvider),
    jobs: ref.watch(generationRepositoryProvider),
  ),
);
