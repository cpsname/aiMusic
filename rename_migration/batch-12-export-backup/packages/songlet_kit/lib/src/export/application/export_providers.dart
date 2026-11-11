import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';

import '../../creation/application/creation_providers.dart';
import '../../library/application/library_providers.dart';
import '../../platform/application/platform_providers.dart';
import '../data/license_repository_impl.dart';
import '../domain/license_repository.dart';
import 'export_service.dart';

final licenseRepositoryProvider = Provider<LicenseRepository>(
  (ref) => LicenseRepositoryImpl(ref.watch(apiDioProvider)),
);

final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(
    audio: ref.watch(audioStoreProvider),
    licenses: ref.watch(licenseRepositoryProvider),
    exporter: ref.watch(fileExporterProvider),
    jobs: ref.watch(generationRepositoryProvider),
  ),
);
