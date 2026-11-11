// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get startupLoading => 'Afinando…';

  @override
  String get commonErrorTitle => 'Algo deu errado';

  @override
  String get updateRequiredTitle => 'Atualização necessária';

  @override
  String get updateRequiredMessage =>
      'É necessária uma nova versão para continuar.';

  @override
  String get updateNow => 'Atualizar agora';

  @override
  String get maintenanceTitle => 'Manutenção programada';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Previsão de retorno em cerca de $minutesString min';
  }

  @override
  String get featureUnavailable =>
      'Este recurso está temporariamente indisponível.';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navStore => 'Loja';

  @override
  String get navUpload => 'Enviar';

  @override
  String get uploadTitle => 'Envios';

  @override
  String get uploadSubtitle =>
      'Envio direto ao R2 com URL pré-assinada, hash, deduplicação instantânea e progresso.';

  @override
  String get uploadPick => 'Escolher imagem e enviar';

  @override
  String get uploadAgain => 'Enviar outra';

  @override
  String get uploadPhaseHashing => 'Calculando hash…';

  @override
  String get uploadPhaseSigning => 'Solicitando autorização de envio…';

  @override
  String uploadPhaseUploading(String percent) {
    return 'Enviando $percent';
  }

  @override
  String get uploadPhaseFinalizing => 'Finalizando…';

  @override
  String get uploadDone => 'Enviado.';

  @override
  String get uploadDedup => 'Instantâneo: este arquivo já existia no servidor.';

  @override
  String get uploadOpenLink => 'Ver arquivo';

  @override
  String get uploadFailed => 'Falha no envio.';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'O arquivo é grande demais (máx. $limitString MB).';
  }

  @override
  String get uploadUnsupportedType => 'Tipo de arquivo não compatível.';

  @override
  String get profileGuestTitle => 'Convidado';

  @override
  String get profileGuestSubtitle =>
      'Entre na sua conta para manter suas compras em todos os dispositivos.';

  @override
  String get signIn => 'Entrar';

  @override
  String get signOut => 'Sair';

  @override
  String get profileBalanceLabel => 'Créditos';

  @override
  String get profileAccountId => 'ID da conta';

  @override
  String get profileFeaturesLabel => 'Benefícios ativos';

  @override
  String get profileNoFeatures => 'Nenhum benefício ativo ainda.';

  @override
  String get profileSubscriptionLabel => 'Assinatura';

  @override
  String get profileManageSubscription => 'Gerenciar assinatura';

  @override
  String get subscriptionActive => 'Ativa';

  @override
  String get subscriptionInactive => 'Nenhuma';

  @override
  String get profileDeleteAccount => 'Apagar conta';

  @override
  String get deleteAccountTitle => 'Apagar esta conta?';

  @override
  String get deleteAccountMessage =>
      'Esta ação não pode ser desfeita: esta conta e seus créditos e benefícios ficarão permanentemente inacessíveis, e uma nova conta será criada. Apagar a conta não cancela uma assinatura ativa da App Store: gerencie-a nos ajustes da sua conta da App Store ou vincule-a novamente mais tarde com Restaurar compras.';

  @override
  String get deleteAccountConfirm => 'Apagar';

  @override
  String get deleteAccountWorking => 'Apagando conta…';

  @override
  String get deleteAccountDone => 'Conta apagada.';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Membro desde $dateString';
  }

  @override
  String get loginTitle => 'Entrar';

  @override
  String get loginUsername => 'Nome de usuário';

  @override
  String get loginPassword => 'Senha';

  @override
  String get loginSubmit => 'Entrar';

  @override
  String get paywallTitle => 'Tenha a música completa';

  @override
  String get paywallSubtitle =>
      'Transforme sua prévia em uma música de 2 minutos com letra, sua para baixar e usar.';

  @override
  String get paywallRestore => 'Restaurar compras';

  @override
  String get paywallAutoRenewNotice =>
      'O pagamento será cobrado na sua Conta Apple na confirmação da compra. As assinaturas são renovadas automaticamente pelo mesmo preço e período, a menos que sejam canceladas pelo menos 24 horas antes do fim do período atual. O teste grátis se converte em uma assinatura paga quando termina. Gerencie ou cancele a qualquer momento nos ajustes da sua conta da App Store.';

  @override
  String get paywallContinue => 'Continuar';

  @override
  String get paywallFreeTrial => 'Teste grátis';

  @override
  String get paywallOffer => 'Oferta';

  @override
  String get paywallManage => 'Gerenciar';

  @override
  String get paywallTermsOfUse => 'Termos de Uso';

  @override
  String get paywallPrivacyPolicy => 'Política de Privacidade';

  @override
  String get paywallSubscriptionTerms => 'Termos da Assinatura';

  @override
  String get commonLinkError => 'Não foi possível abrir o link.';

  @override
  String get commonError => 'Algo deu errado.';

  @override
  String get commonNetworkError =>
      'Erro de rede: verifique sua conexão e tente novamente.';

  @override
  String get commonOfflineError =>
      'Parece que você está offline. Verifique sua conexão e tente novamente.';

  @override
  String get networkErrorTitle => 'Problema de conexão';

  @override
  String get configErrorTitle => 'Problema de configuração do app';

  @override
  String get configErrorMessage =>
      'Esta versão não consegue acessar nosso serviço. Atualize o app pela App Store ou reinstale-o. Se o problema persistir, entre em contato com o suporte.';

  @override
  String get commonAuthError => 'Sua sessão expirou. Entre novamente.';

  @override
  String get paywallProductsErrorTitle =>
      'Não foi possível carregar os produtos';

  @override
  String get paywallNoProducts => 'Nenhum produto disponível no momento.';

  @override
  String get paywallPurchaseSuccess => 'Compra concluída. Aproveite!';

  @override
  String get paywallProcessing => 'Processando sua compra…';

  @override
  String get paywallVerifying => 'Verificando sua compra…';

  @override
  String get paywallPurchaseFailed => 'Não foi possível concluir a compra.';

  @override
  String get paywallRestoreStarted => 'Restaurando suas compras…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString compras restauradas.',
      one: '$countString compra restaurada.',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing => 'Nenhuma compra para restaurar.';

  @override
  String get paywallDeferred =>
      'Aguardando aprovação. Vamos concluir assim que for aprovada.';

  @override
  String get paywallAlreadySubscribed => 'Você já é assinante.';

  @override
  String get paywallBillingRetry =>
      'Atualize sua forma de pagamento para manter sua assinatura.';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Teste grátis de $daysString dias';
  }

  @override
  String get cycleOneTime => 'pagamento único';

  @override
  String get cycleWeekly => '/ semana';

  @override
  String get cycleMonthly => '/ mês';

  @override
  String get cycleQuarterly => '/ trimestre';

  @override
  String get cycleSemiAnnual => '/ 6 meses';

  @override
  String get cycleAnnual => '/ ano';

  @override
  String get cycleLifetime => 'vitalício';

  @override
  String get navCreate => 'Criar';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonBack => 'Voltar';

  @override
  String get createTitle => 'Para quem é esta música?';

  @override
  String get occasionBirthday => 'Aniversário';

  @override
  String get occasionBirthdayHint => 'Uma música alegre para o grande dia';

  @override
  String get occasionAnniversary => 'Aniversário de casal';

  @override
  String get occasionAnniversaryHint => 'Celebrem a história de vocês';

  @override
  String get occasionConfession => 'Declaração de amor';

  @override
  String get occasionConfessionHint => 'Diga o que seu coração sente';

  @override
  String get occasionWedding => 'Casamento';

  @override
  String get occasionWeddingHint => 'Uma música para o momento de uma vida';

  @override
  String get occasionMemorial => 'Em memória';

  @override
  String get occasionMemorialHint => 'Homenageie alguém especial';

  @override
  String get occasionFestival => 'Festividade';

  @override
  String get occasionFestivalHint => 'Votos calorosos para uma época especial';

  @override
  String get occasionBrand => 'Jingle de marca';

  @override
  String get occasionBrandHint => 'Uma melodia chiclete para sua marca';

  @override
  String get occasionSoundtrack => 'Trilha para vídeo';

  @override
  String get occasionSoundtrackHint => 'Música que combina com sua história';

  @override
  String get festivalNewYear => 'Ano-Novo';

  @override
  String get festivalThanksgiving => 'Ação de Graças';

  @override
  String get festivalDiwali => 'Diwali';

  @override
  String get festivalCarnival => 'Carnaval';

  @override
  String get festivalEid => 'Eid';

  @override
  String get festivalLunarNewYear => 'Ano-Novo Lunar';

  @override
  String get regionTitle => 'Onde ela vai tocar?';

  @override
  String get regionSearchHint => 'Buscar país';

  @override
  String get regionLanguageSheetTitle => 'Idioma da letra';

  @override
  String get countryUS => 'Estados Unidos';

  @override
  String get countryGB => 'Reino Unido';

  @override
  String get countryCA => 'Canadá';

  @override
  String get countryAU => 'Austrália';

  @override
  String get countryDE => 'Alemanha';

  @override
  String get countryFR => 'França';

  @override
  String get countryJP => 'Japão';

  @override
  String get countryKR => 'Coreia do Sul';

  @override
  String get countryBR => 'Brasil';

  @override
  String get countryMX => 'México';

  @override
  String get countryIN => 'Índia';

  @override
  String get countryID => 'Indonésia';

  @override
  String get countryVN => 'Vietnã';

  @override
  String get countryTR => 'Turquia';

  @override
  String get languageEn => 'Inglês';

  @override
  String get languageFr => 'Francês';

  @override
  String get languageDe => 'Alemão';

  @override
  String get languageJa => 'Japonês';

  @override
  String get languageKo => 'Coreano';

  @override
  String get languagePtBR => 'Português (Brasil)';

  @override
  String get languageEsMX => 'Espanhol (México)';

  @override
  String get languageHi => 'Hindi';

  @override
  String get languageId => 'Indonésio';

  @override
  String get languageVi => 'Vietnamita';

  @override
  String get languageTr => 'Turco';

  @override
  String get languageZhHans => 'Chinês (simplificado)';

  @override
  String get languageZhHant => 'Chinês (tradicional)';

  @override
  String get inputNameLabel => 'Nome da pessoa';

  @override
  String get inputNameOptionalLabel => 'Nome (opcional)';

  @override
  String get inputNameHint => 'ex.: Alex';

  @override
  String get inputKeywordsLabel => 'Três palavras sobre a pessoa';

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
      'Esta letra é minha ou tenho o direito de usá-la';

  @override
  String get issueRecipientMissing => 'Adicione o nome da pessoa.';

  @override
  String get issueRecipientTooLong => 'Os nomes podem ter até 24 caracteres.';

  @override
  String get issueBriefMissing =>
      'Conte sobre a música: algumas palavras, letra ou fotos.';

  @override
  String get issueDescriptionMissing =>
      'Esta ideia precisa das suas palavras: escreva uma frase sobre a música.';

  @override
  String get generatingBackToEdit => 'Voltar para editar';

  @override
  String get issueKeywordTooLong => 'Cada palavra pode ter até 20 caracteres.';

  @override
  String get issueTooManyKeywords => 'Use no máximo três palavras.';

  @override
  String get issueArtistName =>
      'Não é possível usar nomes de artistas. Descreva o sentimento.';

  @override
  String get issueStyleImitation =>
      'Não podemos imitar um cantor ou uma banda. Descreva o clima.';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'A letra pode ter até $limitString caracteres.';
  }

  @override
  String get issueLyricsNotOriginal =>
      'Esta letra parece uma música existente. Escreva a sua.';

  @override
  String get issueLyricsOwnership =>
      'Confirme que você tem o direito de usar a letra.';

  @override
  String get issueTooManyPhotos => 'Escolha até 10 fotos.';

  @override
  String get photosTitle => 'Escolha algumas fotos';

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
      'As fotos são usadas uma única vez para escrever a música e apagadas dos nossos servidores em até 24 horas.';

  @override
  String get photosAdd => 'Adicionar fotos';

  @override
  String get photosCreate => 'Criar com fotos';

  @override
  String get photosEmpty => 'Escolha de 1 a 10 fotos do momento.';

  @override
  String get generatingStepPolishing => 'Refinando suas palavras neste iPhone…';

  @override
  String get generatingStepUploading => 'Enviando suas fotos…';

  @override
  String get generatingStepSubmitting => 'Enviando para o estúdio…';

  @override
  String get errorSafetyBlocked =>
      'Não conseguimos criar esta. Tente outras palavras e não use nomes de artistas.';

  @override
  String get errorQuotaExhausted =>
      'Você já usou as músicas deste mês. Adicione um pacote ou faça upgrade.';

  @override
  String get errorUpstreamTimeout =>
      'Está demorando mais que o normal. Vamos continuar tentando e avisaremos você.';

  @override
  String get errorUpstreamRateLimited =>
      'Muitas músicas sendo criadas agora. A sua está na fila.';

  @override
  String get errorAttestFailed => 'Atualize o Songlet pela App Store.';

  @override
  String get errorImageRejected =>
      'Uma dessas fotos não pode ser usada. Tente outra.';

  @override
  String get errorNetworkOffline =>
      'Você está offline. Sua biblioteca continua funcionando.';

  @override
  String get errorDownloadLocked =>
      'Não é possível baixar esta música: a compra usada para criá-la foi reembolsada ou seu plano terminou. Você ainda pode ouvi-la.';

  @override
  String get errorJobAlreadyFinished =>
      'Já terminou — não há nada para cancelar.';

  @override
  String get errorMvSongNotReady =>
      'Esta música ainda não está pronta para um vídeo.';

  @override
  String get errorMvSongTooLong =>
      'Esta música é longa demais para um vídeo completo — tente um vídeo do refrão.';

  @override
  String get errorMvSongExpired =>
      'Esta música expirou. Gere-a de novo para fazer um vídeo.';

  @override
  String get errorMvNotFound => 'Este vídeo não está mais disponível.';

  @override
  String get errorMvPhotosExpired =>
      'Essas fotos expiraram — escolha-as de novo.';

  @override
  String get errorMvRenderFailed =>
      'Não conseguimos terminar este vídeo. Seus créditos voltaram — tente de novo.';

  @override
  String get mvHubTitle => 'Fazer um vídeo';

  @override
  String mvHubSubtitle(String title) {
    return 'Transforme “$title” em um videoclipe.';
  }

  @override
  String get mvLevelLyricVideo => 'Vídeo com letra';

  @override
  String get mvLevelLyricHint => 'Uma cena fixa com a sua letra';

  @override
  String get mvLevelChorus => 'Vídeo do refrão';

  @override
  String get mvLevelChorusHint => '30 segundos do seu refrão, filmados por IA';

  @override
  String get mvLevelFull => 'Vídeo da música inteira';

  @override
  String get mvLevelFullHint => 'A música inteira, cena a cena';

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
      other: 'Você tem $creditsString créditos',
      one: 'Você tem $creditsString crédito',
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
      other: 'Faltam $creditsString créditos',
      one: 'Falta $creditsString crédito',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => 'Verificando o preço…';

  @override
  String get mvOptionsHeader => 'Opções';

  @override
  String get mvAspectLabel => 'Formato';

  @override
  String get mvAspectPortrait => 'Vertical';

  @override
  String get mvAspectLandscape => 'Horizontal';

  @override
  String get mvAspectSquare => 'Quadrado';

  @override
  String get mvQualityLabel => 'Qualidade';

  @override
  String get mvQualityStandard => 'Padrão';

  @override
  String get mvQualityHigh => 'Alta';

  @override
  String get mvSubtitlesLabel => 'Letra na tela';

  @override
  String get mvPhotosLabel => 'Fotos de referência';

  @override
  String get mvPhotosHint =>
      'Definem o clima e as cores — rostos não são usados';

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
  String get mvChorusLabel => 'Refrão';

  @override
  String get mvChorusAuto => 'Encontrado automaticamente';

  @override
  String get mvChorusCustom => 'Escolher o trecho';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => 'Fazer o vídeo';

  @override
  String get mvBuyPack => 'Pegue o pacote e faça';

  @override
  String get mvSongLocked => 'Sua música foi salva para o vídeo.';

  @override
  String get mvGeneratingTitle => 'Fazendo o seu vídeo…';

  @override
  String get mvStageQueued => 'Aguardando para começar';

  @override
  String get mvStageSlicing => 'Escolhendo os momentos';

  @override
  String get mvStageStoryboarding => 'Escrevendo o storyboard';

  @override
  String get mvStageKeyframing => 'Pintando as cenas';

  @override
  String get mvStageRendering => 'Filmando as cenas';

  @override
  String get mvStageAssembling => 'Montando o vídeo';

  @override
  String get mvStageDone => 'Pronto';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Cena $doneString de $totalString';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Geralmente uns $minutesString minutos';
  }

  @override
  String get mvCancelRequested => 'Vai parar depois da cena atual…';

  @override
  String get mvCancelTitle => 'Parar este vídeo?';

  @override
  String get mvCancelQueued => 'Ainda não começou, então nada será usado.';

  @override
  String get mvCancelStarted =>
      'Já começou. As cenas prontas são cobradas; o resto volta.';

  @override
  String get mvCancelConfirm => 'Parar vídeo';

  @override
  String get mvCancelled => 'Vídeo parado';

  @override
  String get mvCancelledRefunded => 'Vídeo parado — nada foi usado';

  @override
  String get mvNothing => 'Nenhum vídeo sendo feito agora.';

  @override
  String get mvQuotaTitle => 'Créditos insuficientes';

  @override
  String get mvAiLabelBurnedIn => 'Gerado por IA — o selo faz parte do vídeo';

  @override
  String get mvSave => 'Salvar em Fotos';

  @override
  String get mvSaveFiles => 'Salvar em Arquivos';

  @override
  String get mvShareText => 'Fiz este videoclipe com o Songlet 🎬';

  @override
  String get mvMissing => 'Este vídeo não está mais neste aparelho.';

  @override
  String get mvDeleteTitle => 'Excluir este vídeo?';

  @override
  String get mvDeleteBody => 'Ele é removido deste aparelho.';

  @override
  String get mvDeleted => 'Vídeo excluído';

  @override
  String get mvProvenance =>
      'Feito com Google Lyria 3 e modelos de vídeo com IA · Gerado por IA';

  @override
  String get detailVideos => 'Vídeos';

  @override
  String get detailMakeVideo => 'Fazer um vídeo';

  @override
  String get mvStatusReady => 'Pronto';

  @override
  String get mvStatusPending => 'Fazendo…';

  @override
  String get mvStatusFailed => 'Não terminou';

  @override
  String get mvPackTitle => 'Videoclipe';

  @override
  String get mvPackChorusSubtitle => 'Um vídeo do refrão';

  @override
  String get mvPackFullSubtitle => 'Um vídeo da música inteira';

  @override
  String get paywallMvHeroTitle => 'Transforme em vídeo';

  @override
  String get paywallMvHeroSubtitle =>
      'Créditos para um videoclipe da sua música — para salvar e compartilhar.';

  @override
  String get playerAiGenerated => 'Gerado por IA';

  @override
  String get playerLoop => 'Repetir';

  @override
  String get playerPlay => 'Reproduzir';

  @override
  String get playerPause => 'Pausar';

  @override
  String get playerPreviewLabel => 'Prévia de 30 segundos';

  @override
  String playerTitleFor(String name) {
    return 'Para $name';
  }

  @override
  String get downloadSaved => 'Salvo em Arquivos.';

  @override
  String get shareComposing => 'Criando seu cartão para compartilhar…';

  @override
  String get shareFailed =>
      'Não foi possível criar o cartão para compartilhar.';

  @override
  String get shareText => 'Fiz esta música com o Songlet 🎵';

  @override
  String get paywallBestValue => 'Melhor custo-benefício';

  @override
  String get paywallStartTrial => 'Começar teste grátis';

  @override
  String get paywallClose => 'Fechar';

  @override
  String get paywallSeePlans => 'Ver assinaturas';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Seu plano está ativo: restam $countString músicas completas neste período.',
      one:
          'Seu plano está ativo: resta $countString música completa neste período.',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => 'Suas músicas vão ficar aqui.';

  @override
  String get libraryEmptyAction => 'Crie sua primeira música';

  @override
  String get libraryPending => 'Compondo…';

  @override
  String get libraryPreviewBadge => 'Prévia';

  @override
  String get librarySongBadge => 'Música completa';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsPlan => 'Seu plano';

  @override
  String get settingsPlanUnavailable =>
      'Não foi possível carregar seu plano. Puxe para baixo para tentar novamente mais tarde.';

  @override
  String get tierFree => 'Sem assinatura';

  @override
  String get tierPack => 'Pacotes de músicas';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString músicas completas restantes',
      one: '$countString música completa restante',
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
      other: '$countString prévias restantes',
      one: '$countString prévia restante',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Renova em $dateString';
  }

  @override
  String get settingsUpgrade => 'Fazer upgrade';

  @override
  String get appTagline => 'Músicas para as pessoas que você ama';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonDone => 'Concluir';

  @override
  String get commonDelete => 'Apagar';

  @override
  String get commonMore => 'Mais';

  @override
  String get commonCopy => 'Copiar';

  @override
  String get commonCopied => 'Copiado';

  @override
  String get commonNotNow => 'Agora não';

  @override
  String get commonLearnMore => 'Saiba mais';

  @override
  String get commonSeeAll => 'Ver tudo';

  @override
  String get commonKeepGoing => 'Continuar';

  @override
  String get composerHint => 'Descreva a música que você quer';

  @override
  String get composerAddPhotos => 'Adicionar fotos';

  @override
  String get composerSourceMusicHint => 'Descreva com suas palavras';

  @override
  String get composerDictate => 'Ditar';

  @override
  String get composerStopDictation => 'Parar ditado';

  @override
  String get lengthPreview => 'Prévia';

  @override
  String get lengthFull => 'Música completa';

  @override
  String get paramLength => 'Duração';

  @override
  String get paramVocals => 'Vocal';

  @override
  String get paramGenre => 'Gênero';

  @override
  String templatePlaySample(String name) {
    return 'Ouvir uma amostra de $name';
  }

  @override
  String get templatePauseSample => 'Pausar a amostra';

  @override
  String get lengthShort => 'Curta';

  @override
  String get lengthShortHint => 'Prévia de 30 segundos';

  @override
  String get lengthStandard => 'Padrão';

  @override
  String get lengthStandardHint => 'cerca de 2 minutos, Pro';

  @override
  String get vocalsCustom => 'Automático';

  @override
  String get vocalsCustomHint => 'conforme sua descrição';

  @override
  String get vocalsCustomDetail => 'O estilo vocal segue sua descrição.';

  @override
  String get vocalsOn => 'Com vocal';

  @override
  String get vocalsInstrumental => 'Instrumental';

  @override
  String vocalsLyricsIn(String language) {
    return 'Letra em $language';
  }

  @override
  String get genreCustom => 'Automático';

  @override
  String get genreCustomHint => 'conforme sua descrição';

  @override
  String genrePopularIn(String country) {
    return 'Populares: $country';
  }

  @override
  String get genreAll => 'Todos os gêneros';

  @override
  String get regionHelper =>
      'Muda os 3 gêneros recomendados e o idioma da letra';

  @override
  String regionLyricsRow(String language) {
    return 'Idioma da letra: $language';
  }

  @override
  String get regionNoMatch => 'Nenhum país encontrado';

  @override
  String get keywordAdd => 'Adicionar uma palavra';

  @override
  String keywordRemove(String word) {
    return 'Remover $word';
  }

  @override
  String get nameClear => 'Limpar nome';

  @override
  String get lyricsOptional => 'Escreva sua própria letra (opcional)';

  @override
  String get issueRecipientArtistName =>
      'Não é possível usar nomes de artistas.';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Use menos de $limitString caracteres na descrição.';
  }

  @override
  String get voiceRecording => 'Gravando…';

  @override
  String get voiceStarting => 'Iniciando…';

  @override
  String get voiceListening => 'Diga para quem é e do que a pessoa gosta…';

  @override
  String get voiceOnDevice => 'Transcrição no aparelho';

  @override
  String get voicePermissionDenied =>
      'Permita o microfone e o reconhecimento de fala para o Songlet em Ajustes para ditar.';

  @override
  String get voiceUnavailable =>
      'O ditado não está disponível para este idioma neste aparelho.';

  @override
  String get voiceApplied => 'Adicionado pela sua voz';

  @override
  String get photoRemove => 'Remover foto';

  @override
  String generatingTitleFor(String name) {
    return 'Escrevendo a música de $name…';
  }

  @override
  String get generatingTitleGeneric => 'Escrevendo sua música…';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Normalmente cerca de $secondsString segundos';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => 'Progresso';

  @override
  String get generatingGlimpse => 'Uma prévia da sua música';

  @override
  String get generatingCancelTitle => 'Parar esta música?';

  @override
  String get generatingCancelQueued =>
      'Ela ainda não começou, então não conta no seu limite.';

  @override
  String get generatingCancelStarted =>
      'Ela já começou, então conta no seu limite.';

  @override
  String get generatingCancelConfirm => 'Parar';

  @override
  String get generatingCancelled => 'Música interrompida';

  @override
  String get generatingCancelledRefunded =>
      'Música interrompida — nada foi usado';

  @override
  String get queueTitle => 'Muitas músicas estão sendo criadas agora.';

  @override
  String get queueSubtitle => 'A sua está na fila.';

  @override
  String get queuePosition => 'Posição';

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
  String get generatingNothing => 'Nenhuma música está sendo criada agora.';

  @override
  String get previewGetFull => 'Obter a música completa de 2 minutos';

  @override
  String get previewShare => 'Compartilhar prévia';

  @override
  String get previewAnother => 'Tentar outra versão (usa 1 prévia)';

  @override
  String get playerPosition => 'Posição da reprodução';

  @override
  String get playerPrevSection => 'Seção anterior';

  @override
  String get playerNextSection => 'Próxima seção';

  @override
  String get playerShuffle => 'Seções aleatórias';

  @override
  String get playerRepeat => 'Repetir';

  @override
  String get playerProvenance =>
      'Feita com Google Lyria 3 · marca d’água SynthID · gerada por IA';

  @override
  String get playerMissing => 'Esta música não está mais neste aparelho.';

  @override
  String get actionDownload => 'Baixar';

  @override
  String get actionShare => 'Compartilhar';

  @override
  String get actionLicense => 'Licença';

  @override
  String get actionRegenerate => 'Gerar de novo';

  @override
  String get actionDetails => 'Detalhes';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionVerse => 'Verso';

  @override
  String get sectionPreChorus => 'Pré-refrão';

  @override
  String get sectionChorus => 'Refrão';

  @override
  String get sectionBridge => 'Ponte';

  @override
  String get sectionOutro => 'Final';

  @override
  String get sectionHook => 'Gancho';

  @override
  String get shareTitle => 'Cartão para compartilhar';

  @override
  String get shareSubtitle => 'Escolha um tema e um layout.';

  @override
  String get shareTheme => 'Tema';

  @override
  String get shareLayout => 'Layout';

  @override
  String get shareLayoutScene => 'Com ilustração';

  @override
  String get shareLayoutText => 'Só texto';

  @override
  String get paletteTerracotta => 'Terracota';

  @override
  String get paletteSand => 'Areia';

  @override
  String get paletteOlive => 'Oliva';

  @override
  String get paletteNavy => 'Azul-marinho';

  @override
  String get shareAction => 'Compartilhar';

  @override
  String get shareSaveVideo => 'Salvar vídeo';

  @override
  String get shareCopyLyrics => 'Copiar letra';

  @override
  String get shareVideoSaved => 'Salvo em Fotos';

  @override
  String get shareLyricsCopied => 'Letra copiada';

  @override
  String get shareCardTagline => 'Uma música para alguém';

  @override
  String get shareSaveFailed =>
      'Não foi possível salvar o vídeo. Permita que o Songlet adicione a Fotos em Ajustes.';

  @override
  String get downloadReady => 'Música completa pronta';

  @override
  String get downloadTitle => 'Sua para sempre';

  @override
  String get downloadIntro =>
      'Sua música está pronta. Baixe o áudio em alta qualidade e sua licença comercial abaixo.';

  @override
  String get downloadAudioHeader => 'Baixar áudio';

  @override
  String get downloadAudioNote => 'Alta qualidade';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbps';

  @override
  String get downloadMp3Subtitle =>
      'Ideal para compartilhar e ouvir no dia a dia';

  @override
  String get downloadWavTitle => 'WAV · 44,1 kHz (Premier)';

  @override
  String get downloadWavSubtitle =>
      'A mais alta qualidade para uso profissional';

  @override
  String get downloadMp3Action => 'Baixar MP3';

  @override
  String get downloadWavAction => 'Baixar WAV';

  @override
  String get downloadLicenseAction => 'Baixar licença';

  @override
  String get licenseHeader => 'Licença comercial';

  @override
  String get licenseIncluded => 'Incluída no seu plano';

  @override
  String get licenseNotIncluded => 'Disponível com um plano ou pacote';

  @override
  String get licensePdfTitle => 'Licença comercial (PDF)';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Gerada em $dateString';
  }

  @override
  String licenseId(String id) {
    return 'ID da licença: $id';
  }

  @override
  String get licenseUsesTitle => 'Você pode usar esta música para:';

  @override
  String get usePersonal => 'Uso pessoal';

  @override
  String get usePersonalDetail => 'Presentes, lembranças, sem fins comerciais';

  @override
  String get useAds => 'Anúncios e marketing';

  @override
  String get useAdsDetail => 'Promoções, campanhas pagas';

  @override
  String get useSocial => 'Redes sociais';

  @override
  String get useSocialDetail => 'TikTok, Instagram, YouTube etc.';

  @override
  String get usePodcasts => 'Podcasts e vídeos';

  @override
  String get usePodcastsDetail => 'Conteúdo monetizado';

  @override
  String get licenseDetailsNote => 'Todos os detalhes estão no PDF da licença.';

  @override
  String get saveEnjoyHeader => 'Salve e aproveite';

  @override
  String get saveToFiles => 'Salvar em Arquivos';

  @override
  String get addToMusic => 'Adicionar ao Música';

  @override
  String get synthIdNote =>
      'Esta música contém uma marca d’água SynthID que a identifica como conteúdo gerado por IA, mesmo depois de baixada.';

  @override
  String get wavNeedsPremier => 'Downloads em WAV fazem parte do Premier.';

  @override
  String get wavUnavailable =>
      'Esta música não tem arquivo WAV. Arquivos WAV podem ser salvos em até 24 horas após a criação da música.';

  @override
  String get libraryFilterAll => 'Todas';

  @override
  String get libraryJustBecause => 'Só porque sim';

  @override
  String libraryPlay(String title) {
    return 'Tocar $title';
  }

  @override
  String libraryActions(String title) {
    return 'Ações para $title';
  }

  @override
  String get libraryDeleteTitle => 'Apagar esta música?';

  @override
  String get libraryDeleteBody =>
      'Ela será removida deste aparelho. Se a sincronização do iCloud estiver ligada, também dos seus outros aparelhos.';

  @override
  String get libraryDeleted => 'Música apagada';

  @override
  String get libraryFailed => 'Não concluída';

  @override
  String get libraryNoMatch => 'Ainda não há músicas para esta ocasião.';

  @override
  String get detailFullGenerated => 'Música completa gerada';

  @override
  String get detailPreviewGenerated => 'Prévia gerada';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Gerada em $dateString';
  }

  @override
  String get detailPromptUsed => 'Dados usados';

  @override
  String get detailOccasion => 'Ocasião';

  @override
  String get detailCountry => 'País';

  @override
  String get detailGenre => 'Gênero';

  @override
  String get detailKeywords => 'Palavras-chave';

  @override
  String get detailDescription => 'Descrição';

  @override
  String get detailLyrics => 'Letra';

  @override
  String get detailGenerationId => 'ID de geração';

  @override
  String get detailRegenerate => 'Gerar de novo no mesmo estilo';

  @override
  String get detailCustomGenre => 'Conforme a descrição';

  @override
  String get settingsSectionPlan => 'Compras';

  @override
  String get settingsSectionLibrary => 'Biblioteca';

  @override
  String get settingsSectionAbout => 'Sobre';

  @override
  String get settingsRestore => 'Restaurar compras';

  @override
  String get settingsManage => 'Gerenciar assinatura';

  @override
  String get settingsICloud => 'Sincronização do iCloud';

  @override
  String get settingsICloudOn => 'As músicas sincronizam entre seus aparelhos';

  @override
  String get settingsICloudOff => 'As músicas ficam neste aparelho';

  @override
  String get settingsICloudUnavailable =>
      'Entre no iCloud em Ajustes para sincronizar';

  @override
  String get settingsLyricsLanguage => 'Idioma padrão da letra';

  @override
  String get settingsLyricsLanguageAuto => 'Conforme o país';

  @override
  String get settingsTerms => 'Termos de Uso';

  @override
  String get settingsPrivacy => 'Política de Privacidade';

  @override
  String settingsVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get aboutTitle => 'Sobre a geração';

  @override
  String get aboutSubtitle => 'Como o Songlet cria suas músicas';

  @override
  String get aboutLyriaTitle => 'Com o Lyria 3 do Google';

  @override
  String get aboutLyriaBody =>
      'As músicas são geradas pelo Lyria 3 do Google por meio da API Gemini. O Lyria 3 é um modelo de geração musical que transforma suas ideias em músicas originais.';

  @override
  String get aboutWatermarkTitle => 'Marca d’água integrada';

  @override
  String get aboutWatermarkBody =>
      'Toda música inclui uma marca d’água SynthID do Google. Ela ajuda a identificar música gerada por IA e não pode ser removida.';

  @override
  String get aboutImitationTitle => 'Sem imitar artistas reais';

  @override
  String get aboutImitationBody =>
      'O Songlet nunca imita artistas reais, suas vozes ou estilos específicos. As músicas são originais e criadas a partir das suas ideias, descrições e fotos.';

  @override
  String get aboutPrivacyTitle => 'Sua privacidade importa';

  @override
  String get aboutPrivacyBody =>
      'Fotos e descrições são apagadas dos nossos servidores em até 24 horas. Não guardamos suas imagens nem descrições depois que a música é gerada.';

  @override
  String get aboutBanner =>
      'Toda música que você compartilha é identificada como gerada por IA.';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · Feito com Google Lyria 3';
  }

  @override
  String get festivalKicker => 'Viva a sua história';

  @override
  String get festivalComing => 'está chegando!';

  @override
  String get festivalBody =>
      'Crie uma música única para celebrar essa energia.';

  @override
  String festivalCta(String festival) {
    return 'Fazer uma música de $festival';
  }

  @override
  String get festivalPickOccasion => 'Escolha uma ocasião e comece a criar';

  @override
  String get festivalLanguagesTitle => 'Músicas no seu idioma';

  @override
  String festivalLanguagesBody(String language) {
    return 'Crie músicas em $language e em mais 12 idiomas';
  }

  @override
  String get unavailableTitle => 'Temporariamente indisponível';

  @override
  String get unavailableMessage =>
      'O Songlet não consegue criar músicas agora. Sua biblioteca continua funcionando — tente de novo daqui a pouco.';

  @override
  String get paywallHeroTitle => 'Transforme em música completa';

  @override
  String get paywallHeroSubtitle =>
      'Leve sua ideia a uma música completa, com mais qualidade e todos os direitos.';

  @override
  String get paywallBenefitSongs => 'Mais músicas';

  @override
  String get paywallBenefitQuality => 'Mais qualidade';

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
      other: '$countString músicas completas por mês',
      one: '$countString música completa por mês',
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
      other: '$countString prévias por mês',
      one: '$countString prévia por mês',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'Download em MP3';

  @override
  String get planMp3Wav => 'Download em MP3 + WAV';

  @override
  String get planLicense => 'Licença comercial';

  @override
  String get planPriority => 'Geração prioritária';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Teste grátis de $daysString dias';
  }

  @override
  String planPerYear(String price) {
    return '$price/ano';
  }

  @override
  String planPerMonth(String price) {
    return '$price/mês';
  }

  @override
  String get packTitle => 'Precisa de só algumas?';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pacote de $countString músicas',
      one: 'Pacote de $countString música',
    );
    return '$_temp0';
  }

  @override
  String get packNote => 'não expira';

  @override
  String get valueForever => 'Suas músicas, para sempre';

  @override
  String get valueDownloads => 'Downloads em alta qualidade';

  @override
  String get valueCommercial => 'Uso comercial permitido';

  @override
  String get valuePrivate => 'Privacidade em primeiro lugar';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return 'Após o teste grátis, serão cobrados $pricePerPeriod automaticamente. Cancele quando quiser antes do fim do teste.';
  }

  @override
  String get paywallSubscribe => 'Assinar';

  @override
  String get paywallBuyPack => 'Comprar pacote';

  @override
  String get templateBirthdayWish => 'Parabéns';

  @override
  String get templateBirthdayWishHint =>
      'Uma música especial para um dia especial';

  @override
  String get templateBirthdayParty => 'Festa de aniversário';

  @override
  String get templateBirthdayPartyHint => 'Anime a festa do aniversariante';

  @override
  String get templateLoveStory => 'História de amor';

  @override
  String get templateLoveStoryHint => 'A história de vocês em forma de música';

  @override
  String get templateThankAFriend => 'Obrigado, amigo';

  @override
  String get templateThankAFriendHint =>
      'Agradeça como as palavras não conseguem';

  @override
  String get templatePartyInvite => 'Convite para festa';

  @override
  String get templatePartyInviteHint => 'Chame todo mundo para a festa';

  @override
  String get templateWedding => 'Casamento';

  @override
  String get templateWeddingHint => 'Uma música para o momento eterno deles';

  @override
  String get templateInMemory => 'Em memória';

  @override
  String get templateInMemoryHint => 'Homenageie alguém querido';

  @override
  String get templateFestival => 'Festas';

  @override
  String get templateFestivalHint => 'Votos carinhosos para uma época especial';

  @override
  String get templateRingtone => 'Toque';

  @override
  String get templateRingtoneHint => 'Um loop curto só seu';

  @override
  String get templateTeamAnthem => 'Hino do time';

  @override
  String get templateTeamAnthemHint => 'Anime o time e a torcida';

  @override
  String get templateSportsRecap => 'Resumo do jogo';

  @override
  String get templateSportsRecapHint => 'O grande jogo em forma de música';

  @override
  String get templateRapBattle => 'Batalha de rap';

  @override
  String get templateRapBattleHint => 'Rimas amigáveis para um rival amigável';

  @override
  String get templateComedy => 'Comédia';

  @override
  String get templateComedyHint => 'Piadas internas, agora com refrão';

  @override
  String get templatePetAnthem => 'Hino do pet';

  @override
  String get templatePetAnthemHint => 'Uma música-tema para o seu melhor amigo';

  @override
  String get templateHometown => 'Minha cidade';

  @override
  String get templateHometownHint => 'Amor pelo lugar que você chama de lar';

  @override
  String get templateBusinessPromo => 'Promo do negócio';

  @override
  String get templateBusinessPromoHint =>
      'Um jingle chiclete para sua loja ou marca';

  @override
  String get templateCustom => 'Sua própria ideia';

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
  String get mvViewProgress => 'Ver o progresso';

  @override
  String mvIntentWaiting(String level) {
    return '$level está esperando créditos';
  }

  @override
  String get mvSongExpiredAction => 'Fazer a música de novo';

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
    return '$level precisa de $_temp0. Você tem $availableString.';
  }

  @override
  String get mvQuotaBuyAndContinue => 'Comprar e continuar';

  @override
  String get mvQuotaMayNeedTwice =>
      'Onde você está, um pacote pode não bastar — talvez precise de dois.';

  @override
  String get mvQuotaAutoRetry =>
      'Seu vídeo começa assim que a compra for concluída.';

  @override
  String get mvAutoLyricMaking => 'Fazendo seu vídeo com letra';

  @override
  String get mvAutoChorusDetail => 'Feito com esta música e seus créditos';

  @override
  String mvAutoReady(String level) {
    return '$level está pronto';
  }

  @override
  String get mvAutoView => 'Ver';

  @override
  String get mvUpgradeChorus => 'Fazer um vídeo do refrão';

  @override
  String get mvAutoFailed => 'O vídeo não pôde começar';

  @override
  String get mvLeaveHint =>
      'Você pode sair desta tela — avisamos quando ele deve estar pronto.';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: 'Seus $creditsString créditos foram devolvidos.',
      one: 'Seu crédito foi devolvido.',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => 'Este vídeo não foi concluído';

  @override
  String get mvRejectedTitle => 'Uma foto não pôde ser usada';

  @override
  String get mvRejectedBody =>
      'O modelo de vídeo recusou uma das suas fotos de referência. Ajuste as fotos e tente de novo.';

  @override
  String get mvAdjustPhotos => 'Ajustar fotos e tentar de novo';

  @override
  String get mvTryChorus => 'Fazer um vídeo do refrão';

  @override
  String get mvPreparingPhotos => 'Enviando suas fotos…';

  @override
  String get mvPreparingSubmit => 'Enviando seu vídeo…';

  @override
  String get mvNotifyTitle => 'Seu vídeo já deve estar pronto';

  @override
  String mvNotifyBody(String level) {
    return '$level — toque para assistir.';
  }

  @override
  String get mvRegenerate => 'Fazer outro';

  @override
  String get mvEntryTitle => 'Transformar em vídeo';

  @override
  String get mvEntrySubtitle =>
      'Vídeos com letra, do refrão e completos, com créditos';

  @override
  String get mvEntryDisabled => 'Disponível quando a música estiver pronta';

  @override
  String get mvEntryChoose => 'Escolher um vídeo';

  @override
  String get mvEntryWatch => 'Assistir ao vídeo';

  @override
  String get mvChipReady => 'Vídeo';

  @override
  String get mvChipMaking => 'Fazendo o vídeo';

  @override
  String get lengthAutoVideo => 'Fazer também um vídeo com letra';

  @override
  String get lengthAutoVideoHint =>
      'Pronto alguns minutos depois da música · usa créditos';

  @override
  String get lengthSongAndChorus => 'Música + vídeo do refrão';

  @override
  String get lengthSongAndChorusHint =>
      'A música completa e depois um vídeo do refrão de 30 segundos';

  @override
  String get paywallVideoGroup => 'Videoclipes';

  @override
  String get planVideoIncluded => 'Sua cota também faz videoclipes';

  @override
  String get settingsVideoCredits => 'Créditos de vídeo';

  @override
  String get createGenrePop => 'Pop';

  @override
  String get createGenreHipHopRap => 'Hip-hop e rap';

  @override
  String get createGenreRock => 'Rock';

  @override
  String get createGenreKPop => 'K-pop';

  @override
  String get createGenreLatin => 'Latina';

  @override
  String get createGenreElectronic => 'Eletrônica';

  @override
  String get createGenreRnb => 'R&B';

  @override
  String get createGenreCountry => 'Country';

  @override
  String get createGenreAfrobeats => 'Afrobeats';

  @override
  String get createGenreReggae => 'Reggae';

  @override
  String get createGenreJazzBlues => 'Jazz e blues';

  @override
  String get createGenreClassical => 'Clássica';

  @override
  String get createGenreFolk => 'Folk';

  @override
  String get createGenreLofi => 'Lo-fi';

  @override
  String get createGenreAcoustic => 'Acústica';

  @override
  String get createGenreCinematic => 'Trilha de cinema';

  @override
  String get createGenreAmbient => 'Ambient';

  @override
  String get createGenreBossaNova => 'Bossa nova';

  @override
  String get createGenreIndiePop => 'Pop indie';

  @override
  String get createGenreContemporaryRnb => 'R&B contemporâneo';

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
  String get createGenreFrenchYeyePop => 'Yé-yé francês dos anos 60';

  @override
  String get createGenreChillout => 'Chill-out';

  @override
  String get createGenreJPopIndiePop => 'J-pop indie';

  @override
  String get createGenreChiptune => 'Chiptune';

  @override
  String get createGenreDiscoFunk => 'Disco-funk';

  @override
  String get createGenreReggaeton => 'Reggaeton';

  @override
  String get createGenreCumbia => 'Cumbia';

  @override
  String get createGenreLatinJazz => 'Jazz latino';

  @override
  String get createGenreBhangra => 'Bhangra';

  @override
  String get createGenreIndianClassical => 'Clássica indiana';

  @override
  String get createGenreLofiHipHop => 'Hip-hop lo-fi';

  @override
  String profileAccountIdWithValue(String id) {
    return 'ID da conta: $id';
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
  String get createVocalsCustomSummary => 'Automático — conforme sua descrição';

  @override
  String mvChipMakingWithProgress(String progress) {
    return 'Fazendo o vídeo · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return 'O vídeo não pôde começar · $reason';
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
  String get inspirationHeader => 'Inspiração';

  @override
  String inspirationPlay(String name) {
    return 'Tocar $name';
  }

  @override
  String get inspirationStop => 'Parar a prévia';

  @override
  String get inspirationNameSoundscape => 'Paisagem sonora';

  @override
  String get inspirationStyleSoundscape => 'Texturas ambientes, sem voz';

  @override
  String get inspirationNameBackgroundMusic => 'Música de fundo';

  @override
  String get inspirationStyleBackgroundMusic => 'Instrumental leve para vídeos';

  @override
  String get inspirationNameMemorizeSomething => 'Para memorizar';

  @override
  String get inspirationStyleMemorizeSomething => 'Pop grudento para memorizar';

  @override
  String get inspirationNameTextMessages => 'Mensagens viram música';

  @override
  String get inspirationStyleTextMessages =>
      'Pop divertido com as suas mensagens';

  @override
  String get inspirationNameIntroMusic => 'Música de abertura';

  @override
  String get inspirationStyleIntroMusic => 'Abertura cinematográfica marcante';

  @override
  String get inspirationNameMontage => 'Montagem';

  @override
  String get inspirationStyleMontage =>
      'Crescendo animado para melhores momentos';

  @override
  String get inspirationNameSayItWithATrack => 'Diga com uma música';

  @override
  String get inspirationStyleSayItWithATrack => 'Balada pop emocionante';

  @override
  String get inspirationNameBrandJingle => 'Jingle de marca';

  @override
  String get inspirationStyleBrandJingle =>
      'Refrão curto, brilhante e marcante';

  @override
  String get inspirationNameRingtone => 'Toque de celular';

  @override
  String get inspirationStyleRingtone => 'Trecho de 30 segundos em loop';

  @override
  String get inspirationNameStreaming => 'Streaming';

  @override
  String get inspirationStyleStreaming =>
      'Abertura eletrônica animada para lives';

  @override
  String get inspirationNameSpeechToTrack => 'Da voz para a música';

  @override
  String get inspirationStyleSpeechToTrack => 'A sua voz virando música';

  @override
  String get inspirationNameRapBattle => 'Batalha de rap';

  @override
  String get inspirationStyleRapBattle => 'Hip-hop pesado';

  @override
  String get inspirationNameComedy => 'Humor';

  @override
  String get inspirationStyleComedy => 'Diferente, animado e irônico';

  @override
  String get inspirationNameTeamAnthem => 'Hino do time';

  @override
  String get inspirationStyleTeamAnthem => 'Grito de guerra de rock de estádio';

  @override
  String get inspirationNameSportsRecap => 'Resumo do jogo';

  @override
  String get inspirationStyleSportsRecap =>
      'Melhores momentos orquestrais épicos';

  @override
  String get inspirationNamePartyInvite => 'Convite para a festa';

  @override
  String get inspirationStylePartyInvite => 'Convite dance-pop';

  @override
  String get inspirationNameHappyBirthday => 'Feliz aniversário';

  @override
  String get inspirationStyleHappyBirthday =>
      'Música de aniversário acústica e calorosa';

  @override
  String get inspirationNameFriendAppreciation => 'Valeu, amigos';

  @override
  String get inspirationStyleFriendAppreciation =>
      'Indie pop de bem com a vida';

  @override
  String get inspirationNameLoveStory => 'História de amor';

  @override
  String get inspirationStyleLoveStory => 'Balada romântica de R&B';

  @override
  String get inspirationNameBirthdayRoast => 'Aniversário zoeira';

  @override
  String get inspirationStyleBirthdayRoast =>
      'Música de aniversário engraçadinha';

  @override
  String get inspirationNameOdeToYourPet => 'Ode ao seu pet';

  @override
  String get inspirationStyleOdeToYourPet => 'Pop fofo e saltitante';

  @override
  String get inspirationNameHometownTribute => 'Homenagem à sua cidade';

  @override
  String get inspirationStyleHometownTribute => 'Folk nostálgico';

  @override
  String get inspirationNameWeatherReport => 'Previsão do tempo';

  @override
  String get inspirationStyleWeatherReport => 'Groove lounge descontraído';

  @override
  String get inspirationNameBusinessPromo => 'Divulgação do seu negócio';

  @override
  String get inspirationStyleBusinessPromo => 'Pop corporativo confiante';

  @override
  String get inspirationStyleBirthdayWish =>
      'Canção sincera para o dia especial';

  @override
  String get inspirationStyleBirthdayParty =>
      'Hino de festa animado para o aniversariante';

  @override
  String get inspirationStyleThankAFriend =>
      'Canção de agradecimento calorosa e sincera';

  @override
  String get inspirationStyleWedding =>
      'Canção alegre e romântica para o grande dia';

  @override
  String get inspirationStyleInMemory => 'Homenagem suave e esperançosa';

  @override
  String get inspirationStyleFestival =>
      'Saudação festiva e brilhante da estação';

  @override
  String get inspirationStylePetAnthem =>
      'Tema carinhoso e animado para o seu pet';

  @override
  String get inspirationStyleHometown =>
      'Hino orgulhoso e nostálgico à sua cidade';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsSectionProfile => 'Perfil';

  @override
  String get settingsCredits => 'Créditos';

  @override
  String get settingsAccountId => 'ID da conta';

  @override
  String get settingsCopyAccountId => 'Copiar ID da conta';

  @override
  String get devSectionTitle => 'Desenvolvedor (só DEV)';

  @override
  String get devKeychainReset => 'Apagar chaves do Keychain';

  @override
  String get devKeychainResetHint => 'ID do dispositivo e tokens de sessão';

  @override
  String get devKeychainResetConfirmTitle => 'Apagar chaves do Keychain?';

  @override
  String get devKeychainResetConfirmBody =>
      'O ID do dispositivo e os tokens de sessão são apagados do Keychain. A conta de convidado atual não pode ser recuperada; o app entra como um novo convidado.';

  @override
  String get devKeychainResetDone =>
      'Chaves apagadas — conectado como novo convidado';

  @override
  String get settingsAppLanguage => 'Idioma do app';

  @override
  String get settingsLanguageSystem => 'Usar idioma do sistema';

  @override
  String settingsLanguageSystemValue(String language) {
    return 'Sistema ($language)';
  }

  @override
  String get settingsLanguageNativeName => 'Português (Brasil)';

  @override
  String get settingsLanguageSaveFailed =>
      'Não foi possível salvar o idioma. Tente de novo.';

  @override
  String get settingsLyricsLanguageHint => 'Vale para novas músicas.';

  @override
  String composerRemoveInspiration(String name) {
    return 'Remover $name';
  }

  @override
  String get composerPromptHint =>
      'Descreva a música ou escolha uma ideia acima';

  @override
  String get composerPromptHintWide => 'Descreva a música ou escolha uma ideia';

  @override
  String get composerWordsLabel => 'Suas palavras';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fotos adicionadas',
      one: '$countString foto adicionada',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return 'Opções da música: $summary';
  }

  @override
  String get composerOptionsShow => 'Mostrar opções';

  @override
  String get composerOptionsHide => 'Ocultar opções';

  @override
  String get composerSummaryAnyVocals => 'Qualquer vocal';

  @override
  String get composerSummaryAnyGenre => 'Qualquer gênero';

  @override
  String get composerSummaryLyrics => 'Letra própria';

  @override
  String get composerSummaryVideo => 'Vídeo com letra';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Criar prévia · grátis',
      'preview': 'Criar prévia · 1 prévia',
      'other': 'Criar prévia',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Criar a prévia de $name · grátis',
      'preview': 'Criar a prévia de $name · 1 prévia',
      'other': 'Criar a prévia de $name',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': 'Criar música completa · 1 música',
      'other': 'Criar música completa',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => 'Usar este texto';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$level começa em $seconds s';
  }

  @override
  String planPerWeek(String price) {
    return '$price/semana';
  }

  @override
  String get planCreditsWeekly => 'Novos créditos toda semana';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'no primeiro dia',
      'week': 'na primeira semana',
      'month': 'no primeiro mês',
      'year': 'no primeiro ano',
      'other': 'no primeiro período',
    });
    return '$percent% de desconto $_temp0';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return 'Após o preço promocional de $introPrice, você será cobrado $pricePerPeriod automaticamente. Cancele quando quiser antes da renovação.';
  }

  @override
  String get storePreviewAHook => 'Comece pelo nome';

  @override
  String get storePreviewAWords => 'Três palavras sobre a pessoa';

  @override
  String get storePreviewAWait => 'Sua música está sendo criada';

  @override
  String get storePreviewAChorus => 'O nome no refrão';

  @override
  String get storePreviewAEnd => 'Uma música com esse nome';

  @override
  String get storePreviewBHook => 'Comece pelas suas fotos';

  @override
  String get storePreviewBVideo => 'Inclua um vídeo com letra';

  @override
  String get storePreviewBWait => 'Criando sua música';

  @override
  String get storePreviewBLyrics => 'Letra sincronizada na tela';

  @override
  String get storePreviewBMood => 'Suas fotos criam o clima.';

  @override
  String get storePreviewBShare => 'Compartilhe o vídeo.';

  @override
  String get storePreviewBLanguage => 'Letras no seu idioma';

  @override
  String get storePreviewAShare => 'Envie como cartão';

  @override
  String get storePreviewCta => 'Crie sua primeira música';

  @override
  String get storePreviewDisclosure => 'Requer assinatura ou créditos';

  @override
  String get storeCreativeHeader => 'Músicas para quem você ama';

  @override
  String get storeCreativeSearch => 'Um nome vira uma música';

  @override
  String get storeCreativeBirthday => 'Uma música de aniversário com o nome';

  @override
  String get storeCreativePhoto => 'Suas fotos viram uma música';

  @override
  String get storeCreativeWedding => 'Uma música para o seu casamento';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get startupLoading => 'Afinando…';

  @override
  String get commonErrorTitle => 'Algo deu errado';

  @override
  String get updateRequiredTitle => 'Atualização necessária';

  @override
  String get updateRequiredMessage =>
      'É necessária uma nova versão para continuar.';

  @override
  String get updateNow => 'Atualizar agora';

  @override
  String get maintenanceTitle => 'Manutenção programada';

  @override
  String maintenanceResumeEstimate(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Previsão de retorno em cerca de $minutesString min';
  }

  @override
  String get featureUnavailable =>
      'Este recurso está temporariamente indisponível.';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navStore => 'Loja';

  @override
  String get navUpload => 'Enviar';

  @override
  String get uploadTitle => 'Envios';

  @override
  String get uploadSubtitle =>
      'Envio direto ao R2 com URL pré-assinada, hash, deduplicação instantânea e progresso.';

  @override
  String get uploadPick => 'Escolher imagem e enviar';

  @override
  String get uploadAgain => 'Enviar outra';

  @override
  String get uploadPhaseHashing => 'Calculando hash…';

  @override
  String get uploadPhaseSigning => 'Solicitando autorização de envio…';

  @override
  String uploadPhaseUploading(String percent) {
    return 'Enviando $percent';
  }

  @override
  String get uploadPhaseFinalizing => 'Finalizando…';

  @override
  String get uploadDone => 'Enviado.';

  @override
  String get uploadDedup => 'Instantâneo: este arquivo já existia no servidor.';

  @override
  String get uploadOpenLink => 'Ver arquivo';

  @override
  String get uploadFailed => 'Falha no envio.';

  @override
  String uploadTooLarge(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'O arquivo é grande demais (máx. $limitString MB).';
  }

  @override
  String get uploadUnsupportedType => 'Tipo de arquivo não compatível.';

  @override
  String get profileGuestTitle => 'Convidado';

  @override
  String get profileGuestSubtitle =>
      'Entre na sua conta para manter suas compras em todos os dispositivos.';

  @override
  String get signIn => 'Entrar';

  @override
  String get signOut => 'Sair';

  @override
  String get profileBalanceLabel => 'Créditos';

  @override
  String get profileAccountId => 'ID da conta';

  @override
  String get profileFeaturesLabel => 'Benefícios ativos';

  @override
  String get profileNoFeatures => 'Nenhum benefício ativo ainda.';

  @override
  String get profileSubscriptionLabel => 'Assinatura';

  @override
  String get profileManageSubscription => 'Gerenciar assinatura';

  @override
  String get subscriptionActive => 'Ativa';

  @override
  String get subscriptionInactive => 'Nenhuma';

  @override
  String get profileDeleteAccount => 'Apagar conta';

  @override
  String get deleteAccountTitle => 'Apagar esta conta?';

  @override
  String get deleteAccountMessage =>
      'Esta ação não pode ser desfeita: esta conta e seus créditos e benefícios ficarão permanentemente inacessíveis, e uma nova conta será criada. Apagar a conta não cancela uma assinatura ativa da App Store: gerencie-a nos ajustes da sua conta da App Store ou vincule-a novamente mais tarde com Restaurar compras.';

  @override
  String get deleteAccountConfirm => 'Apagar';

  @override
  String get deleteAccountWorking => 'Apagando conta…';

  @override
  String get deleteAccountDone => 'Conta apagada.';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Membro desde $dateString';
  }

  @override
  String get loginTitle => 'Entrar';

  @override
  String get loginUsername => 'Nome de usuário';

  @override
  String get loginPassword => 'Senha';

  @override
  String get loginSubmit => 'Entrar';

  @override
  String get paywallTitle => 'Tenha a música completa';

  @override
  String get paywallSubtitle =>
      'Transforme sua prévia em uma música de 2 minutos com letra, sua para baixar e usar.';

  @override
  String get paywallRestore => 'Restaurar compras';

  @override
  String get paywallAutoRenewNotice =>
      'O pagamento será cobrado na sua Conta Apple na confirmação da compra. As assinaturas são renovadas automaticamente pelo mesmo preço e período, a menos que sejam canceladas pelo menos 24 horas antes do fim do período atual. O teste grátis se converte em uma assinatura paga quando termina. Gerencie ou cancele a qualquer momento nos ajustes da sua conta da App Store.';

  @override
  String get paywallContinue => 'Continuar';

  @override
  String get paywallFreeTrial => 'Teste grátis';

  @override
  String get paywallOffer => 'Oferta';

  @override
  String get paywallManage => 'Gerenciar';

  @override
  String get paywallTermsOfUse => 'Termos de Uso';

  @override
  String get paywallPrivacyPolicy => 'Política de Privacidade';

  @override
  String get paywallSubscriptionTerms => 'Termos da Assinatura';

  @override
  String get commonLinkError => 'Não foi possível abrir o link.';

  @override
  String get commonError => 'Algo deu errado.';

  @override
  String get commonNetworkError =>
      'Erro de rede: verifique sua conexão e tente novamente.';

  @override
  String get commonOfflineError =>
      'Parece que você está offline. Verifique sua conexão e tente novamente.';

  @override
  String get networkErrorTitle => 'Problema de conexão';

  @override
  String get configErrorTitle => 'Problema de configuração do app';

  @override
  String get configErrorMessage =>
      'Esta versão não consegue acessar nosso serviço. Atualize o app pela App Store ou reinstale-o. Se o problema persistir, entre em contato com o suporte.';

  @override
  String get commonAuthError => 'Sua sessão expirou. Entre novamente.';

  @override
  String get paywallProductsErrorTitle =>
      'Não foi possível carregar os produtos';

  @override
  String get paywallNoProducts => 'Nenhum produto disponível no momento.';

  @override
  String get paywallPurchaseSuccess => 'Compra concluída. Aproveite!';

  @override
  String get paywallProcessing => 'Processando sua compra…';

  @override
  String get paywallVerifying => 'Verificando sua compra…';

  @override
  String get paywallPurchaseFailed => 'Não foi possível concluir a compra.';

  @override
  String get paywallRestoreStarted => 'Restaurando suas compras…';

  @override
  String paywallRestoreSuccess(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString compras restauradas.',
      one: '$countString compra restaurada.',
    );
    return '$_temp0';
  }

  @override
  String get paywallRestoreNothing => 'Nenhuma compra para restaurar.';

  @override
  String get paywallDeferred =>
      'Aguardando aprovação. Vamos concluir assim que for aprovada.';

  @override
  String get paywallAlreadySubscribed => 'Você já é assinante.';

  @override
  String get paywallBillingRetry =>
      'Atualize sua forma de pagamento para manter sua assinatura.';

  @override
  String paywallTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Teste grátis de $daysString dias';
  }

  @override
  String get cycleOneTime => 'pagamento único';

  @override
  String get cycleWeekly => '/ semana';

  @override
  String get cycleMonthly => '/ mês';

  @override
  String get cycleQuarterly => '/ trimestre';

  @override
  String get cycleSemiAnnual => '/ 6 meses';

  @override
  String get cycleAnnual => '/ ano';

  @override
  String get cycleLifetime => 'vitalício';

  @override
  String get navCreate => 'Criar';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonBack => 'Voltar';

  @override
  String get createTitle => 'Para quem é esta música?';

  @override
  String get occasionBirthday => 'Aniversário';

  @override
  String get occasionBirthdayHint => 'Uma música alegre para o grande dia';

  @override
  String get occasionAnniversary => 'Aniversário de casal';

  @override
  String get occasionAnniversaryHint => 'Celebrem a história de vocês';

  @override
  String get occasionConfession => 'Declaração de amor';

  @override
  String get occasionConfessionHint => 'Diga o que seu coração sente';

  @override
  String get occasionWedding => 'Casamento';

  @override
  String get occasionWeddingHint => 'Uma música para o momento de uma vida';

  @override
  String get occasionMemorial => 'Em memória';

  @override
  String get occasionMemorialHint => 'Homenageie alguém especial';

  @override
  String get occasionFestival => 'Festividade';

  @override
  String get occasionFestivalHint => 'Votos calorosos para uma época especial';

  @override
  String get occasionBrand => 'Jingle de marca';

  @override
  String get occasionBrandHint => 'Uma melodia chiclete para sua marca';

  @override
  String get occasionSoundtrack => 'Trilha para vídeo';

  @override
  String get occasionSoundtrackHint => 'Música que combina com sua história';

  @override
  String get festivalNewYear => 'Ano-Novo';

  @override
  String get festivalThanksgiving => 'Ação de Graças';

  @override
  String get festivalDiwali => 'Diwali';

  @override
  String get festivalCarnival => 'Carnaval';

  @override
  String get festivalEid => 'Eid';

  @override
  String get festivalLunarNewYear => 'Ano-Novo Lunar';

  @override
  String get regionTitle => 'Onde ela vai tocar?';

  @override
  String get regionSearchHint => 'Buscar país';

  @override
  String get regionLanguageSheetTitle => 'Idioma da letra';

  @override
  String get countryUS => 'Estados Unidos';

  @override
  String get countryGB => 'Reino Unido';

  @override
  String get countryCA => 'Canadá';

  @override
  String get countryAU => 'Austrália';

  @override
  String get countryDE => 'Alemanha';

  @override
  String get countryFR => 'França';

  @override
  String get countryJP => 'Japão';

  @override
  String get countryKR => 'Coreia do Sul';

  @override
  String get countryBR => 'Brasil';

  @override
  String get countryMX => 'México';

  @override
  String get countryIN => 'Índia';

  @override
  String get countryID => 'Indonésia';

  @override
  String get countryVN => 'Vietnã';

  @override
  String get countryTR => 'Turquia';

  @override
  String get languageEn => 'Inglês';

  @override
  String get languageFr => 'Francês';

  @override
  String get languageDe => 'Alemão';

  @override
  String get languageJa => 'Japonês';

  @override
  String get languageKo => 'Coreano';

  @override
  String get languagePtBR => 'Português (Brasil)';

  @override
  String get languageEsMX => 'Espanhol (México)';

  @override
  String get languageHi => 'Hindi';

  @override
  String get languageId => 'Indonésio';

  @override
  String get languageVi => 'Vietnamita';

  @override
  String get languageTr => 'Turco';

  @override
  String get languageZhHans => 'Chinês (simplificado)';

  @override
  String get languageZhHant => 'Chinês (tradicional)';

  @override
  String get inputNameLabel => 'Nome da pessoa';

  @override
  String get inputNameOptionalLabel => 'Nome (opcional)';

  @override
  String get inputNameHint => 'ex.: Alex';

  @override
  String get inputKeywordsLabel => 'Três palavras sobre a pessoa';

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
      'Esta letra é minha ou tenho o direito de usá-la';

  @override
  String get issueRecipientMissing => 'Adicione o nome da pessoa.';

  @override
  String get issueRecipientTooLong => 'Os nomes podem ter até 24 caracteres.';

  @override
  String get issueBriefMissing =>
      'Conte sobre a música: algumas palavras, letra ou fotos.';

  @override
  String get issueDescriptionMissing =>
      'Esta ideia precisa das suas palavras: escreva uma frase sobre a música.';

  @override
  String get generatingBackToEdit => 'Voltar para editar';

  @override
  String get issueKeywordTooLong => 'Cada palavra pode ter até 20 caracteres.';

  @override
  String get issueTooManyKeywords => 'Use no máximo três palavras.';

  @override
  String get issueArtistName =>
      'Não é possível usar nomes de artistas. Descreva o sentimento.';

  @override
  String get issueStyleImitation =>
      'Não podemos imitar um cantor ou uma banda. Descreva o clima.';

  @override
  String issueLyricsTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'A letra pode ter até $limitString caracteres.';
  }

  @override
  String get issueLyricsNotOriginal =>
      'Esta letra parece uma música existente. Escreva a sua.';

  @override
  String get issueLyricsOwnership =>
      'Confirme que você tem o direito de usar a letra.';

  @override
  String get issueTooManyPhotos => 'Escolha até 10 fotos.';

  @override
  String get photosTitle => 'Escolha algumas fotos';

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
      'As fotos são usadas uma única vez para escrever a música e apagadas dos nossos servidores em até 24 horas.';

  @override
  String get photosAdd => 'Adicionar fotos';

  @override
  String get photosCreate => 'Criar com fotos';

  @override
  String get photosEmpty => 'Escolha de 1 a 10 fotos do momento.';

  @override
  String get generatingStepPolishing => 'Refinando suas palavras neste iPhone…';

  @override
  String get generatingStepUploading => 'Enviando suas fotos…';

  @override
  String get generatingStepSubmitting => 'Enviando para o estúdio…';

  @override
  String get errorSafetyBlocked =>
      'Não conseguimos criar esta. Tente outras palavras e não use nomes de artistas.';

  @override
  String get errorQuotaExhausted =>
      'Você já usou as músicas deste mês. Adicione um pacote ou faça upgrade.';

  @override
  String get errorUpstreamTimeout =>
      'Está demorando mais que o normal. Vamos continuar tentando e avisaremos você.';

  @override
  String get errorUpstreamRateLimited =>
      'Muitas músicas sendo criadas agora. A sua está na fila.';

  @override
  String get errorAttestFailed => 'Atualize o Songlet pela App Store.';

  @override
  String get errorImageRejected =>
      'Uma dessas fotos não pode ser usada. Tente outra.';

  @override
  String get errorNetworkOffline =>
      'Você está offline. Sua biblioteca continua funcionando.';

  @override
  String get errorDownloadLocked =>
      'Não é possível baixar esta música: a compra usada para criá-la foi reembolsada ou seu plano terminou. Você ainda pode ouvi-la.';

  @override
  String get errorJobAlreadyFinished =>
      'Já terminou — não há nada para cancelar.';

  @override
  String get errorMvSongNotReady =>
      'Esta música ainda não está pronta para um vídeo.';

  @override
  String get errorMvSongTooLong =>
      'Esta música é longa demais para um vídeo completo — tente um vídeo do refrão.';

  @override
  String get errorMvSongExpired =>
      'Esta música expirou. Gere-a de novo para fazer um vídeo.';

  @override
  String get errorMvNotFound => 'Este vídeo não está mais disponível.';

  @override
  String get errorMvPhotosExpired =>
      'Essas fotos expiraram — escolha-as de novo.';

  @override
  String get errorMvRenderFailed =>
      'Não conseguimos terminar este vídeo. Seus créditos voltaram — tente de novo.';

  @override
  String get mvHubTitle => 'Fazer um vídeo';

  @override
  String mvHubSubtitle(String title) {
    return 'Transforme “$title” em um videoclipe.';
  }

  @override
  String get mvLevelLyricVideo => 'Vídeo com letra';

  @override
  String get mvLevelLyricHint => 'Uma cena fixa com a sua letra';

  @override
  String get mvLevelChorus => 'Vídeo do refrão';

  @override
  String get mvLevelChorusHint => '30 segundos do seu refrão, filmados por IA';

  @override
  String get mvLevelFull => 'Vídeo da música inteira';

  @override
  String get mvLevelFullHint => 'A música inteira, cena a cena';

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
      other: 'Você tem $creditsString créditos',
      one: 'Você tem $creditsString crédito',
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
      other: 'Faltam $creditsString créditos',
      one: 'Falta $creditsString crédito',
    );
    return '$_temp0';
  }

  @override
  String get mvEstimating => 'Verificando o preço…';

  @override
  String get mvOptionsHeader => 'Opções';

  @override
  String get mvAspectLabel => 'Formato';

  @override
  String get mvAspectPortrait => 'Vertical';

  @override
  String get mvAspectLandscape => 'Horizontal';

  @override
  String get mvAspectSquare => 'Quadrado';

  @override
  String get mvQualityLabel => 'Qualidade';

  @override
  String get mvQualityStandard => 'Padrão';

  @override
  String get mvQualityHigh => 'Alta';

  @override
  String get mvSubtitlesLabel => 'Letra na tela';

  @override
  String get mvPhotosLabel => 'Fotos de referência';

  @override
  String get mvPhotosHint =>
      'Definem o clima e as cores — rostos não são usados';

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
  String get mvChorusLabel => 'Refrão';

  @override
  String get mvChorusAuto => 'Encontrado automaticamente';

  @override
  String get mvChorusCustom => 'Escolher o trecho';

  @override
  String mvChorusRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get mvCreate => 'Fazer o vídeo';

  @override
  String get mvBuyPack => 'Pegue o pacote e faça';

  @override
  String get mvSongLocked => 'Sua música foi salva para o vídeo.';

  @override
  String get mvGeneratingTitle => 'Fazendo o seu vídeo…';

  @override
  String get mvStageQueued => 'Aguardando para começar';

  @override
  String get mvStageSlicing => 'Escolhendo os momentos';

  @override
  String get mvStageStoryboarding => 'Escrevendo o storyboard';

  @override
  String get mvStageKeyframing => 'Pintando as cenas';

  @override
  String get mvStageRendering => 'Filmando as cenas';

  @override
  String get mvStageAssembling => 'Montando o vídeo';

  @override
  String get mvStageDone => 'Pronto';

  @override
  String mvScenes(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Cena $doneString de $totalString';
  }

  @override
  String mvUsuallyMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Geralmente uns $minutesString minutos';
  }

  @override
  String get mvCancelRequested => 'Vai parar depois da cena atual…';

  @override
  String get mvCancelTitle => 'Parar este vídeo?';

  @override
  String get mvCancelQueued => 'Ainda não começou, então nada será usado.';

  @override
  String get mvCancelStarted =>
      'Já começou. As cenas prontas são cobradas; o resto volta.';

  @override
  String get mvCancelConfirm => 'Parar vídeo';

  @override
  String get mvCancelled => 'Vídeo parado';

  @override
  String get mvCancelledRefunded => 'Vídeo parado — nada foi usado';

  @override
  String get mvNothing => 'Nenhum vídeo sendo feito agora.';

  @override
  String get mvQuotaTitle => 'Créditos insuficientes';

  @override
  String get mvAiLabelBurnedIn => 'Gerado por IA — o selo faz parte do vídeo';

  @override
  String get mvSave => 'Salvar em Fotos';

  @override
  String get mvSaveFiles => 'Salvar em Arquivos';

  @override
  String get mvShareText => 'Fiz este videoclipe com o Songlet 🎬';

  @override
  String get mvMissing => 'Este vídeo não está mais neste aparelho.';

  @override
  String get mvDeleteTitle => 'Excluir este vídeo?';

  @override
  String get mvDeleteBody => 'Ele é removido deste aparelho.';

  @override
  String get mvDeleted => 'Vídeo excluído';

  @override
  String get mvProvenance =>
      'Feito com Google Lyria 3 e modelos de vídeo com IA · Gerado por IA';

  @override
  String get detailVideos => 'Vídeos';

  @override
  String get detailMakeVideo => 'Fazer um vídeo';

  @override
  String get mvStatusReady => 'Pronto';

  @override
  String get mvStatusPending => 'Fazendo…';

  @override
  String get mvStatusFailed => 'Não terminou';

  @override
  String get mvPackTitle => 'Videoclipe';

  @override
  String get mvPackChorusSubtitle => 'Um vídeo do refrão';

  @override
  String get mvPackFullSubtitle => 'Um vídeo da música inteira';

  @override
  String get paywallMvHeroTitle => 'Transforme em vídeo';

  @override
  String get paywallMvHeroSubtitle =>
      'Créditos para um videoclipe da sua música — para salvar e compartilhar.';

  @override
  String get playerAiGenerated => 'Gerado por IA';

  @override
  String get playerLoop => 'Repetir';

  @override
  String get playerPlay => 'Reproduzir';

  @override
  String get playerPause => 'Pausar';

  @override
  String get playerPreviewLabel => 'Prévia de 30 segundos';

  @override
  String playerTitleFor(String name) {
    return 'Para $name';
  }

  @override
  String get downloadSaved => 'Salvo em Arquivos.';

  @override
  String get shareComposing => 'Criando seu cartão para compartilhar…';

  @override
  String get shareFailed =>
      'Não foi possível criar o cartão para compartilhar.';

  @override
  String get shareText => 'Fiz esta música com o Songlet 🎵';

  @override
  String get paywallBestValue => 'Melhor custo-benefício';

  @override
  String get paywallStartTrial => 'Começar teste grátis';

  @override
  String get paywallClose => 'Fechar';

  @override
  String get paywallSeePlans => 'Ver assinaturas';

  @override
  String paywallCurrentPlan(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Seu plano está ativo: restam $countString músicas completas neste período.',
      one:
          'Seu plano está ativo: resta $countString música completa neste período.',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmpty => 'Suas músicas vão ficar aqui.';

  @override
  String get libraryEmptyAction => 'Crie sua primeira música';

  @override
  String get libraryPending => 'Compondo…';

  @override
  String get libraryPreviewBadge => 'Prévia';

  @override
  String get librarySongBadge => 'Música completa';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsPlan => 'Seu plano';

  @override
  String get settingsPlanUnavailable =>
      'Não foi possível carregar seu plano. Puxe para baixo para tentar novamente mais tarde.';

  @override
  String get tierFree => 'Sem assinatura';

  @override
  String get tierPack => 'Pacotes de músicas';

  @override
  String settingsSongsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString músicas completas restantes',
      one: '$countString música completa restante',
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
      other: '$countString prévias restantes',
      one: '$countString prévia restante',
    );
    return '$_temp0';
  }

  @override
  String settingsResets(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Renova em $dateString';
  }

  @override
  String get settingsUpgrade => 'Fazer upgrade';

  @override
  String get appTagline => 'Músicas para as pessoas que você ama';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonDone => 'Concluir';

  @override
  String get commonDelete => 'Apagar';

  @override
  String get commonMore => 'Mais';

  @override
  String get commonCopy => 'Copiar';

  @override
  String get commonCopied => 'Copiado';

  @override
  String get commonNotNow => 'Agora não';

  @override
  String get commonLearnMore => 'Saiba mais';

  @override
  String get commonSeeAll => 'Ver tudo';

  @override
  String get commonKeepGoing => 'Continuar';

  @override
  String get composerHint => 'Descreva a música que você quer';

  @override
  String get composerAddPhotos => 'Adicionar fotos';

  @override
  String get composerSourceMusicHint => 'Descreva com suas palavras';

  @override
  String get composerDictate => 'Ditar';

  @override
  String get composerStopDictation => 'Parar ditado';

  @override
  String get lengthPreview => 'Prévia';

  @override
  String get lengthFull => 'Música completa';

  @override
  String get paramLength => 'Duração';

  @override
  String get paramVocals => 'Vocal';

  @override
  String get paramGenre => 'Gênero';

  @override
  String templatePlaySample(String name) {
    return 'Ouvir uma amostra de $name';
  }

  @override
  String get templatePauseSample => 'Pausar a amostra';

  @override
  String get lengthShort => 'Curta';

  @override
  String get lengthShortHint => 'Prévia de 30 segundos';

  @override
  String get lengthStandard => 'Padrão';

  @override
  String get lengthStandardHint => 'cerca de 2 minutos, Pro';

  @override
  String get vocalsCustom => 'Automático';

  @override
  String get vocalsCustomHint => 'conforme sua descrição';

  @override
  String get vocalsCustomDetail => 'O estilo vocal segue sua descrição.';

  @override
  String get vocalsOn => 'Com vocal';

  @override
  String get vocalsInstrumental => 'Instrumental';

  @override
  String vocalsLyricsIn(String language) {
    return 'Letra em $language';
  }

  @override
  String get genreCustom => 'Automático';

  @override
  String get genreCustomHint => 'conforme sua descrição';

  @override
  String genrePopularIn(String country) {
    return 'Populares: $country';
  }

  @override
  String get genreAll => 'Todos os gêneros';

  @override
  String get regionHelper =>
      'Muda os 3 gêneros recomendados e o idioma da letra';

  @override
  String regionLyricsRow(String language) {
    return 'Idioma da letra: $language';
  }

  @override
  String get regionNoMatch => 'Nenhum país encontrado';

  @override
  String get keywordAdd => 'Adicionar uma palavra';

  @override
  String keywordRemove(String word) {
    return 'Remover $word';
  }

  @override
  String get nameClear => 'Limpar nome';

  @override
  String get lyricsOptional => 'Escreva sua própria letra (opcional)';

  @override
  String get issueRecipientArtistName =>
      'Não é possível usar nomes de artistas.';

  @override
  String issuePromptTooLong(int limit) {
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Use menos de $limitString caracteres na descrição.';
  }

  @override
  String get voiceRecording => 'Gravando…';

  @override
  String get voiceStarting => 'Iniciando…';

  @override
  String get voiceListening => 'Diga para quem é e do que a pessoa gosta…';

  @override
  String get voiceOnDevice => 'Transcrição no aparelho';

  @override
  String get voicePermissionDenied =>
      'Permita o microfone e o reconhecimento de fala para o Songlet em Ajustes para ditar.';

  @override
  String get voiceUnavailable =>
      'O ditado não está disponível para este idioma neste aparelho.';

  @override
  String get voiceApplied => 'Adicionado pela sua voz';

  @override
  String get photoRemove => 'Remover foto';

  @override
  String generatingTitleFor(String name) {
    return 'Escrevendo a música de $name…';
  }

  @override
  String get generatingTitleGeneric => 'Escrevendo sua música…';

  @override
  String generatingUsually(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Normalmente cerca de $secondsString segundos';
  }

  @override
  String generatingPercent(String percent) {
    return '$percent';
  }

  @override
  String get generatingProgress => 'Progresso';

  @override
  String get generatingGlimpse => 'Uma prévia da sua música';

  @override
  String get generatingCancelTitle => 'Parar esta música?';

  @override
  String get generatingCancelQueued =>
      'Ela ainda não começou, então não conta no seu limite.';

  @override
  String get generatingCancelStarted =>
      'Ela já começou, então conta no seu limite.';

  @override
  String get generatingCancelConfirm => 'Parar';

  @override
  String get generatingCancelled => 'Música interrompida';

  @override
  String get generatingCancelledRefunded =>
      'Música interrompida — nada foi usado';

  @override
  String get queueTitle => 'Muitas músicas estão sendo criadas agora.';

  @override
  String get queueSubtitle => 'A sua está na fila.';

  @override
  String get queuePosition => 'Posição';

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
  String get generatingNothing => 'Nenhuma música está sendo criada agora.';

  @override
  String get previewGetFull => 'Obter a música completa de 2 minutos';

  @override
  String get previewShare => 'Compartilhar prévia';

  @override
  String get previewAnother => 'Tentar outra versão (usa 1 prévia)';

  @override
  String get playerPosition => 'Posição da reprodução';

  @override
  String get playerPrevSection => 'Seção anterior';

  @override
  String get playerNextSection => 'Próxima seção';

  @override
  String get playerShuffle => 'Seções aleatórias';

  @override
  String get playerRepeat => 'Repetir';

  @override
  String get playerProvenance =>
      'Feita com Google Lyria 3 · marca d’água SynthID · gerada por IA';

  @override
  String get playerMissing => 'Esta música não está mais neste aparelho.';

  @override
  String get actionDownload => 'Baixar';

  @override
  String get actionShare => 'Compartilhar';

  @override
  String get actionLicense => 'Licença';

  @override
  String get actionRegenerate => 'Gerar de novo';

  @override
  String get actionDetails => 'Detalhes';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionVerse => 'Verso';

  @override
  String get sectionPreChorus => 'Pré-refrão';

  @override
  String get sectionChorus => 'Refrão';

  @override
  String get sectionBridge => 'Ponte';

  @override
  String get sectionOutro => 'Final';

  @override
  String get sectionHook => 'Gancho';

  @override
  String get shareTitle => 'Cartão para compartilhar';

  @override
  String get shareSubtitle => 'Escolha um tema e um layout.';

  @override
  String get shareTheme => 'Tema';

  @override
  String get shareLayout => 'Layout';

  @override
  String get shareLayoutScene => 'Com ilustração';

  @override
  String get shareLayoutText => 'Só texto';

  @override
  String get paletteTerracotta => 'Terracota';

  @override
  String get paletteSand => 'Areia';

  @override
  String get paletteOlive => 'Oliva';

  @override
  String get paletteNavy => 'Azul-marinho';

  @override
  String get shareAction => 'Compartilhar';

  @override
  String get shareSaveVideo => 'Salvar vídeo';

  @override
  String get shareCopyLyrics => 'Copiar letra';

  @override
  String get shareVideoSaved => 'Salvo em Fotos';

  @override
  String get shareLyricsCopied => 'Letra copiada';

  @override
  String get shareCardTagline => 'Uma música para alguém';

  @override
  String get shareSaveFailed =>
      'Não foi possível salvar o vídeo. Permita que o Songlet adicione a Fotos em Ajustes.';

  @override
  String get downloadReady => 'Música completa pronta';

  @override
  String get downloadTitle => 'Sua para sempre';

  @override
  String get downloadIntro =>
      'Sua música está pronta. Baixe o áudio em alta qualidade e sua licença comercial abaixo.';

  @override
  String get downloadAudioHeader => 'Baixar áudio';

  @override
  String get downloadAudioNote => 'Alta qualidade';

  @override
  String get downloadMp3Title => 'MP3 · 320 kbps';

  @override
  String get downloadMp3Subtitle =>
      'Ideal para compartilhar e ouvir no dia a dia';

  @override
  String get downloadWavTitle => 'WAV · 44,1 kHz (Premier)';

  @override
  String get downloadWavSubtitle =>
      'A mais alta qualidade para uso profissional';

  @override
  String get downloadMp3Action => 'Baixar MP3';

  @override
  String get downloadWavAction => 'Baixar WAV';

  @override
  String get downloadLicenseAction => 'Baixar licença';

  @override
  String get licenseHeader => 'Licença comercial';

  @override
  String get licenseIncluded => 'Incluída no seu plano';

  @override
  String get licenseNotIncluded => 'Disponível com um plano ou pacote';

  @override
  String get licensePdfTitle => 'Licença comercial (PDF)';

  @override
  String licenseGenerated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Gerada em $dateString';
  }

  @override
  String licenseId(String id) {
    return 'ID da licença: $id';
  }

  @override
  String get licenseUsesTitle => 'Você pode usar esta música para:';

  @override
  String get usePersonal => 'Uso pessoal';

  @override
  String get usePersonalDetail => 'Presentes, lembranças, sem fins comerciais';

  @override
  String get useAds => 'Anúncios e marketing';

  @override
  String get useAdsDetail => 'Promoções, campanhas pagas';

  @override
  String get useSocial => 'Redes sociais';

  @override
  String get useSocialDetail => 'TikTok, Instagram, YouTube etc.';

  @override
  String get usePodcasts => 'Podcasts e vídeos';

  @override
  String get usePodcastsDetail => 'Conteúdo monetizado';

  @override
  String get licenseDetailsNote => 'Todos os detalhes estão no PDF da licença.';

  @override
  String get saveEnjoyHeader => 'Salve e aproveite';

  @override
  String get saveToFiles => 'Salvar em Arquivos';

  @override
  String get addToMusic => 'Adicionar ao Música';

  @override
  String get synthIdNote =>
      'Esta música contém uma marca d’água SynthID que a identifica como conteúdo gerado por IA, mesmo depois de baixada.';

  @override
  String get wavNeedsPremier => 'Downloads em WAV fazem parte do Premier.';

  @override
  String get wavUnavailable =>
      'Esta música não tem arquivo WAV. Arquivos WAV podem ser salvos em até 24 horas após a criação da música.';

  @override
  String get libraryFilterAll => 'Todas';

  @override
  String get libraryJustBecause => 'Só porque sim';

  @override
  String libraryPlay(String title) {
    return 'Tocar $title';
  }

  @override
  String libraryActions(String title) {
    return 'Ações para $title';
  }

  @override
  String get libraryDeleteTitle => 'Apagar esta música?';

  @override
  String get libraryDeleteBody =>
      'Ela será removida deste aparelho. Se a sincronização do iCloud estiver ligada, também dos seus outros aparelhos.';

  @override
  String get libraryDeleted => 'Música apagada';

  @override
  String get libraryFailed => 'Não concluída';

  @override
  String get libraryNoMatch => 'Ainda não há músicas para esta ocasião.';

  @override
  String get detailFullGenerated => 'Música completa gerada';

  @override
  String get detailPreviewGenerated => 'Prévia gerada';

  @override
  String detailGeneratedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Gerada em $dateString';
  }

  @override
  String get detailPromptUsed => 'Dados usados';

  @override
  String get detailOccasion => 'Ocasião';

  @override
  String get detailCountry => 'País';

  @override
  String get detailGenre => 'Gênero';

  @override
  String get detailKeywords => 'Palavras-chave';

  @override
  String get detailDescription => 'Descrição';

  @override
  String get detailLyrics => 'Letra';

  @override
  String get detailGenerationId => 'ID de geração';

  @override
  String get detailRegenerate => 'Gerar de novo no mesmo estilo';

  @override
  String get detailCustomGenre => 'Conforme a descrição';

  @override
  String get settingsSectionPlan => 'Compras';

  @override
  String get settingsSectionLibrary => 'Biblioteca';

  @override
  String get settingsSectionAbout => 'Sobre';

  @override
  String get settingsRestore => 'Restaurar compras';

  @override
  String get settingsManage => 'Gerenciar assinatura';

  @override
  String get settingsICloud => 'Sincronização do iCloud';

  @override
  String get settingsICloudOn => 'As músicas sincronizam entre seus aparelhos';

  @override
  String get settingsICloudOff => 'As músicas ficam neste aparelho';

  @override
  String get settingsICloudUnavailable =>
      'Entre no iCloud em Ajustes para sincronizar';

  @override
  String get settingsLyricsLanguage => 'Idioma padrão da letra';

  @override
  String get settingsLyricsLanguageAuto => 'Conforme o país';

  @override
  String get settingsTerms => 'Termos de Uso';

  @override
  String get settingsPrivacy => 'Política de Privacidade';

  @override
  String settingsVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get aboutTitle => 'Sobre a geração';

  @override
  String get aboutSubtitle => 'Como o Songlet cria suas músicas';

  @override
  String get aboutLyriaTitle => 'Com o Lyria 3 do Google';

  @override
  String get aboutLyriaBody =>
      'As músicas são geradas pelo Lyria 3 do Google por meio da API Gemini. O Lyria 3 é um modelo de geração musical que transforma suas ideias em músicas originais.';

  @override
  String get aboutWatermarkTitle => 'Marca d’água integrada';

  @override
  String get aboutWatermarkBody =>
      'Toda música inclui uma marca d’água SynthID do Google. Ela ajuda a identificar música gerada por IA e não pode ser removida.';

  @override
  String get aboutImitationTitle => 'Sem imitar artistas reais';

  @override
  String get aboutImitationBody =>
      'O Songlet nunca imita artistas reais, suas vozes ou estilos específicos. As músicas são originais e criadas a partir das suas ideias, descrições e fotos.';

  @override
  String get aboutPrivacyTitle => 'Sua privacidade importa';

  @override
  String get aboutPrivacyBody =>
      'Fotos e descrições são apagadas dos nossos servidores em até 24 horas. Não guardamos suas imagens nem descrições depois que a música é gerada.';

  @override
  String get aboutBanner =>
      'Toda música que você compartilha é identificada como gerada por IA.';

  @override
  String aboutFooter(String version) {
    return 'Songlet $version · Feito com Google Lyria 3';
  }

  @override
  String get festivalKicker => 'Viva a sua história';

  @override
  String get festivalComing => 'está chegando!';

  @override
  String get festivalBody =>
      'Crie uma música única para celebrar essa energia.';

  @override
  String festivalCta(String festival) {
    return 'Fazer uma música de $festival';
  }

  @override
  String get festivalPickOccasion => 'Escolha uma ocasião e comece a criar';

  @override
  String get festivalLanguagesTitle => 'Músicas no seu idioma';

  @override
  String festivalLanguagesBody(String language) {
    return 'Crie músicas em $language e em mais 12 idiomas';
  }

  @override
  String get unavailableTitle => 'Temporariamente indisponível';

  @override
  String get unavailableMessage =>
      'O Songlet não consegue criar músicas agora. Sua biblioteca continua funcionando — tente de novo daqui a pouco.';

  @override
  String get paywallHeroTitle => 'Transforme em música completa';

  @override
  String get paywallHeroSubtitle =>
      'Leve sua ideia a uma música completa, com mais qualidade e todos os direitos.';

  @override
  String get paywallBenefitSongs => 'Mais músicas';

  @override
  String get paywallBenefitQuality => 'Mais qualidade';

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
      other: '$countString músicas completas por mês',
      one: '$countString música completa por mês',
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
      other: '$countString prévias por mês',
      one: '$countString prévia por mês',
    );
    return '$_temp0';
  }

  @override
  String get planMp3 => 'Download em MP3';

  @override
  String get planMp3Wav => 'Download em MP3 + WAV';

  @override
  String get planLicense => 'Licença comercial';

  @override
  String get planPriority => 'Geração prioritária';

  @override
  String planTrial(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Teste grátis de $daysString dias';
  }

  @override
  String planPerYear(String price) {
    return '$price/ano';
  }

  @override
  String planPerMonth(String price) {
    return '$price/mês';
  }

  @override
  String get packTitle => 'Precisa de só algumas?';

  @override
  String packSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pacote de $countString músicas',
      one: 'Pacote de $countString música',
    );
    return '$_temp0';
  }

  @override
  String get packNote => 'não expira';

  @override
  String get valueForever => 'Suas músicas, para sempre';

  @override
  String get valueDownloads => 'Downloads em alta qualidade';

  @override
  String get valueCommercial => 'Uso comercial permitido';

  @override
  String get valuePrivate => 'Privacidade em primeiro lugar';

  @override
  String paywallTrialDisclosure(String pricePerPeriod) {
    return 'Após o teste grátis, serão cobrados $pricePerPeriod automaticamente. Cancele quando quiser antes do fim do teste.';
  }

  @override
  String get paywallSubscribe => 'Assinar';

  @override
  String get paywallBuyPack => 'Comprar pacote';

  @override
  String get templateBirthdayWish => 'Parabéns';

  @override
  String get templateBirthdayWishHint =>
      'Uma música especial para um dia especial';

  @override
  String get templateBirthdayParty => 'Festa de aniversário';

  @override
  String get templateBirthdayPartyHint => 'Anime a festa do aniversariante';

  @override
  String get templateLoveStory => 'História de amor';

  @override
  String get templateLoveStoryHint => 'A história de vocês em forma de música';

  @override
  String get templateThankAFriend => 'Obrigado, amigo';

  @override
  String get templateThankAFriendHint =>
      'Agradeça como as palavras não conseguem';

  @override
  String get templatePartyInvite => 'Convite para festa';

  @override
  String get templatePartyInviteHint => 'Chame todo mundo para a festa';

  @override
  String get templateWedding => 'Casamento';

  @override
  String get templateWeddingHint => 'Uma música para o momento eterno deles';

  @override
  String get templateInMemory => 'Em memória';

  @override
  String get templateInMemoryHint => 'Homenageie alguém querido';

  @override
  String get templateFestival => 'Festas';

  @override
  String get templateFestivalHint => 'Votos carinhosos para uma época especial';

  @override
  String get templateRingtone => 'Toque';

  @override
  String get templateRingtoneHint => 'Um loop curto só seu';

  @override
  String get templateTeamAnthem => 'Hino do time';

  @override
  String get templateTeamAnthemHint => 'Anime o time e a torcida';

  @override
  String get templateSportsRecap => 'Resumo do jogo';

  @override
  String get templateSportsRecapHint => 'O grande jogo em forma de música';

  @override
  String get templateRapBattle => 'Batalha de rap';

  @override
  String get templateRapBattleHint => 'Rimas amigáveis para um rival amigável';

  @override
  String get templateComedy => 'Comédia';

  @override
  String get templateComedyHint => 'Piadas internas, agora com refrão';

  @override
  String get templatePetAnthem => 'Hino do pet';

  @override
  String get templatePetAnthemHint => 'Uma música-tema para o seu melhor amigo';

  @override
  String get templateHometown => 'Minha cidade';

  @override
  String get templateHometownHint => 'Amor pelo lugar que você chama de lar';

  @override
  String get templateBusinessPromo => 'Promo do negócio';

  @override
  String get templateBusinessPromoHint =>
      'Um jingle chiclete para sua loja ou marca';

  @override
  String get templateCustom => 'Sua própria ideia';

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
  String get mvViewProgress => 'Ver o progresso';

  @override
  String mvIntentWaiting(String level) {
    return '$level está esperando créditos';
  }

  @override
  String get mvSongExpiredAction => 'Fazer a música de novo';

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
    return '$level precisa de $_temp0. Você tem $availableString.';
  }

  @override
  String get mvQuotaBuyAndContinue => 'Comprar e continuar';

  @override
  String get mvQuotaMayNeedTwice =>
      'Onde você está, um pacote pode não bastar — talvez precise de dois.';

  @override
  String get mvQuotaAutoRetry =>
      'Seu vídeo começa assim que a compra for concluída.';

  @override
  String get mvAutoLyricMaking => 'Fazendo seu vídeo com letra';

  @override
  String get mvAutoChorusDetail => 'Feito com esta música e seus créditos';

  @override
  String mvAutoReady(String level) {
    return '$level está pronto';
  }

  @override
  String get mvAutoView => 'Ver';

  @override
  String get mvUpgradeChorus => 'Fazer um vídeo do refrão';

  @override
  String get mvAutoFailed => 'O vídeo não pôde começar';

  @override
  String get mvLeaveHint =>
      'Você pode sair desta tela — avisamos quando ele deve estar pronto.';

  @override
  String mvCreditsBack(int credits) {
    final intl.NumberFormat creditsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String creditsString = creditsNumberFormat.format(credits);

    String _temp0 = intl.Intl.pluralLogic(
      credits,
      locale: localeName,
      other: 'Seus $creditsString créditos foram devolvidos.',
      one: 'Seu crédito foi devolvido.',
    );
    return '$_temp0';
  }

  @override
  String get mvFailedTitle => 'Este vídeo não foi concluído';

  @override
  String get mvRejectedTitle => 'Uma foto não pôde ser usada';

  @override
  String get mvRejectedBody =>
      'O modelo de vídeo recusou uma das suas fotos de referência. Ajuste as fotos e tente de novo.';

  @override
  String get mvAdjustPhotos => 'Ajustar fotos e tentar de novo';

  @override
  String get mvTryChorus => 'Fazer um vídeo do refrão';

  @override
  String get mvPreparingPhotos => 'Enviando suas fotos…';

  @override
  String get mvPreparingSubmit => 'Enviando seu vídeo…';

  @override
  String get mvNotifyTitle => 'Seu vídeo já deve estar pronto';

  @override
  String mvNotifyBody(String level) {
    return '$level — toque para assistir.';
  }

  @override
  String get mvRegenerate => 'Fazer outro';

  @override
  String get mvEntryTitle => 'Transformar em vídeo';

  @override
  String get mvEntrySubtitle =>
      'Vídeos com letra, do refrão e completos, com créditos';

  @override
  String get mvEntryDisabled => 'Disponível quando a música estiver pronta';

  @override
  String get mvEntryChoose => 'Escolher um vídeo';

  @override
  String get mvEntryWatch => 'Assistir ao vídeo';

  @override
  String get mvChipReady => 'Vídeo';

  @override
  String get mvChipMaking => 'Fazendo o vídeo';

  @override
  String get lengthAutoVideo => 'Fazer também um vídeo com letra';

  @override
  String get lengthAutoVideoHint =>
      'Pronto alguns minutos depois da música · usa créditos';

  @override
  String get lengthSongAndChorus => 'Música + vídeo do refrão';

  @override
  String get lengthSongAndChorusHint =>
      'A música completa e depois um vídeo do refrão de 30 segundos';

  @override
  String get paywallVideoGroup => 'Videoclipes';

  @override
  String get planVideoIncluded => 'Sua cota também faz videoclipes';

  @override
  String get settingsVideoCredits => 'Créditos de vídeo';

  @override
  String get createGenrePop => 'Pop';

  @override
  String get createGenreHipHopRap => 'Hip-hop e rap';

  @override
  String get createGenreRock => 'Rock';

  @override
  String get createGenreKPop => 'K-pop';

  @override
  String get createGenreLatin => 'Latina';

  @override
  String get createGenreElectronic => 'Eletrônica';

  @override
  String get createGenreRnb => 'R&B';

  @override
  String get createGenreCountry => 'Country';

  @override
  String get createGenreAfrobeats => 'Afrobeats';

  @override
  String get createGenreReggae => 'Reggae';

  @override
  String get createGenreJazzBlues => 'Jazz e blues';

  @override
  String get createGenreClassical => 'Clássica';

  @override
  String get createGenreFolk => 'Folk';

  @override
  String get createGenreLofi => 'Lo-fi';

  @override
  String get createGenreAcoustic => 'Acústica';

  @override
  String get createGenreCinematic => 'Trilha de cinema';

  @override
  String get createGenreAmbient => 'Ambient';

  @override
  String get createGenreBossaNova => 'Bossa nova';

  @override
  String get createGenreIndiePop => 'Pop indie';

  @override
  String get createGenreContemporaryRnb => 'R&B contemporâneo';

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
  String get createGenreFrenchYeyePop => 'Yé-yé francês dos anos 60';

  @override
  String get createGenreChillout => 'Chill-out';

  @override
  String get createGenreJPopIndiePop => 'J-pop indie';

  @override
  String get createGenreChiptune => 'Chiptune';

  @override
  String get createGenreDiscoFunk => 'Disco-funk';

  @override
  String get createGenreReggaeton => 'Reggaeton';

  @override
  String get createGenreCumbia => 'Cumbia';

  @override
  String get createGenreLatinJazz => 'Jazz latino';

  @override
  String get createGenreBhangra => 'Bhangra';

  @override
  String get createGenreIndianClassical => 'Clássica indiana';

  @override
  String get createGenreLofiHipHop => 'Hip-hop lo-fi';

  @override
  String profileAccountIdWithValue(String id) {
    return 'ID da conta: $id';
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
  String get createVocalsCustomSummary => 'Automático — conforme sua descrição';

  @override
  String mvChipMakingWithProgress(String progress) {
    return 'Fazendo o vídeo · $progress';
  }

  @override
  String mvAutoFailureMessage(String reason) {
    return 'O vídeo não pôde começar · $reason';
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
  String get inspirationHeader => 'Inspiração';

  @override
  String inspirationPlay(String name) {
    return 'Tocar $name';
  }

  @override
  String get inspirationStop => 'Parar a prévia';

  @override
  String get inspirationNameSoundscape => 'Paisagem sonora';

  @override
  String get inspirationStyleSoundscape => 'Texturas ambientes, sem voz';

  @override
  String get inspirationNameBackgroundMusic => 'Música de fundo';

  @override
  String get inspirationStyleBackgroundMusic => 'Instrumental leve para vídeos';

  @override
  String get inspirationNameMemorizeSomething => 'Para memorizar';

  @override
  String get inspirationStyleMemorizeSomething => 'Pop grudento para memorizar';

  @override
  String get inspirationNameTextMessages => 'Mensagens viram música';

  @override
  String get inspirationStyleTextMessages =>
      'Pop divertido com as suas mensagens';

  @override
  String get inspirationNameIntroMusic => 'Música de abertura';

  @override
  String get inspirationStyleIntroMusic => 'Abertura cinematográfica marcante';

  @override
  String get inspirationNameMontage => 'Montagem';

  @override
  String get inspirationStyleMontage =>
      'Crescendo animado para melhores momentos';

  @override
  String get inspirationNameSayItWithATrack => 'Diga com uma música';

  @override
  String get inspirationStyleSayItWithATrack => 'Balada pop emocionante';

  @override
  String get inspirationNameBrandJingle => 'Jingle de marca';

  @override
  String get inspirationStyleBrandJingle =>
      'Refrão curto, brilhante e marcante';

  @override
  String get inspirationNameRingtone => 'Toque de celular';

  @override
  String get inspirationStyleRingtone => 'Trecho de 30 segundos em loop';

  @override
  String get inspirationNameStreaming => 'Streaming';

  @override
  String get inspirationStyleStreaming =>
      'Abertura eletrônica animada para lives';

  @override
  String get inspirationNameSpeechToTrack => 'Da voz para a música';

  @override
  String get inspirationStyleSpeechToTrack => 'A sua voz virando música';

  @override
  String get inspirationNameRapBattle => 'Batalha de rap';

  @override
  String get inspirationStyleRapBattle => 'Hip-hop pesado';

  @override
  String get inspirationNameComedy => 'Humor';

  @override
  String get inspirationStyleComedy => 'Diferente, animado e irônico';

  @override
  String get inspirationNameTeamAnthem => 'Hino do time';

  @override
  String get inspirationStyleTeamAnthem => 'Grito de guerra de rock de estádio';

  @override
  String get inspirationNameSportsRecap => 'Resumo do jogo';

  @override
  String get inspirationStyleSportsRecap =>
      'Melhores momentos orquestrais épicos';

  @override
  String get inspirationNamePartyInvite => 'Convite para a festa';

  @override
  String get inspirationStylePartyInvite => 'Convite dance-pop';

  @override
  String get inspirationNameHappyBirthday => 'Feliz aniversário';

  @override
  String get inspirationStyleHappyBirthday =>
      'Música de aniversário acústica e calorosa';

  @override
  String get inspirationNameFriendAppreciation => 'Valeu, amigos';

  @override
  String get inspirationStyleFriendAppreciation =>
      'Indie pop de bem com a vida';

  @override
  String get inspirationNameLoveStory => 'História de amor';

  @override
  String get inspirationStyleLoveStory => 'Balada romântica de R&B';

  @override
  String get inspirationNameBirthdayRoast => 'Aniversário zoeira';

  @override
  String get inspirationStyleBirthdayRoast =>
      'Música de aniversário engraçadinha';

  @override
  String get inspirationNameOdeToYourPet => 'Ode ao seu pet';

  @override
  String get inspirationStyleOdeToYourPet => 'Pop fofo e saltitante';

  @override
  String get inspirationNameHometownTribute => 'Homenagem à sua cidade';

  @override
  String get inspirationStyleHometownTribute => 'Folk nostálgico';

  @override
  String get inspirationNameWeatherReport => 'Previsão do tempo';

  @override
  String get inspirationStyleWeatherReport => 'Groove lounge descontraído';

  @override
  String get inspirationNameBusinessPromo => 'Divulgação do seu negócio';

  @override
  String get inspirationStyleBusinessPromo => 'Pop corporativo confiante';

  @override
  String get inspirationStyleBirthdayWish =>
      'Canção sincera para o dia especial';

  @override
  String get inspirationStyleBirthdayParty =>
      'Hino de festa animado para o aniversariante';

  @override
  String get inspirationStyleThankAFriend =>
      'Canção de agradecimento calorosa e sincera';

  @override
  String get inspirationStyleWedding =>
      'Canção alegre e romântica para o grande dia';

  @override
  String get inspirationStyleInMemory => 'Homenagem suave e esperançosa';

  @override
  String get inspirationStyleFestival =>
      'Saudação festiva e brilhante da estação';

  @override
  String get inspirationStylePetAnthem =>
      'Tema carinhoso e animado para o seu pet';

  @override
  String get inspirationStyleHometown =>
      'Hino orgulhoso e nostálgico à sua cidade';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsSectionProfile => 'Perfil';

  @override
  String get settingsCredits => 'Créditos';

  @override
  String get settingsAccountId => 'ID da conta';

  @override
  String get settingsCopyAccountId => 'Copiar ID da conta';

  @override
  String get devSectionTitle => 'Desenvolvedor (só DEV)';

  @override
  String get devKeychainReset => 'Apagar chaves do Keychain';

  @override
  String get devKeychainResetHint => 'ID do dispositivo e tokens de sessão';

  @override
  String get devKeychainResetConfirmTitle => 'Apagar chaves do Keychain?';

  @override
  String get devKeychainResetConfirmBody =>
      'O ID do dispositivo e os tokens de sessão são apagados do Keychain. A conta de convidado atual não pode ser recuperada; o app entra como um novo convidado.';

  @override
  String get devKeychainResetDone =>
      'Chaves apagadas — conectado como novo convidado';

  @override
  String get settingsAppLanguage => 'Idioma do app';

  @override
  String get settingsLanguageSystem => 'Usar idioma do sistema';

  @override
  String settingsLanguageSystemValue(String language) {
    return 'Sistema ($language)';
  }

  @override
  String get settingsLanguageNativeName => 'Português (Brasil)';

  @override
  String get settingsLanguageSaveFailed =>
      'Não foi possível salvar o idioma. Tente de novo.';

  @override
  String get settingsLyricsLanguageHint => 'Vale para novas músicas.';

  @override
  String composerRemoveInspiration(String name) {
    return 'Remover $name';
  }

  @override
  String get composerPromptHint =>
      'Descreva a música ou escolha uma ideia acima';

  @override
  String get composerPromptHintWide => 'Descreva a música ou escolha uma ideia';

  @override
  String get composerWordsLabel => 'Suas palavras';

  @override
  String composerPhotosAttached(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fotos adicionadas',
      one: '$countString foto adicionada',
    );
    return '$_temp0';
  }

  @override
  String composerOptionsSummary(String summary) {
    return 'Opções da música: $summary';
  }

  @override
  String get composerOptionsShow => 'Mostrar opções';

  @override
  String get composerOptionsHide => 'Ocultar opções';

  @override
  String get composerSummaryAnyVocals => 'Qualquer vocal';

  @override
  String get composerSummaryAnyGenre => 'Qualquer gênero';

  @override
  String get composerSummaryLyrics => 'Letra própria';

  @override
  String get composerSummaryVideo => 'Vídeo com letra';

  @override
  String createPreviewLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Criar prévia · grátis',
      'preview': 'Criar prévia · 1 prévia',
      'other': 'Criar prévia',
    });
    return '$_temp0';
  }

  @override
  String createPreviewForLabel(String name, String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'free': 'Criar a prévia de $name · grátis',
      'preview': 'Criar a prévia de $name · 1 prévia',
      'other': 'Criar a prévia de $name',
    });
    return '$_temp0';
  }

  @override
  String createFullSongLabel(String cost) {
    String _temp0 = intl.Intl.selectLogic(cost, {
      'song': 'Criar música completa · 1 música',
      'other': 'Criar música completa',
    });
    return '$_temp0';
  }

  @override
  String get voiceUseText => 'Usar este texto';

  @override
  String mvAutoCountdown(String level, int seconds) {
    return '$level começa em $seconds s';
  }

  @override
  String planPerWeek(String price) {
    return '$price/semana';
  }

  @override
  String get planCreditsWeekly => 'Novos créditos toda semana';

  @override
  String paywallIntroOffer(int percent, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'no primeiro dia',
      'week': 'na primeira semana',
      'month': 'no primeiro mês',
      'year': 'no primeiro ano',
      'other': 'no primeiro período',
    });
    return '$percent% de desconto $_temp0';
  }

  @override
  String paywallIntroDisclosure(String introPrice, String pricePerPeriod) {
    return 'Após o preço promocional de $introPrice, você será cobrado $pricePerPeriod automaticamente. Cancele quando quiser antes da renovação.';
  }

  @override
  String get storePreviewAHook => 'Comece pelo nome';

  @override
  String get storePreviewAWords => 'Três palavras sobre a pessoa';

  @override
  String get storePreviewAWait => 'Sua música está sendo criada';

  @override
  String get storePreviewAChorus => 'O nome no refrão';

  @override
  String get storePreviewAEnd => 'Uma música com esse nome';

  @override
  String get storePreviewBHook => 'Comece pelas suas fotos';

  @override
  String get storePreviewBVideo => 'Inclua um vídeo com letra';

  @override
  String get storePreviewBWait => 'Criando sua música';

  @override
  String get storePreviewBLyrics => 'Letra sincronizada na tela';

  @override
  String get storePreviewBMood => 'Suas fotos criam o clima.';

  @override
  String get storePreviewBShare => 'Compartilhe o vídeo.';

  @override
  String get storePreviewBLanguage => 'Letras no seu idioma';

  @override
  String get storePreviewAShare => 'Envie como cartão';

  @override
  String get storePreviewCta => 'Crie sua primeira música';

  @override
  String get storePreviewDisclosure => 'Requer assinatura ou créditos';

  @override
  String get storeCreativeHeader => 'Músicas para quem você ama';

  @override
  String get storeCreativeSearch => 'Um nome vira uma música';

  @override
  String get storeCreativeBirthday => 'Uma música de aniversário com o nome';

  @override
  String get storeCreativePhoto => 'Suas fotos viram uma música';

  @override
  String get storeCreativeWedding => 'Uma música para o seu casamento';
}
