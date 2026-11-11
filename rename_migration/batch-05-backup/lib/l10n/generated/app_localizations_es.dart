// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get startupLoading => 'Afinando…';

  @override
  String get commonErrorTitle => 'Algo salió mal';

  @override
  String get updateRequiredTitle => 'Actualización necesaria';

  @override
  String get updateRequiredMessage =>
      'Se necesita una versión nueva para continuar.';

  @override
  String get updateNow => 'Actualizar ahora';

  @override
  String get maintenanceTitle => 'Mantenimiento programado';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Volveremos en unos $minutesString min, aproximadamente';
  }

  @override
  String get featureUnavailable =>
      'Esta función no está disponible temporalmente.';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navStore => 'Tienda';

  @override
  String get navUpload => 'Subir';

  @override
  String get uploadTitle => 'Subidas';

  @override
  String get uploadSubtitle =>
      'Carga directa a R2 con URL prefirmada, hash, deduplicación instantánea y progreso.';

  @override
  String get uploadPick => 'Elegir imagen y subir';

  @override
  String get uploadAgain => 'Subir otra';

  @override
  String get uploadPhaseHashing => 'Calculando hash…';

  @override
  String get uploadPhaseSigning => 'Solicitando permiso de carga…';

  @override
  String uploadPhaseUploading(String percent) {
    return 'Subiendo $percent';
  }

  @override
  String get uploadPhaseFinalizing => 'Finalizando…';

  @override
  String get uploadDone => 'Archivo subido.';

  @override
  String get uploadDedup =>
      'Instantáneo: este archivo ya existía en el servidor.';

  @override
  String get uploadOpenLink => 'Ver archivo';

  @override
  String get uploadFailed => 'No se pudo subir el archivo.';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'El archivo es demasiado grande (máx. $limitString MB).';
  }

  @override
  String get uploadUnsupportedType => 'Tipo de archivo no compatible.';

  @override
  String get profileGuestTitle => 'Invitado';

  @override
  String get profileGuestSubtitle =>
      'Inicia sesión para conservar tus compras en todos tus dispositivos.';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get profileBalanceLabel => 'Créditos';

  @override
  String get profileAccountId => 'ID de cuenta';

  @override
  String get profileFeaturesLabel => 'Beneficios activos';

  @override
  String get profileNoFeatures => 'Aún no tienes beneficios activos.';

  @override
  String get profileSubscriptionLabel => 'Suscripción';

  @override
  String get profileManageSubscription => 'Administrar suscripción';

  @override
  String get subscriptionActive => 'Activa';

  @override
  String get subscriptionInactive => 'Ninguna';

  @override
  String get profileDeleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountTitle => '¿Eliminar esta cuenta?';

  @override
  String get deleteAccountMessage =>
      'Esta acción no se puede deshacer: esta cuenta, junto con sus créditos y beneficios, quedará inaccesible de forma permanente y se creará una cuenta nueva. Eliminar la cuenta no cancela una suscripción activa del App Store: adminístrala en la configuración de tu cuenta del App Store o vuelve a vincularla más tarde con Restaurar compras.';

  @override
  String get deleteAccountConfirm => 'Eliminar';

  @override
  String get deleteAccountWorking => 'Eliminando cuenta…';

  @override
  String get deleteAccountDone => 'Cuenta eliminada.';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Miembro desde $dateString';
  }

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginUsername => 'Nombre de usuario';

  @override
  String get loginPassword => 'Contraseña';

  @override
  String get loginSubmit => 'Iniciar sesión';

  @override
  String get paywallTitle => 'Obtén la canción completa';

  @override
  String get paywallSubtitle =>
      'Convierte tu vista previa en una canción de 2 minutos con letra, tuya para descargar y usar.';

  @override
  String get paywallRestore => 'Restaurar compras';

  @override
  String get paywallAutoRenewNotice =>
      'El pago se cargará a tu cuenta de Apple al confirmar la compra. Las suscripciones se renuevan automáticamente al mismo precio y por el mismo periodo, a menos que se cancelen al menos 24 horas antes de que termine el periodo actual. La prueba gratis se convierte en una suscripción de pago al terminar. Administra o cancela cuando quieras en la configuración de tu cuenta del App Store.';

  @override
  String get paywallContinue => 'Continuar';

  @override
  String get paywallFreeTrial => 'Prueba gratis';

  @override
  String get paywallOffer => 'Oferta';

  @override
  String get paywallManage => 'Administrar';

  @override
  String get paywallTermsOfUse => 'Términos de uso';

  @override
  String get paywallPrivacyPolicy => 'Política de privacidad';

  @override
  String get paywallSubscriptionTerms => 'Términos de la suscripción';

  @override
  String get commonLinkError => 'No se pudo abrir el enlace.';

  @override
  String get commonError => 'Algo salió mal.';

  @override
  String get commonNetworkError =>
      'Error de red: revisa tu conexión e inténtalo de nuevo.';

  @override
  String get commonOfflineError =>
      'Parece que no tienes conexión. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get networkErrorTitle => 'Problema de conexión';

  @override
  String get configErrorTitle => 'Problema de configuración de la app';

  @override
  String get configErrorMessage =>
      'Esta versión no puede conectarse con nuestro servicio. Actualiza la app desde el App Store o vuelve a instalarla. Si el problema continúa, contacta a soporte.';

  @override
  String get commonAuthError => 'Tu sesión expiró. Vuelve a iniciar sesión.';

  @override
  String get paywallProductsErrorTitle => 'No se pudieron cargar los productos';

  @override
  String get paywallNoProducts =>
      'No hay productos disponibles en este momento.';

  @override
  String get paywallPurchaseSuccess => '¡Compra completada! Disfrútala.';

  @override
  String get paywallProcessing => 'Procesando tu compra…';

  @override
  String get paywallVerifying => 'Verificando tu compra…';

  @override
  String get paywallPurchaseFailed => 'No se pudo completar la compra.';

  @override
  String get paywallRestoreStarted => 'Restaurando tus compras…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se restauraron $countString compras.',
      one: 'Se restauró $countString compra.',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing => 'No hay compras para restaurar.';

  @override
  String get paywallDeferred =>
      'Esperando aprobación. Terminaremos en cuanto se apruebe.';

  @override
  String get paywallAlreadySubscribed => 'Ya tienes una suscripción.';

  @override
  String get paywallBillingRetry =>
      'Actualiza tu método de pago para conservar tu suscripción.';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Prueba gratis de $daysString días';
  }

  @override
  String get cycleOneTime => 'pago único';

  @override
  String get cycleWeekly => '/ semana';

  @override
  String get cycleMonthly => '/ mes';

  @override
  String get cycleQuarterly => '/ trimestre';

  @override
  String get cycleSemiAnnual => '/ 6 meses';

  @override
  String get cycleAnnual => '/ año';

  @override
  String get cycleLifetime => 'de por vida';

  @override
  String get navCreate => 'Crear';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navSettings => 'Configuración';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonBack => 'Atrás';

  @override
  String get createTitle => '¿Para quién es esta canción?';

  @override
  String get occasionBirthday => 'Cumpleaños';

  @override
  String get occasionBirthdayHint => 'Una canción alegre para su gran día';

  @override
  String get occasionAnniversary => 'Aniversario';

  @override
  String get occasionAnniversaryHint => 'Celebren su historia juntos';

  @override
  String get occasionConfession => 'Declaración de amor';

  @override
  String get occasionConfessionHint => 'Di lo que siente tu corazón';

  @override
  String get occasionWedding => 'Boda';

  @override
  String get occasionWeddingHint => 'Una canción para el día más especial';

  @override
  String get occasionMemorial => 'En memoria';

  @override
  String get occasionMemorialHint => 'Honra a alguien que quieres';

  @override
  String get occasionFestival => 'Festividad';

  @override
  String get occasionFestivalHint =>
      'Buenos deseos para una temporada especial';

  @override
  String get occasionBrand => 'Jingle de marca';

  @override
  String get occasionBrandHint => 'Una melodía pegajosa para tu marca';

  @override
  String get occasionSoundtrack => 'Música para video';

  @override
  String get occasionSoundtrackHint => 'Música que va con tu historia';

  @override
  String get festivalNewYear => 'Año Nuevo';

  @override
  String get festivalThanksgiving => 'Día de Acción de Gracias';

  @override
  String get festivalDiwali => 'Diwali';

  @override
  String get festivalCarnival => 'Carnaval';

  @override
  String get festivalEid => 'Eid';

  @override
  String get festivalLunarNewYear => 'Año Nuevo Lunar';

  @override
  String get regionTitle => '¿Dónde se va a escuchar?';

  @override
  String get regionSearchHint => 'Buscar país';

  @override
  String get regionLanguageSheetTitle => 'Idioma de la letra';

  @override
  String get countryUS => 'Estados Unidos';

  @override
  String get countryGB => 'Reino Unido';

  @override
  String get countryCA => 'Canadá';

  @override
  String get countryAU => 'Australia';

  @override
  String get countryDE => 'Alemania';

  @override
  String get countryFR => 'Francia';

  @override
  String get countryJP => 'Japón';

  @override
  String get countryKR => 'Corea del Sur';

  @override
  String get countryBR => 'Brasil';

  @override
  String get countryMX => 'México';

  @override
  String get countryIN => 'India';

  @override
  String get countryID => 'Indonesia';

  @override
  String get countryVN => 'Vietnam';

  @override
  String get countryTR => 'Turquía';

  @override
  String get languageEn => 'Inglés';

  @override
  String get languageFr => 'Francés';

  @override
  String get languageDe => 'Alemán';

  @override
  String get languageJa => 'Japonés';

  @override
  String get languageKo => 'Coreano';

  @override
  String get languagePtBR => 'Portugués (Brasil)';

  @override
  String get languageEsMX => 'Español (México)';

  @override
  String get languageHi => 'Hindi';

  @override
  String get languageId => 'Indonesio';

  @override
  String get languageVi => 'Vietnamita';

  @override
  String get languageTr => 'Turco';

  @override
  String get languageZhHans => 'Chino (simplificado)';

  @override
  String get languageZhHant => 'Chino (tradicional)';

  @override
  String get inputNameLabel => 'Su nombre';

  @override
  String get inputNameOptionalLabel => 'Nombre (opcional)';

  @override
  String get inputNameHint => 'p. ej., Alex';

  @override
  String get inputKeywordsLabel => 'Tres palabras que la describan';

  @override
  String get inputLyricsHint => '[Verse] …\n[Chorus] …';

  @override
  String lyricsCounter(int count, int limit) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '$countString / $limitString';
  }

  @override
  String get inputLyricsOwnership =>
      'Esta letra es mía o tengo derecho a usarla';

  @override
  String get issueRecipientMissing => 'Agrega su nombre.';

  @override
  String get issueRecipientTooLong =>
      'Los nombres pueden tener hasta 24 caracteres.';

  @override
  String get issueBriefMissing =>
      'Cuéntanos sobre la canción: unas palabras, letra o fotos.';

  @override
  String get issueDescriptionMissing =>
      'Esta idea necesita tus palabras: escribe una frase sobre la canción.';

  @override
  String get generatingBackToEdit => 'Volver a editar';

  @override
  String get issueKeywordTooLong =>
      'Cada palabra puede tener hasta 20 caracteres.';

  @override
  String get issueTooManyKeywords => 'Usa hasta tres palabras.';

  @override
  String get issueArtistName =>
      'No se pueden usar nombres de artistas; mejor describe el sentimiento.';

  @override
  String get issueStyleImitation =>
      'No podemos imitar a un cantante ni a una banda. Mejor describe el ambiente.';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'La letra puede tener hasta $limitString caracteres.';
  }

  @override
  String get issueLyricsNotOriginal =>
      'Esta letra se parece a una canción existente. Escribe la tuya.';

  @override
  String get issueLyricsOwnership =>
      'Confirma que tienes derecho a usar esta letra.';

  @override
  String get issueTooManyPhotos => 'Elige hasta 10 fotos.';

  @override
  String get photosTitle => 'Elige algunas fotos';

  @override
  String photosCount(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '$countString / $maxString';
  }

  @override
  String get photosPrivacy =>
      'Las fotos se usan una sola vez para escribir la canción y se eliminan de nuestros servidores en un plazo de 24 horas.';

  @override
  String get photosAdd => 'Agregar fotos';

  @override
  String get photosCreate => 'Crear con fotos';

  @override
  String get photosEmpty => 'Elige de 1 a 10 fotos del momento.';

  @override
  String get generatingStepPolishing => 'Puliendo tus palabras en este iPhone…';

  @override
  String get generatingStepUploading => 'Enviando tus fotos…';

  @override
  String get generatingStepSubmitting => 'Enviando al estudio…';

  @override
  String get errorSafetyBlocked =>
      'No podemos crear esta. Prueba con otras palabras y evita nombres de artistas.';

  @override
  String get errorQuotaExhausted =>
      'Ya usaste las canciones de este mes. Agrega un paquete o mejora tu plan.';

  @override
  String get errorUpstreamTimeout =>
      'Está tardando más de lo normal. Seguiremos intentándolo y te avisaremos.';

  @override
  String get errorUpstreamRateLimited =>
      'Se están creando muchas canciones en este momento. La tuya está en la fila.';

  @override
  String get errorAttestFailed => 'Actualiza Songlet desde el App Store.';

  @override
  String get errorImageRejected =>
      'Una de estas fotos no se puede usar. Prueba con otra.';

  @override
  String get errorNetworkOffline =>
      'No tienes conexión. Tu biblioteca sigue funcionando.';

  @override
  String get errorDownloadLocked =>
      'Esta canción no se puede descargar: la compra con la que se creó se reembolsó o tu plan terminó. Aún puedes reproducirla.';

  @override
  String get errorJobAlreadyFinished => 'Ya terminó, no hay nada que cancelar.';

  @override
  String get errorMvSongNotReady =>
      'Esta canción aún no está lista para un vídeo.';

  @override
  String get errorMvSongTooLong =>
      'Esta canción es demasiado larga para un vídeo completo; prueba con un vídeo del estribillo.';

  @override
  String get errorMvSongExpired =>
      'Esta canción ha caducado. Genérala de nuevo para hacer un vídeo.';

  @override
  String get errorMvNotFound => 'Este vídeo ya no está disponible.';

  @override
  String get errorMvPhotosExpired =>
      'Esas fotos han caducado; elígelas de nuevo.';

  @override
  String get errorMvRenderFailed =>
      'No pudimos terminar este vídeo. Tus créditos han vuelto; inténtalo de nuevo.';

  @override
  String get mvHubTitle => 'Hacer un vídeo';

  @override
  String mvHubSubtitle(String title) {
    return 'Convierte «$title» en un vídeo musical.';
  }

  @override
  String get mvLevelLyricVideo => 'Vídeo con letra';

  @override
  String get mvLevelLyricHint => 'Una escena fija con tu letra';

  @override
  String get mvLevelChorus => 'Vídeo del estribillo';

  @override
  String get mvLevelChorusHint =>
      '30 segundos de tu estribillo, rodados por IA';

  @override
  String get mvLevelFull => 'Vídeo de la canción completa';

  @override
  String get mvLevelFullHint => 'Toda la canción, escena a escena';

  @override
  String mvPriceCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: '$creditsString créditos',
      one: '$creditsString crédito',
    );
    return '$_temp0';
  }

  @override
  String mvAvailableCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: 'Tienes $creditsString créditos',
      one: 'Tienes $creditsString crédito',
    );
    return '$_temp0';
  }

  @override
  String mvGapCredits(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: 'Faltan $creditsString créditos',
      one: 'Falta $creditsString crédito',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => 'Consultando el precio…';

  @override
  String get mvOptionsHeader => 'Opciones';

  @override
  String get mvAspectLabel => 'Formato';

  @override
  String get mvAspectPortrait => 'Vertical';

  @override
  String get mvAspectLandscape => 'Horizontal';

  @override
  String get mvAspectSquare => 'Cuadrado';

  @override
  String get mvQualityLabel => 'Calidad';

  @override
  String get mvQualityStandard => 'Estándar';

  @override
  String get mvQualityHigh => 'Alta';

  @override
  String get mvSubtitlesLabel => 'Letra en pantalla';

  @override
  String get mvPhotosLabel => 'Fotos de referencia';

  @override
  String get mvPhotosHint =>
      'Marcan el ambiente y los colores; no se usan las caras';

  @override
  String mvPhotosCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fotos',
      one: '$countString foto',
    );
    return '$_temp0';
  }

  @override
  String get mvChorusLabel => 'Estribillo';

  @override
  String get mvChorusAuto => 'Se detecta automáticamente';

  @override
  String get mvChorusCustom => 'Elegir el momento';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => 'Hacer el vídeo';

  @override
  String get mvBuyPack => 'Consigue el pack y hazlo';

  @override
  String get mvSongLocked => 'Tu canción se ha guardado para el vídeo.';

  @override
  String get mvGeneratingTitle => 'Haciendo tu vídeo…';

  @override
  String get mvStageQueued => 'Esperando para empezar';

  @override
  String get mvStageSlicing => 'Eligiendo los momentos';

  @override
  String get mvStageStoryboarding => 'Escribiendo el guion gráfico';

  @override
  String get mvStageKeyframing => 'Pintando las escenas';

  @override
  String get mvStageRendering => 'Rodando las escenas';

  @override
  String get mvStageAssembling => 'Montando el vídeo';

  @override
  String get mvStageDone => 'Listo';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Escena $doneString de $totalString';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Suele tardar unos $minutesString minutos';
  }

  @override
  String get mvCancelRequested => 'Se detendrá tras la escena actual…';

  @override
  String get mvCancelTitle => '¿Detener este vídeo?';

  @override
  String get mvCancelQueued => 'Aún no ha empezado, así que no se usará nada.';

  @override
  String get mvCancelStarted =>
      'Ya ha empezado. Las escenas hechas se cobran; el resto se devuelve.';

  @override
  String get mvCancelConfirm => 'Detener vídeo';

  @override
  String get mvCancelled => 'Vídeo detenido';

  @override
  String get mvCancelledRefunded => 'Vídeo detenido: no se usó nada';

  @override
  String get mvNothing => 'No se está haciendo ningún vídeo ahora.';

  @override
  String get mvQuotaTitle => 'No hay créditos suficientes';

  @override
  String get mvAiLabelBurnedIn =>
      'Generado por IA: la insignia forma parte del vídeo';

  @override
  String get mvSave => 'Guardar en Fotos';

  @override
  String get mvSaveFiles => 'Guardar en Archivos';

  @override
  String get mvShareText => 'Hice este vídeo musical con Songlet 🎬';

  @override
  String get mvMissing => 'Este vídeo ya no está en este dispositivo.';

  @override
  String get mvDeleteTitle => '¿Eliminar este vídeo?';

  @override
  String get mvDeleteBody => 'Se elimina de este dispositivo.';

  @override
  String get mvDeleted => 'Vídeo eliminado';

  @override
  String get mvProvenance =>
      'Hecho con Google Lyria 3 y modelos de vídeo con IA · Generado por IA';

  @override
  String get detailVideos => 'Vídeos';

  @override
  String get detailMakeVideo => 'Hacer un vídeo';

  @override
  String get mvStatusReady => 'Listo';

  @override
  String get mvStatusPending => 'Haciéndose…';

  @override
  String get mvStatusFailed => 'No terminó';

  @override
  String get mvPackTitle => 'Vídeo musical';

  @override
  String get mvPackChorusSubtitle => 'Un vídeo del estribillo';

  @override
  String get mvPackFullSubtitle => 'Un vídeo de la canción completa';

  @override
  String get paywallMvHeroTitle => 'Hazlo vídeo';

  @override
  String get paywallMvHeroSubtitle =>
      'Créditos para un vídeo musical de tu canción: para guardar y compartir.';

  @override
  String get playerAiGenerated => 'Generado con IA';

  @override
  String get playerLoop => 'Repetir';

  @override
  String get playerPlay => 'Reproducir';

  @override
  String get playerPause => 'Pausar';

  @override
  String get playerPreviewLabel => 'Vista previa de 30 segundos';

  @override
  String playerTitleFor(String name) {
    return 'Para $name';
  }

  @override
  String get downloadSaved => 'Se guardó en Archivos.';

  @override
  String get shareComposing => 'Creando tu tarjeta para compartir…';

  @override
  String get shareFailed => 'No se pudo crear la tarjeta para compartir.';

  @override
  String get shareText => 'Hice esta canción con Songlet 🎵';

  @override
  String get paywallBestValue => 'Más conveniente';

  @override
  String get paywallStartTrial => 'Comenzar prueba gratis';

  @override
  String get paywallClose => 'Cerrar';

  @override
  String get paywallSeePlans => 'Ver suscripciones';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tu plan está activo: te quedan $countString canciones completas en este periodo.',
      one:
          'Tu plan está activo: te queda $countString canción completa en este periodo.',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => 'Aquí vivirán tus canciones.';

  @override
  String get libraryEmptyAction => 'Crea tu primera canción';

  @override
  String get libraryPending => 'Componiendo…';

  @override
  String get libraryPreviewBadge => 'Vista previa';

  @override
  String get librarySongBadge => 'Canción completa';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsPlan => 'Tu plan';

  @override
  String get settingsPlanUnavailable =>
      'No se pudo cargar tu plan. Desliza hacia abajo para intentarlo más tarde.';

  @override
  String get tierFree => 'Sin suscripción';

  @override
  String get tierPack => 'Paquetes de canciones';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te quedan $countString canciones completas',
      one: 'Te queda $countString canción completa',
    );
    return '$_temp0';
  }

  @override
  String settingsClipsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te quedan $countString vistas previas',
      one: 'Te queda $countString vista previa',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Se restablece el $dateString';
  }

  @override
  String get settingsUpgrade => 'Mejorar plan';

  @override
  String get appTagline => 'Canciones para quienes amas';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonMore => 'Más';

  @override
  String get commonCopy => 'Copiar';

  @override
  String get commonCopied => 'Copiado';

  @override
  String get commonNotNow => 'Ahora no';

  @override
  String get commonLearnMore => 'Más información';

  @override
  String get commonSeeAll => 'Ver todo';

  @override
  String get commonKeepGoing => 'Seguir';

  @override
  String get composerHint => 'Describe la canción que quieres';

  @override
  String get composerAddPhotos => 'Agregar fotos';

  @override
  String get composerSourceMusicHint => 'Descríbela con tus palabras';

  @override
  String get composerDictate => 'Dictar';

  @override
  String get composerStopDictation => 'Detener dictado';

  @override
  String get lengthPreview => 'Adelanto';

  @override
  String get lengthFull => 'Canción completa';

  @override
  String get paramLength => 'Duración';

  @override
  String get paramVocals => 'Voz';

  @override
  String get paramGenre => 'Género';

  @override
  String templatePlaySample(String name) {
    return 'Reproducir una muestra de $name';
  }

  @override
  String get templatePauseSample => 'Pausar la muestra';

  @override
  String get lengthShort => 'Corta';

  @override
  String get lengthShortHint => 'Adelanto de 30 segundos';

  @override
  String get lengthStandard => 'Estándar';

  @override
  String get lengthStandardHint => 'unos 2 minutos, Pro';

  @override
  String get vocalsCustom => 'Automático';

  @override
  String get vocalsCustomHint => 'según tu descripción';

  @override
  String get vocalsCustomDetail => 'El estilo vocal sigue tu descripción.';

  @override
  String get vocalsOn => 'Con voz';

  @override
  String get vocalsInstrumental => 'Instrumental';

  @override
  String vocalsLyricsIn(String language) {
    return 'Letra en $language';
  }

  @override
  String get genreCustom => 'Automático';

  @override
  String get genreCustomHint => 'según tu descripción';

  @override
  String genrePopularIn(String country) {
    return 'Popular en $country';
  }

  @override
  String get genreAll => 'Todos los géneros';

  @override
  String get regionHelper =>
      'Cambia los 3 géneros recomendados y el idioma de la letra';

  @override
  String regionLyricsRow(String language) {
    return 'Idioma de la letra: $language';
  }

  @override
  String get regionNoMatch => 'Ningún país coincide';

  @override
  String get keywordAdd => 'Agregar una palabra';

  @override
  String keywordRemove(String word) {
    return 'Quitar $word';
  }

  @override
  String get nameClear => 'Borrar nombre';

  @override
  String get lyricsOptional => 'Escribe tu propia letra (opcional)';

  @override
  String get issueRecipientArtistName =>
      'No se pueden usar nombres de artistas.';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'La descripción debe tener menos de $limitString caracteres.';
  }

  @override
  String get voiceRecording => 'Grabando…';

  @override
  String get voiceStarting => 'Iniciando…';

  @override
  String get voiceListening => 'Di para quién es y qué le encanta…';

  @override
  String get voiceOnDevice => 'Transcripción en el dispositivo';

  @override
  String get voicePermissionDenied =>
      'Permite el micrófono y el reconocimiento de voz para Songlet en Ajustes para dictar.';

  @override
  String get voiceUnavailable =>
      'El dictado no está disponible para este idioma en este dispositivo.';

  @override
  String get voiceApplied => 'Agregado desde tu voz';

  @override
  String get photoRemove => 'Quitar foto';

  @override
  String generatingTitleFor(String name) {
    return 'Escribiendo la canción de $name…';
  }

  @override
  String get generatingTitleGeneric => 'Escribiendo tu canción…';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Normalmente unos $secondsString segundos';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => 'Progreso';

  @override
  String get generatingGlimpse => 'Un vistazo a tu canción';

  @override
  String get generatingCancelTitle => '¿Detener esta canción?';

  @override
  String get generatingCancelQueued =>
      'Aún no ha empezado, así que no se descontará de tu cupo.';

  @override
  String get generatingCancelStarted =>
      'Ya ha empezado, así que se descuenta de tu cupo.';

  @override
  String get generatingCancelConfirm => 'Detener';

  @override
  String get generatingCancelled => 'Canción detenida';

  @override
  String get generatingCancelledRefunded => 'Canción detenida: no se usó nada';

  @override
  String get queueTitle => 'Se están creando muchas canciones ahora.';

  @override
  String get queueSubtitle => 'La tuya está en la cola.';

  @override
  String get queuePosition => 'Posición';

  @override
  String get queueWait => 'espera estimada';

  @override
  String queueWaitMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '≈ $minutesString min';
  }

  @override
  String get generatingNothing => 'No se está creando ninguna canción ahora.';

  @override
  String get previewGetFull => 'Obtener la canción completa de 2 minutos';

  @override
  String get previewShare => 'Compartir adelanto';

  @override
  String get previewAnother => 'Probar otra versión (usa 1 adelanto)';

  @override
  String get playerPosition => 'Posición de reproducción';

  @override
  String get playerPrevSection => 'Sección anterior';

  @override
  String get playerNextSection => 'Sección siguiente';

  @override
  String get playerShuffle => 'Secciones aleatorias';

  @override
  String get playerRepeat => 'Repetir';

  @override
  String get playerProvenance =>
      'Creada con Google Lyria 3 · marca de agua SynthID · generada por IA';

  @override
  String get playerMissing => 'Esta canción ya no está en este dispositivo.';

  @override
  String get actionDownload => 'Descargar';

  @override
  String get actionShare => 'Compartir';

  @override
  String get actionLicense => 'Licencia';

  @override
  String get actionRegenerate => 'Regenerar';

  @override
  String get actionDetails => 'Detalles';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionVerse => 'Estrofa';

  @override
  String get sectionPreChorus => 'Precoro';

  @override
  String get sectionChorus => 'Coro';

  @override
  String get sectionBridge => 'Puente';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionHook => 'Gancho';

  @override
  String get shareTitle => 'Tarjeta para compartir';

  @override
  String get shareSubtitle => 'Elige un tema y un diseño.';

  @override
  String get shareTheme => 'Tema';

  @override
  String get shareLayout => 'Diseño';

  @override
  String get shareLayoutScene => 'Con ilustración';

  @override
  String get shareLayoutText => 'Solo texto';

  @override
  String get paletteTerracotta => 'Terracota';

  @override
  String get paletteSand => 'Arena';

  @override
  String get paletteOlive => 'Oliva';

  @override
  String get paletteNavy => 'Azul marino';

  @override
  String get shareAction => 'Compartir';

  @override
  String get shareSaveVideo => 'Guardar video';

  @override
  String get shareCopyLyrics => 'Copiar letra';

  @override
  String get shareVideoSaved => 'Guardado en Fotos';

  @override
  String get shareLyricsCopied => 'Letra copiada';

  @override
  String get shareCardTagline => 'Una canción para alguien';

  @override
  String get shareSaveFailed =>
      'No se pudo guardar el video. Permite que Songlet agregue a Fotos en Ajustes.';

  @override
  String get downloadReady => 'Canción completa lista';

  @override
  String get downloadTitle => 'Tuya para siempre';

  @override
  String get downloadIntro =>
      'Tu canción está lista. Descarga el audio en alta calidad y tu licencia comercial abajo.';

  @override
  String get downloadAudioHeader => 'Descargar audio';

  @override
  String get downloadAudioNote => 'Alta calidad';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbps';

  @override
  String get downloadMp3Subtitle => 'Ideal para compartir y escuchar a diario';

  @override
  String get downloadWavTitle => 'WAV · 44.1 kHz (Premier)';

  @override
  String get downloadWavSubtitle => 'La mejor calidad para uso profesional';

  @override
  String get downloadMp3Action => 'Descargar MP3';

  @override
  String get downloadWavAction => 'Descargar WAV';

  @override
  String get downloadLicenseAction => 'Descargar licencia';

  @override
  String get licenseHeader => 'Licencia comercial';

  @override
  String get licenseIncluded => 'Incluida en tu plan';

  @override
  String get licenseNotIncluded => 'Disponible con un plan o paquete';

  @override
  String get licensePdfTitle => 'Licencia comercial (PDF)';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Emitida el $dateString';
  }

  @override
  String licenseId(String id) {
    return 'ID de licencia: $id';
  }

  @override
  String get licenseUsesTitle => 'Puedes usar esta canción para:';

  @override
  String get usePersonal => 'Uso personal';

  @override
  String get usePersonalDetail => 'Regalos, recuerdos, sin fines comerciales';

  @override
  String get useAds => 'Publicidad y marketing';

  @override
  String get useAdsDetail => 'Promociones, campañas pagadas';

  @override
  String get useSocial => 'Redes sociales';

  @override
  String get useSocialDetail => 'TikTok, Instagram, YouTube, etc.';

  @override
  String get usePodcasts => 'Pódcasts y videos';

  @override
  String get usePodcastsDetail => 'Contenido monetizado';

  @override
  String get licenseDetailsNote =>
      'Todos los detalles están en el PDF de la licencia.';

  @override
  String get saveEnjoyHeader => 'Guarda y disfruta';

  @override
  String get saveToFiles => 'Guardar en Archivos';

  @override
  String get addToMusic => 'Agregar a Música';

  @override
  String get synthIdNote =>
      'Esta canción contiene una marca de agua SynthID que la identifica como contenido generado por IA, incluso tras descargarla.';

  @override
  String get wavNeedsPremier => 'Las descargas WAV están incluidas en Premier.';

  @override
  String get wavUnavailable =>
      'Esta canción no tiene archivo WAV. Los archivos WAV se pueden guardar dentro de las 24 horas posteriores a su creación.';

  @override
  String get libraryFilterAll => 'Todas';

  @override
  String get libraryJustBecause => 'Porque sí';

  @override
  String libraryPlay(String title) {
    return 'Reproducir $title';
  }

  @override
  String libraryActions(String title) {
    return 'Acciones para $title';
  }

  @override
  String get libraryDeleteTitle => '¿Eliminar esta canción?';

  @override
  String get libraryDeleteBody =>
      'Se eliminará de este dispositivo. Si la sincronización con iCloud está activada, también de tus otros dispositivos.';

  @override
  String get libraryDeleted => 'Canción eliminada';

  @override
  String get libraryFailed => 'Sin terminar';

  @override
  String get libraryNoMatch => 'Aún no hay canciones para esta ocasión.';

  @override
  String get detailFullGenerated => 'Canción completa generada';

  @override
  String get detailPreviewGenerated => 'Adelanto generado';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Generada el $dateString';
  }

  @override
  String get detailPromptUsed => 'Datos usados';

  @override
  String get detailOccasion => 'Ocasión';

  @override
  String get detailCountry => 'País';

  @override
  String get detailGenre => 'Género';

  @override
  String get detailKeywords => 'Palabras clave';

  @override
  String get detailDescription => 'Descripción';

  @override
  String get detailLyrics => 'Letra';

  @override
  String get detailGenerationId => 'ID de generación';

  @override
  String get detailRegenerate => 'Regenerar con el mismo estilo';

  @override
  String get detailCustomGenre => 'Según la descripción';

  @override
  String get settingsSectionPlan => 'Compras';

  @override
  String get settingsSectionLibrary => 'Biblioteca';

  @override
  String get settingsSectionAbout => 'Información';

  @override
  String get settingsRestore => 'Restaurar compras';

  @override
  String get settingsManage => 'Gestionar suscripción';

  @override
  String get settingsICloud => 'Sincronización con iCloud';

  @override
  String get settingsICloudOn =>
      'Las canciones se sincronizan en tus dispositivos';

  @override
  String get settingsICloudOff => 'Las canciones se quedan en este dispositivo';

  @override
  String get settingsICloudUnavailable =>
      'Inicia sesión en iCloud en Ajustes para sincronizar';

  @override
  String get settingsLyricsLanguage => 'Idioma predeterminado de la letra';

  @override
  String get settingsLyricsLanguageAuto => 'Según el país';

  @override
  String get settingsTerms => 'Términos de uso';

  @override
  String get settingsPrivacy => 'Política de privacidad';

  @override
  String settingsVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get aboutTitle => 'Sobre la generación';

  @override
  String get aboutSubtitle => 'Cómo crea Songlet tus canciones';

  @override
  String get aboutLyriaTitle => 'Con Lyria 3 de Google';

  @override
  String get aboutLyriaBody =>
      'Las canciones se generan con Lyria 3 de Google a través de la API de Gemini. Lyria 3 es un modelo de generación musical que convierte tus ideas en canciones originales.';

  @override
  String get aboutWatermarkTitle => 'Marca de agua integrada';

  @override
  String get aboutWatermarkBody =>
      'Cada canción incluye una marca de agua SynthID de Google. Ayuda a identificar la música generada por IA y no se puede eliminar.';

  @override
  String get aboutImitationTitle => 'Sin imitar a artistas reales';

  @override
  String get aboutImitationBody =>
      'Songlet nunca imita a artistas reales, sus voces ni estilos concretos. Las canciones son originales y se crean a partir de tus ideas, descripciones y fotos.';

  @override
  String get aboutPrivacyTitle => 'Tu privacidad importa';

  @override
  String get aboutPrivacyBody =>
      'Las fotos y descripciones se eliminan de nuestros servidores en un plazo de 24 horas. No guardamos tus imágenes ni descripciones una vez creada tu canción.';

  @override
  String get aboutBanner =>
      'Cada canción que compartes lleva la etiqueta de generada por IA.';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · Creado con Google Lyria 3';
  }

  @override
  String get festivalKicker => 'Vive tu historia';

  @override
  String get festivalComing => '¡ya llega!';

  @override
  String get festivalBody => 'Crea una canción única para celebrarlo.';

  @override
  String festivalCta(String festival) {
    return 'Crear una canción de $festival';
  }

  @override
  String get festivalPickOccasion => 'Elige una ocasión y empieza a crear';

  @override
  String get festivalLanguagesTitle => 'Canciones en tu idioma';

  @override
  String festivalLanguagesBody(String language) {
    return 'Canciones en $language y 12 idiomas más';
  }

  @override
  String get unavailableTitle => 'No disponible temporalmente';

  @override
  String get unavailableMessage =>
      'Songlet no puede crear canciones ahora. Tu biblioteca sigue funcionando: inténtalo de nuevo en un rato.';

  @override
  String get paywallHeroTitle => 'Hazla una canción completa';

  @override
  String get paywallHeroSubtitle =>
      'Convierte tu idea en una canción completa, con mayor calidad y todos los derechos.';

  @override
  String get paywallBenefitSongs => 'Más canciones';

  @override
  String get paywallBenefitQuality => 'Mayor calidad';

  @override
  String get paywallBenefitCommercial => 'Uso comercial';

  @override
  String planSongs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString canciones completas al mes',
      one: '$countString canción completa al mes',
    );
    return '$_temp0';
  }

  @override
  String planPreviews(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString vistas previas al mes',
      one: '$countString vista previa al mes',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'Descarga en MP3';

  @override
  String get planMp3Wav => 'Descarga en MP3 + WAV';

  @override
  String get planLicense => 'Licencia comercial';

  @override
  String get planPriority => 'Generación prioritaria';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Prueba gratis de $daysString días';
  }

  @override
  String planPerYear(String price) {
    return '$price/año';
  }

  @override
  String planPerMonth(String price) {
    return '$price/mes';
  }

  @override
  String get packTitle => '¿Solo necesitas unas pocas?';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pack de $countString canciones',
      one: 'Pack de $countString canción',
    );
    return '$_temp0';
  }

  @override
  String get packNote => 'no caduca';

  @override
  String get valueForever => 'Tus canciones, para siempre';

  @override
  String get valueDownloads => 'Descargas en alta calidad';

  @override
  String get valueCommercial => 'Uso comercial permitido';

  @override
  String get valuePrivate => 'Privacidad ante todo';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return 'Tras la prueba gratuita se cobran $pricePerPeriod automáticamente. Cancela cuando quieras antes de que termine.';
  }

  @override
  String get paywallSubscribe => 'Suscribirse';

  @override
  String get paywallBuyPack => 'Comprar paquete';

  @override
  String get templateBirthdayWish => 'Felicitación de cumpleaños';

  @override
  String get templateBirthdayWishHint =>
      'Una canción especial para su día especial';

  @override
  String get templateBirthdayParty => 'Fiesta de cumpleaños';

  @override
  String get templateBirthdayPartyHint =>
      'Anima la fiesta de quien cumple años';

  @override
  String get templateLoveStory => 'Historia de amor';

  @override
  String get templateLoveStoryHint => 'Su historia hecha canción';

  @override
  String get templateThankAFriend => 'Gracias, amigo';

  @override
  String get templateThankAFriendHint =>
      'Da las gracias como las palabras no pueden';

  @override
  String get templatePartyInvite => 'Invitación a la fiesta';

  @override
  String get templatePartyInviteHint => 'Reúne a todos en la fiesta';

  @override
  String get templateWedding => 'Boda';

  @override
  String get templateWeddingHint => 'Una canción para su momento eterno';

  @override
  String get templateInMemory => 'En memoria';

  @override
  String get templateInMemoryHint => 'Honra a alguien que quieres';

  @override
  String get templateFestival => 'Festividad';

  @override
  String get templateFestivalHint => 'Buenos deseos para una época especial';

  @override
  String get templateRingtone => 'Tono de llamada';

  @override
  String get templateRingtoneHint => 'Un bucle corto solo tuyo';

  @override
  String get templateTeamAnthem => 'Himno del equipo';

  @override
  String get templateTeamAnthemHint => 'Enciende al equipo y a la afición';

  @override
  String get templateSportsRecap => 'Resumen del partido';

  @override
  String get templateSportsRecapHint => 'El gran partido, en una canción';

  @override
  String get templateRapBattle => 'Batalla de rap';

  @override
  String get templateRapBattleHint => 'Rimas amistosas para un rival amistoso';

  @override
  String get templateComedy => 'Humor';

  @override
  String get templateComedyHint => 'Las bromas internas, ahora con estribillo';

  @override
  String get templatePetAnthem => 'Himno para tu mascota';

  @override
  String get templatePetAnthemHint => 'Una canción para tu mejor compañero';

  @override
  String get templateHometown => 'Tu ciudad';

  @override
  String get templateHometownHint => 'Amor por el lugar que llamas hogar';

  @override
  String get templateBusinessPromo => 'Promo de tu negocio';

  @override
  String get templateBusinessPromoHint =>
      'Una melodía pegadiza para tu tienda o marca';

  @override
  String get templateCustom => 'Tu propia idea';

  @override
  String get mvRecommended => 'Recomendado';

  @override
  String mvSeconds(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString s';
  }

  @override
  String get mvViewProgress => 'Ver el progreso';

  @override
  String mvIntentWaiting(String level) {
    return '$level espera créditos';
  }

  @override
  String get mvSongExpiredAction => 'Hacer la canción otra vez';

  @override
  String mvQuotaNeed(String level, int required, int available) {
    final intl.NumberFormat requiredNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String requiredString = requiredNumberFormat.format(required);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    String _temp0 = intl.Intl.pluralLogic(
      required,
      locale: localeName,
      other: '$requiredString créditos',
      one: '$requiredString crédito',
    );
    return '$level necesita $_temp0. Tienes $availableString.';
  }

  @override
  String get mvQuotaBuyAndContinue => 'Comprar y seguir';

  @override
  String get mvQuotaMayNeedTwice =>
      'Donde estás, un paquete quizá no alcance: puede que necesites dos.';

  @override
  String get mvQuotaAutoRetry =>
      'Tu vídeo empieza en cuanto se complete la compra.';

  @override
  String get mvAutoLyricMaking => 'Haciendo tu vídeo con letra';

  @override
  String get mvAutoChorusDetail => 'Hecho con esta canción y tus créditos';

  @override
  String mvAutoReady(String level) {
    return '$level está listo';
  }

  @override
  String get mvAutoView => 'Ver';

  @override
  String get mvUpgradeChorus => 'Hacer un vídeo del estribillo';

  @override
  String get mvAutoFailed => 'El vídeo no pudo empezar';

  @override
  String get mvLeaveHint =>
      'Puedes salir de esta pantalla: te avisaremos cuando debería estar listo.';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: 'Tus $creditsString créditos se han devuelto.',
      one: 'Tu crédito se ha devuelto.',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => 'Este vídeo no se terminó';

  @override
  String get mvRejectedTitle => 'Una foto no se pudo usar';

  @override
  String get mvRejectedBody =>
      'El modelo de vídeo rechazó una de tus fotos de referencia. Cambia las fotos y vuelve a intentarlo.';

  @override
  String get mvAdjustPhotos => 'Cambiar fotos e intentarlo de nuevo';

  @override
  String get mvTryChorus => 'Mejor un vídeo del estribillo';

  @override
  String get mvPreparingPhotos => 'Subiendo tus fotos…';

  @override
  String get mvPreparingSubmit => 'Enviando tu vídeo…';

  @override
  String get mvNotifyTitle => 'Tu vídeo ya debería estar listo';

  @override
  String mvNotifyBody(String level) {
    return '$level: toca para verlo.';
  }

  @override
  String get mvRegenerate => 'Hacer otro';

  @override
  String get mvEntryTitle => 'Conviértela en vídeo';

  @override
  String get mvEntrySubtitle =>
      'Vídeos con letra, del estribillo y completos, con créditos';

  @override
  String get mvEntryDisabled => 'Disponible cuando la canción esté terminada';

  @override
  String get mvEntryChoose => 'Elegir un vídeo';

  @override
  String get mvEntryWatch => 'Ver el vídeo';

  @override
  String get mvChipReady => 'Vídeo';

  @override
  String get mvChipMaking => 'Haciendo el vídeo';

  @override
  String get lengthAutoVideo => 'Hacer también un vídeo con letra';

  @override
  String get lengthAutoVideoHint =>
      'Listo unos minutos después de la canción · con créditos';

  @override
  String get lengthSongAndChorus => 'Canción + vídeo del estribillo';

  @override
  String get lengthSongAndChorusHint =>
      'La canción completa y luego un vídeo del estribillo de 30 segundos';

  @override
  String get paywallVideoGroup => 'Vídeos musicales';

  @override
  String get planVideoIncluded =>
      'Tu cuota también sirve para vídeos musicales';

  @override
  String get settingsVideoCredits => 'Créditos de vídeo';

  @override
  String get createGenrePop => 'Pop';

  @override
  String get createGenreHipHopRap => 'Hip-hop y rap';

  @override
  String get createGenreRock => 'Rock';

  @override
  String get createGenreKPop => 'K-pop';

  @override
  String get createGenreLatin => 'Latina';

  @override
  String get createGenreElectronic => 'Electrónica';

  @override
  String get createGenreRnb => 'R&B';

  @override
  String get createGenreCountry => 'Country';

  @override
  String get createGenreAfrobeats => 'Afrobeats';

  @override
  String get createGenreReggae => 'Reggae';

  @override
  String get createGenreJazzBlues => 'Jazz y blues';

  @override
  String get createGenreClassical => 'Clásica';

  @override
  String get createGenreFolk => 'Folk';

  @override
  String get createGenreLofi => 'Lo-fi';

  @override
  String get createGenreAcoustic => 'Acústica';

  @override
  String get createGenreCinematic => 'Cine';

  @override
  String get createGenreAmbient => 'Ambient';

  @override
  String get createGenreBossaNova => 'Bossa nova';

  @override
  String get createGenreIndiePop => 'Pop indie';

  @override
  String get createGenreContemporaryRnb => 'R&B actual';

  @override
  String get createGenreAlternativeCountry => 'Country alternativo';

  @override
  String get createGenreGarageRock => 'Garage rock';

  @override
  String get createGenreGrime => 'Grime';

  @override
  String get createGenreIndieFolk => 'Folk indie';

  @override
  String get createGenreSynthpop => 'Synthpop';

  @override
  String get createGenrePianoBallad => 'Balada de piano';

  @override
  String get createGenreSurfRock => 'Surf rock';

  @override
  String get createGenreDeepHouse => 'Deep house';

  @override
  String get createGenreMinimalTechno => 'Techno minimalista';

  @override
  String get createGenreFrenchYeyePop => 'Yé-yé francés de los 60';

  @override
  String get createGenreChillout => 'Chill-out';

  @override
  String get createGenreJPopIndiePop => 'J-pop indie';

  @override
  String get createGenreChiptune => 'Chiptune';

  @override
  String get createGenreDiscoFunk => 'Disco-funk';

  @override
  String get createGenreReggaeton => 'Reguetón';

  @override
  String get createGenreCumbia => 'Cumbia';

  @override
  String get createGenreLatinJazz => 'Jazz latino';

  @override
  String get createGenreBhangra => 'Bhangra';

  @override
  String get createGenreIndianClassical => 'Clásica india';

  @override
  String get createGenreLofiHipHop => 'Hip-hop lo-fi';

  @override
  String profileAccountIdWithValue(String id) {
    return 'ID de cuenta: $id';
  }

  @override
  String profileBalanceValue(int balance) {
    final intl.NumberFormat balanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String balanceString = balanceNumberFormat.format(balance);

    return '$balanceString';
  }

  @override
  String playerExportFileName(String brand, String title, String occasion) {
    return '$brand – $title ($occasion)';
  }

  @override
  String get createVocalsCustomSummary => 'Automático — según tu descripción';

  @override
  String mvChipMakingWithProgress(String progress) {
    return 'Haciendo el vídeo · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return 'El vídeo no pudo empezar · $reason';
  }

  @override
  String settingsVideoCreditsSummary(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    return 'Créditos de vídeo: $creditsString';
  }

  @override
  String shareLyricsAttribution(String aiLabel, String brand) {
    return '— $aiLabel · $brand';
  }

  @override
  String get inspirationHeader => 'Inspiración';

  @override
  String inspirationPlay(String name) {
    return 'Reproducir $name';
  }

  @override
  String get inspirationStop => 'Detener la muestra';

  @override
  String get inspirationNameSoundscape => 'Paisaje sonoro';

  @override
  String get inspirationStyleSoundscape => 'Texturas ambientales, sin voz';

  @override
  String get inspirationNameBackgroundMusic => 'Música de fondo';

  @override
  String get inspirationStyleBackgroundMusic =>
      'Instrumental ligero para vídeos';

  @override
  String get inspirationNameMemorizeSomething => 'Para memorizar';

  @override
  String get inspirationStyleMemorizeSomething => 'Pop pegadizo para memorizar';

  @override
  String get inspirationNameTextMessages => 'Mensajes hechos canción';

  @override
  String get inspirationStyleTextMessages => 'Pop juguetón con tus mensajes';

  @override
  String get inspirationNameIntroMusic => 'Música de intro';

  @override
  String get inspirationStyleIntroMusic => 'Apertura cinematográfica y potente';

  @override
  String get inspirationNameMontage => 'Montaje';

  @override
  String get inspirationStyleMontage => 'Crescendo animado para resúmenes';

  @override
  String get inspirationNameSayItWithATrack => 'Dilo con una canción';

  @override
  String get inspirationStyleSayItWithATrack => 'Balada pop emotiva';

  @override
  String get inspirationNameBrandJingle => 'Jingle de marca';

  @override
  String get inspirationStyleBrandJingle =>
      'Gancho corto, brillante y memorable';

  @override
  String get inspirationNameRingtone => 'Tono de llamada';

  @override
  String get inspirationStyleRingtone => 'Gancho de 30 segundos en bucle';

  @override
  String get inspirationNameStreaming => 'Streaming';

  @override
  String get inspirationStyleStreaming =>
      'Intro electrónica con energía para directos';

  @override
  String get inspirationNameSpeechToTrack => 'De voz a canción';

  @override
  String get inspirationStyleSpeechToTrack => 'Tu voz convertida en canción';

  @override
  String get inspirationNameRapBattle => 'Batalla de rap';

  @override
  String get inspirationStyleRapBattle => 'Hip-hop contundente';

  @override
  String get inspirationNameComedy => 'Humor';

  @override
  String get inspirationStyleComedy => 'Peculiar, alegre y con ironía';

  @override
  String get inspirationNameTeamAnthem => 'Himno del equipo';

  @override
  String get inspirationStyleTeamAnthem => 'Cántico de rock de estadio';

  @override
  String get inspirationNameSportsRecap => 'Resumen del partido';

  @override
  String get inspirationStyleSportsRecap => 'Momentos épicos orquestales';

  @override
  String get inspirationNamePartyInvite => 'Invitación a la fiesta';

  @override
  String get inspirationStylePartyInvite => 'Invitación dance-pop';

  @override
  String get inspirationNameHappyBirthday => 'Feliz cumpleaños';

  @override
  String get inspirationStyleHappyBirthday =>
      'Cálida canción acústica de cumpleaños';

  @override
  String get inspirationNameFriendAppreciation => 'Gracias, amigos';

  @override
  String get inspirationStyleFriendAppreciation => 'Indie pop que sienta bien';

  @override
  String get inspirationNameLoveStory => 'Historia de amor';

  @override
  String get inspirationStyleLoveStory => 'Balada romántica de R&B';

  @override
  String get inspirationNameBirthdayRoast => 'Cumpleaños con guasa';

  @override
  String get inspirationStyleBirthdayRoast => 'Cumpleaños con humor pícaro';

  @override
  String get inspirationNameOdeToYourPet => 'Oda a tu mascota';

  @override
  String get inspirationStyleOdeToYourPet => 'Pop tierno y saltarín';

  @override
  String get inspirationNameHometownTribute => 'Homenaje a tu tierra';

  @override
  String get inspirationStyleHometownTribute => 'Folk nostálgico';

  @override
  String get inspirationNameWeatherReport => 'Parte del tiempo';

  @override
  String get inspirationStyleWeatherReport => 'Groove lounge desenfadado';

  @override
  String get inspirationNameBusinessPromo => 'Promo de tu negocio';

  @override
  String get inspirationStyleBusinessPromo => 'Pop corporativo con aplomo';

  @override
  String get inspirationStyleBirthdayWish =>
      'Canción sentida para su día especial';

  @override
  String get inspirationStyleBirthdayParty =>
      'Himno de fiesta animado para quien cumple años';

  @override
  String get inspirationStyleThankAFriend =>
      'Canción de agradecimiento cálida y sincera';

  @override
  String get inspirationStyleWedding =>
      'Canción alegre y romántica para el gran día';

  @override
  String get inspirationStyleInMemory => 'Homenaje suave y esperanzador';

  @override
  String get inspirationStyleFestival => 'Saludo de temporada alegre y festivo';

  @override
  String get inspirationStylePetAnthem =>
      'Tema cariñoso y saltarín para tu mascota';

  @override
  String get inspirationStyleHometown =>
      'Himno orgulloso y nostálgico a tu tierra';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsSectionProfile => 'Perfil';

  @override
  String get settingsCredits => 'Créditos';

  @override
  String get settingsAccountId => 'ID de cuenta';

  @override
  String get settingsCopyAccountId => 'Copiar ID de cuenta';

  @override
  String get devSectionTitle => 'Desarrollador (solo DEV)';

  @override
  String get devKeychainReset => 'Borrar claves del Llavero';

  @override
  String get devKeychainResetHint => 'ID del dispositivo y tokens de sesión';

  @override
  String get devKeychainResetConfirmTitle => '¿Borrar claves del Llavero?';

  @override
  String get devKeychainResetConfirmBody =>
      'Se borran del Llavero el ID del dispositivo y los tokens de sesión. La cuenta de invitado actual no se puede recuperar; la app inicia sesión como un invitado nuevo.';

  @override
  String get devKeychainResetDone =>
      'Claves borradas: sesión iniciada como invitado nuevo';

  @override
  String get settingsAppLanguage => 'Idioma de la app';

  @override
  String get settingsLanguageSystem => 'Usar idioma del sistema';

  @override
  String settingsLanguageSystemValue(String language) {
    return 'Sistema ($language)';
  }

  @override
  String get settingsLanguageNativeName => 'Español';

  @override
  String get settingsLanguageSaveFailed =>
      'No se pudo guardar el idioma. Inténtalo de nuevo.';

  @override
  String get settingsLyricsLanguageHint => 'Se aplica a las canciones nuevas.';

  @override
  String composerRemoveInspiration(String name) {
    return 'Quitar $name';
  }

  @override
  String get composerPromptHint =>
      'Describe la canción o elige una idea arriba';

  @override
  String get composerPromptHintWide => 'Describe la canción o elige una idea';

  @override
  String get composerWordsLabel => 'Tus palabras';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fotos añadidas',
      one: '$countString foto añadida',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return 'Opciones de la canción: $summary';
  }

  @override
  String get composerOptionsShow => 'Mostrar opciones';

  @override
  String get composerOptionsHide => 'Ocultar opciones';

  @override
  String get composerSummaryAnyVocals => 'Cualquier voz';

  @override
  String get composerSummaryAnyGenre => 'Cualquier género';

  @override
  String get composerSummaryLyrics => 'Letra propia';

  @override
  String get composerSummaryVideo => 'Vídeo con letra';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Crear adelanto · gratis',
      'preview': 'Crear adelanto · 1 adelanto',
      'other': 'Crear adelanto',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Crear el adelanto de $name · gratis',
      'preview': 'Crear el adelanto de $name · 1 adelanto',
      'other': 'Crear el adelanto de $name',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': 'Crear canción completa · 1 canción',
      'other': 'Crear canción completa',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => 'Usar este texto';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$level empieza en $seconds s';
  }

  @override
  String planPerWeek(String price) {
    return '$price/semana';
  }

  @override
  String get planCreditsWeekly => 'Créditos nuevos cada semana';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'tu primer día',
      'week': 'tu primera semana',
      'month': 'tu primer mes',
      'year': 'tu primer año',
      'other': 'tu primer periodo',
    });
    return '$percent % de descuento en $_temp0';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return 'Tras el precio introductorio de $introPrice, se te cobrará $pricePerPeriod automáticamente. Cancela cuando quieras antes de la renovación.';
  }

  @override
  String get storePreviewAHook => 'Empieza con su nombre';

  @override
  String get storePreviewAWords => 'Agrega tres palabras';

  @override
  String get storePreviewAWait => 'Tu canción se está creando';

  @override
  String get storePreviewAChorus => 'Su nombre en el coro';

  @override
  String get storePreviewAEnd => 'Una canción con su nombre';

  @override
  String get storePreviewBHook => 'Empieza con tus fotos';

  @override
  String get storePreviewBVideo => 'Agrega un video con letra';

  @override
  String get storePreviewBWait => 'Creando tu canción';

  @override
  String get storePreviewBLyrics => 'Letra sincronizada';

  @override
  String get storePreviewBMood => 'Tus fotos crean el ambiente.';

  @override
  String get storePreviewBShare => 'Comparte el video.';

  @override
  String get storePreviewBLanguage => 'Letras en tu idioma';

  @override
  String get storePreviewAShare => 'Envíala como tarjeta';

  @override
  String get storePreviewCta => 'Crea tu primera canción';

  @override
  String get storePreviewDisclosure => 'Requiere suscripción o créditos';

  @override
  String get storeCreativeHeader => 'Canciones para quienes amas';

  @override
  String get storeCreativeSearch => 'Un nombre se vuelve canción';

  @override
  String get storeCreativeBirthday => 'Una canción de cumpleaños con su nombre';

  @override
  String get storeCreativePhoto => 'Tus fotos se vuelven canción';

  @override
  String get storeCreativeWedding => 'Una canción para tu boda';
}
