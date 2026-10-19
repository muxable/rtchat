// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get sendAMessage => 'Enviar uma mensagem...';

  @override
  String get writeSomething => 'Escreva algo...';

  @override
  String get speakToTheCrowds => 'Fale para a multidão...';

  @override
  String get shareYourThoughts => 'Compartilhe seus pensamentos...';

  @override
  String get saySomethingYouLittleBitch => 'Diga alguma coisa, sua putinha...';

  @override
  String get search => 'Buscar';

  @override
  String get notSignedIn => 'Não conectado';

  @override
  String get searchChannels => 'Buscar';

  @override
  String get raidAChannel => 'Raid';

  @override
  String get noMessagesEmptyState => 'Está quieto aqui.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count novas mensagens',
      one: '1 nova mensagem',
      zero: 'Sem novas mensagens',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Faça login com a Twitch';

  @override
  String get signInError => 'Ocorreu um erro ao fazer login. Tente novamente.';

  @override
  String get continueAsGuest => 'Continuar como convidado';

  @override
  String get signInToSendMessages => 'Faça login para enviar mensagens';

  @override
  String get currentViewers => 'Espectadores atuais';

  @override
  String get textToSpeech => 'Texto para fala';

  @override
  String get streamPreview => 'Visualizar Stream';

  @override
  String get activityFeed => 'Feed de atividade';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream online desde $dateString às $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream offline desde $dateString às $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Chat limpo em $dateString às $timeString';
  }

  @override
  String get configureQuickLinks => 'Configurar links rápidos';

  @override
  String get disableRainMode => 'Desativar modo de chuva';

  @override
  String get enableRainMode => 'Ativar modo de chuva';

  @override
  String get disableRainModeSubtitle => 'A interação será ativada';

  @override
  String get enableRainModeSubtitle => 'A interação será desativada';

  @override
  String get refreshAudioSources => 'Atualizar fontes de áudio';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fontes de áudio atualizadas',
      one: '1 fonte de áudio atualizada',
      zero: 'Nenhuma fonte de áudio atualizada',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Configurações';

  @override
  String get signOut => 'Sair';

  @override
  String get cancel => 'Cancelar';

  @override
  String get signOutConfirmation => 'Você tem certeza que deseja sair?';

  @override
  String get broadcaster => 'Broadcaster';

  @override
  String get moderators => 'Moderadores';

  @override
  String get viewers => 'Espectadores';

  @override
  String get communityVips => 'VIPs';

  @override
  String get searchViewers => 'Procurar Espectadores';

  @override
  String get reconnecting => 'Reconectando...';

  @override
  String get twitchBadges => 'Badges da Twitch';

  @override
  String get selectAll => 'Selecionar todos';

  @override
  String get quickLinks => 'Links rápidos';

  @override
  String get swipeToDeleteQuickLinks =>
      'Deslize para a esquerda ou para a direita para excluir o link rápido';

  @override
  String get quickLinksLabelHint => 'Rótulo';

  @override
  String get invalidUrlErrorText => 'Isso não parece ser um URL válido';

  @override
  String get duplicateUrlErrorText => 'Este link já existe';

  @override
  String get or => 'ou';

  @override
  String get clearCookies => 'Limpar cookies';

  @override
  String get disabled => 'Desabilitado';

  @override
  String get twitchActivityFeed => 'Feed de atividade da Twitch';

  @override
  String get signInToEnable => 'Você deve estar logado para habilitar isso';

  @override
  String get customUrl => 'URL Customizada';

  @override
  String get preview => 'Visualizar';

  @override
  String get audioSources => 'Fontes de áudio';

  @override
  String get enableOffStreamSwitchTitle =>
      'Ativar off-stream (consome mais bateria)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'O áudio também será reproduzido quando você estiver offline';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'O áudio só será reproduzido quando você estiver ao vivo';

  @override
  String get iosOggWarningTitle => 'Ei! Ouvir!';

  @override
  String get iosOggWarningSubtitle =>
      'O iOS não oferece suporte a arquivos de mídia *.ogg, que são os arquivos padrão no Streamlabs. Certifique-se de que suas fontes de áudio usem outro formato, caso contrário, elas não serão reproduzidas.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Personalize seu feed de atividades';

  @override
  String get audioSourcesSubtitle =>
      'Adicionar fontes da web para sons de alerta';

  @override
  String get quickLinksSubtitle =>
      'Adicione atalhos para ferramentas comumente usadas';

  @override
  String get chatHistory => 'Histórico do Chat';

  @override
  String get chatHistorySubtitle => 'Alterar a aparência do bate-papo';

  @override
  String get textToSpeechSubtitle => 'Alterar configurações de text to speech';

  @override
  String get events => 'Eventos';

  @override
  String get eventsSubtitle => 'Configurar eventos do Twitch';

  @override
  String get thirdPartyServices => 'Serviços terceirizados';

  @override
  String get thirdPartyServicesSubtitle =>
      'Conecte-se a um serviço de terceiros';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> te seguiu';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> e <b>$displayNameTwo</b> te seguiu';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b>, e $numOthersString outras pessoas te seguiram';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Desmutar $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Mutar $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Suspender $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Banir $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Desbanir $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Ver o perfil de $displayName';
  }

  @override
  String get copyMessage => 'Copiar Mensagem';

  @override
  String get deleteMessage => 'Deletar Mensagem';

  @override
  String get longScrollNotification =>
      'Você está rolando meio longe, não acha?';

  @override
  String get stfu => 'cala a boca, porra';

  @override
  String get globalEmotes => 'Emotes Global';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString seguidores',
      one: '1 seguidor',
      zero: '0 seguidor',
    );
    return '$_temp0';
  }

  @override
  String viewerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString espectadores',
      one: '1 espectador',
      zero: '0 espectador',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Ei! Que bom que você gosta de usar a visualização de transmissão, mas atenção: ela consome muita bateria. A leitura do bate-papo sem ele prolongará a vida útil da bateria.';

  @override
  String get okay => 'OK';

  @override
  String get streamPreviewLoading => 'Carregando (ou a stream está offline)...';

  @override
  String get copiedToClipboard => 'Copiado';

  @override
  String get audioSourcesRequirePermissions =>
      'Fontes de áudio requerem permissões';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Aprove que o RealtimeChat se sobreponha a outros aplicativos para usar fontes de áudio.';

  @override
  String get audioSourcesRemoveButton => 'Remover fontes de áudio';

  @override
  String get audioSourcesOpenSettingsButton => 'Abrir confgiurações';

  @override
  String get flashOn => 'Flash ligado';

  @override
  String get flashOff => 'Flash desligado';

  @override
  String get durationOneSecond => '1 segundo';

  @override
  String get durationOneMinute => '1 minuto';

  @override
  String get durationTenMinutes => '10 minutos';

  @override
  String get durationOneHour => '1 hora';

  @override
  String get durationSixHours => '6 horas';

  @override
  String get durationOneDay => '1 dia';

  @override
  String get durationTwoDays => '2 dias';

  @override
  String get durationOneWeek => '1 semana';

  @override
  String get durationTwoWeeks => '2 semanas';

  @override
  String get durationOneSecondTimeoutPrompt => 'Timeout de 1 segundo';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Timeout de 1 minuto';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Timeout de 10 minutos';

  @override
  String get durationOneHourTimeoutPrompt => 'Timeout de 1 hora';

  @override
  String get durationSixHoursTimeoutPrompt => 'Timeout de 6 horas';

  @override
  String get durationOneDayTimeoutPrompt => 'Timeout de 1 dia';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Timeout de 2 dias';

  @override
  String get durationOneWeekTimeoutPrompt => 'Timeout de 1 semana';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Timeout de 2 semanas';

  @override
  String get errorFetchingViewerList =>
      'Não foi possível buscar a lista de espectadores para este canal';

  @override
  String get eventsTitle => 'Eventos';

  @override
  String get followEventConfigTitle => 'Evento de Seguir';

  @override
  String get customizeYourFollowEvent => 'Personalize seu evento de seguir';

  @override
  String get subscribeEventConfigTitle => 'Evento de Inscrição';

  @override
  String get customizeYourSubscriptionEvent =>
      'Personalize seu evento de inscrição';

  @override
  String get cheerEventConfigTitle => 'Evento de Torcida';

  @override
  String get customizeYourCheerEvent => 'Personalize seu evento de torcida';

  @override
  String get raidEventConfigTitle => 'Evento de Raid';

  @override
  String get customizeYourRaidEvent => 'Personalize seu evento de raid';

  @override
  String get hostEventConfigTitle => 'Evento de Host';

  @override
  String get customizeYourHostEvent => 'Personalize seu evento de host';

  @override
  String get hypetrainEventConfigTitle => 'Evento de Hype Train';

  @override
  String get customizeYourHypetrainEvent =>
      'Personalize seu evento de Hype Train';

  @override
  String get pollEventConfigTitle => 'Evento de Enquete';

  @override
  String get customizeYourPollEvent => 'Personalize seu evento de enquete';

  @override
  String get predictionEventConfigTitle => 'Evento de Previsão';

  @override
  String get customizeYourPredictionEvent =>
      'Personalize seu evento de previsão';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Evento de Resgate de Pontos do Canal';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Personalize seu evento de resgate de pontos do canal';

  @override
  String get outgoingRaidEventConfigTitle => 'Evento de Raid de Saída';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Personalize seu evento de raid de saída';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b> está fazendo raid com <b>$viewerCountString</b> espectadores!';
  }

  @override
  String get shoutout => 'Shoutout';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Fazendo raid em <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '${secondsString}s';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> fez raid!';
  }

  @override
  String get raidingEventJoin => 'Participar';

  @override
  String raidingEventCanceled(String displayName) {
    return 'O raid de <b>$displayName</b> foi cancelado.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> se inscreveu no Tier $tier!';
  }

  @override
  String subscriptionGiftEvent(
      String gifterUserName, int total, String tier, int cumulativeTotal) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat cumulativeTotalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeTotalString =
        cumulativeTotalNumberFormat.format(cumulativeTotal);

    return '<b>$gifterUserName</b> presenteou $totalString subs de Tier $tier, totalizando $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> está inscrito há $cumulativeMonthsString meses no Tier $tier!';
  }

  @override
  String subscriptionMessageMultiMonthEvent(String subscriberUserName,
      String tier, int durationMonths, int cumulativeMonths) {
    final intl.NumberFormat durationMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String durationMonthsString =
        durationMonthsNumberFormat.format(durationMonths);
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> se inscreveu no nível $tier por $durationMonthsString meses adiantados, $cumulativeMonthsString meses no total!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> deu uma gorjeta de <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anônimo deu uma gorjeta de <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> deu uma gorjeta de <b>$formattedAmount</b> no StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> deu uma gorjeta de <b>$formattedAmount</b> no Streamlabs.';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> resgatou <b>$rewardName</b> por <b>$rewardCostString</b> pontos. $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> resgatou <b>$rewardName</b> por <b>$rewardCostString</b> pontos.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> torceu <b>$bitsString</b> bits. $cheerMessage';
  }

  @override
  String get anonymous => 'Anônimo';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> está hospedando com um grupo de <b>$viewersString</b> espectadores.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train nível <b>$level</b> em andamento! <b>$progressPercent%</b> concluído!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train nível <b>$levelString</b> concluído com sucesso.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train nível <b>$levelString</b> falhou.';
  }

  @override
  String get sampleMessage =>
      'Este é um exemplo de mensagem de texto para voz.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author disse: $text';
  }

  @override
  String get textToSpeechEnabled => 'Texto para voz ativado';

  @override
  String get textToSpeechDisabled => 'Texto para voz desativado';

  @override
  String get alertsEnabled => 'Somente alertas';

  @override
  String get pinDuration => 'Duração fixada';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds segundos',
      one: '1 segundo',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Ativar evento';

  @override
  String get showEventInChatHistory => 'Mostrar o evento no histórico do chat';

  @override
  String get enableShoutouts => 'Ativar shoutouts';

  @override
  String get enableShoutoutsSubtitle =>
      'Enviar no chat um link para o canal que fez a raid';

  @override
  String get raidConfigurationTitle => 'Configurações de raid';

  @override
  String get cheerConfigurationTitle => 'Configurações de cheer';

  @override
  String get followConfigurationTitle => 'Configurações de follow';

  @override
  String get outgoingRaidConfigurationTitle => 'Configurações de raid de saída';

  @override
  String get hostConfigurationTitle => 'Configurações de host';

  @override
  String get channelPointConfigurationTitle =>
      'Configurações de pontos do canal';

  @override
  String get pollConfigurationTitle => 'Configurações de enquete';

  @override
  String get hypetrainConfigurationTitle => 'Configurações do Hype Train';

  @override
  String get subscriptionConfigurationTitle => 'Configurações de inscrição';

  @override
  String get predictionConfigurationTitle => 'Configurações de palpites';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Duração fixada extra para recompensas não atendidas';

  @override
  String get pollPinDuration => 'Duração fixada após o resultado final';

  @override
  String get hypetrainPinDuration => 'Duração fixada após o fim do Hype Train';

  @override
  String get enableGiftedSubscriptions =>
      'Ativar inscrições presenteadas individuais';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Mostrar cada inscrição presenteada';

  @override
  String get settingsBackupTitle => 'Backup e restauração de configurações';

  @override
  String get cloudBackup => 'Backup na nuvem';

  @override
  String get lastBackupNever => 'Último backup: nunca';

  @override
  String get backUp => 'Fazer backup';

  @override
  String get restore => 'Restaurar';

  @override
  String get localBackup => 'Backup local';

  @override
  String get exportSettings => 'Exportar';

  @override
  String get importSettings => 'Importar';

  @override
  String get showViewerAndFollowerCount =>
      'Mostrar contagem de espectadores e seguidores';

  @override
  String get screenOrientation => 'Orientação da tela';

  @override
  String get appTheme => 'Tema do app';

  @override
  String get systemDefault => 'Sistema';

  @override
  String get portrait => 'Retrato';

  @override
  String get landscape => 'Paisagem';

  @override
  String get lightTheme => 'Claro';

  @override
  String get darkTheme => 'Escuro';

  @override
  String get openSourceTitle => 'O RealtimeChat é de código aberto';

  @override
  String get openSourceSubtitle => 'Encontre-nos no GitHub!';

  @override
  String get discordSubtitle => 'Entre no Discord da Muxable!';

  @override
  String get earlyTestersThanks =>
      'Obrigado a todos os primeiros testadores que relataram bugs!';

  @override
  String get discoModeEnabled => '🕺 Modo disco ativado! :D';

  @override
  String get discoModeDisabled => '🕺 Modo disco desativado D:';

  @override
  String get playSampleMessage => 'Tocar mensagem de exemplo';

  @override
  String get textToSpeechRate => 'Velocidade da fala';

  @override
  String get textToSpeechPitch => 'Tom da fala';

  @override
  String get muteBots => 'Silenciar texto para fala de bots';

  @override
  String get muteEmotes => 'Silenciar todos os emotes no texto para fala';

  @override
  String get muteViewerNames =>
      'Silenciar nomes de espectadores no texto para fala';

  @override
  String get subscribersOnly => 'Somente inscritos';

  @override
  String get fontSize => 'Tamanho da fonte';

  @override
  String get usernameContrastBoost => 'Aumento de contraste dos nomes';

  @override
  String get twitchBadgeSettings => 'Configurações de emblemas da Twitch';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Escolha quais emblemas ficam visíveis';

  @override
  String get showDeletedMessages => 'Mostrar mensagens apagadas';

  @override
  String get deletedMessagesGreyedOut => 'Mensagens apagadas ficarão em cinza';

  @override
  String get deletedMessagesRemoved => 'Mensagens apagadas serão removidas';

  @override
  String get showLoginNames => 'Mostrar nomes de login';

  @override
  String get loginNamesShown =>
      'Os nomes de login serão mostrados se forem diferentes do nome de exibição';

  @override
  String get loginNamesHidden => 'Os nomes de login serão ocultados';

  @override
  String get compactMessages => 'Compactar mensagens';

  @override
  String get dontCompactMessages => 'Não compactar mensagens';

  @override
  String get dontCompactMessagesSubtitle =>
      'As mensagens são mostradas sem alterações';

  @override
  String get compactIndividualMessages => 'Compactar mensagens individuais';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Texto repetido nas mensagens é encurtado';

  @override
  String get announcementPinDuration => 'Duração fixada de anúncios';

  @override
  String get idleMessageAlertDuration => 'Alerta de chat inativo';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Se não houver mensagens por esse tempo e chegar uma nova, um som de alerta será tocado.';

  @override
  String get realtimeCashSubtitle => 'Conecte uma carteira ETH ou MATIC';

  @override
  String get walletAddress => 'Endereço da carteira';

  @override
  String get streamlabsSubtitle => 'Veja suas doações do Streamlabs';

  @override
  String get streamElementsSubtitle => 'Veja suas doações do StreamElements';

  @override
  String get thirdPartyAuthError =>
      'Hmm, não funcionou. Tente de novo ou pergunte no Discord?';

  @override
  String get companionAuthBrowserTooOld =>
      'Seu navegador é antigo demais para fazer login diretamente. Escaneie este código QR com o celular para fazer login em outro dispositivo.';

  @override
  String get companionAuthScanQrCode =>
      'Escaneie este código QR com o celular para fazer login em outro dispositivo.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> se inscreveu!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> renovou a inscrição por $monthsString meses!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> presenteou $countString inscrições!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> enviou $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Faça login com o Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Há mensagens demais. Texto para fala desativado';

  @override
  String get turnOffTextToSpeech => 'Desativar';

  @override
  String get addChannel => 'Adicionar canal';

  @override
  String get addToChat => 'Adicionar ao chat';

  @override
  String get defaultChannels => 'Canais padrão';

  @override
  String get defaultChannelsSubtitle => 'Os canais exibidos ao abrir o app';

  @override
  String get save => 'Salvar';

  @override
  String get resetToMyChannel => 'Redefinir para meu canal';

  @override
  String get inChat => 'No chat';

  @override
  String get removeFromChat => 'Remover do chat';

  @override
  String cantChatWithAccount(String provider) {
    return 'Sua conta da $provider não pode conversar aqui';
  }

  @override
  String replaceChannel(String channel) {
    return 'Substituir $channel';
  }

  @override
  String get removeChannel => 'Remover';

  @override
  String get voicePacks => 'Voice packs';

  @override
  String get voicePacksDescription =>
      'Voice packs read chat with natural-sounding voices that run on your device, offline once downloaded. The voices are machine-generated by AI, not recorded by a person.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices voices',
      one: '1 voice',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count languages',
      one: '1 language',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'This model\'s license (OpenRAIL-M) forbids harmful uses, such as impersonating people or spreading disinformation, and these restrictions apply to you too.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Delete $pack? This frees $size.';
  }

  @override
  String get voicePackDownload => 'Download';

  @override
  String get voicePackUpdate => 'Update';

  @override
  String get voicePackWaitingForWifi => 'Waiting for Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Use mobile data';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Downloading: $downloaded of $total';
  }

  @override
  String get voicePackInstalling => 'Installing';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Couldn\'t install $pack. Check your connection and try again.';
  }

  @override
  String get voices => 'Voices';

  @override
  String get perViewerVoice => 'Per-viewer voice';

  @override
  String get perViewerVoiceSubtitle =>
      'Each viewer gets their own voice. The voice you pick reads alerts, or everything when this is off.';

  @override
  String get streamLanguage => 'Stream language';

  @override
  String get ttsEngineNeural => 'Neural voice (on-device)';

  @override
  String get ttsEngineSystem => 'System voice';

  @override
  String languageUnsupported(String language) {
    return '$language isn\'t supported by your voice packs; the system voice will be used';
  }

  @override
  String get neuralFallbackLowMemory =>
      'This device doesn\'t have enough memory for neural voices, so chat is read with the system voice.';

  @override
  String get neuralFallbackLoadFailed =>
      'The neural voice couldn\'t load, so chat is read with the system voice.';

  @override
  String youtubeSuperChatEvent(String name, String amount) {
    return '<b>$name</b> enviou um Super Chat de $amount!';
  }

  @override
  String youtubeSuperStickerEvent(String name, String amount) {
    return '<b>$name</b> enviou um Super Sticker de $amount!';
  }

  @override
  String youtubeNewMemberEvent(String name) {
    return '<b>$name</b> virou membro!';
  }

  @override
  String youtubeMemberUpgradeEvent(String name, String level) {
    return '<b>$name</b> fez upgrade para $level!';
  }

  @override
  String youtubeMemberMilestoneEvent(String name, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$name</b> é membro há $monthsString meses!';
  }

  @override
  String youtubeMembershipGiftingEvent(String name, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '<b>$name</b> presenteou $countString assinaturas!',
      one: '<b>$name</b> presenteou uma assinatura!',
    );
    return '$_temp0';
  }

  @override
  String youtubeGiftMembershipReceivedEvent(String name) {
    return '<b>$name</b> recebeu uma assinatura de presente!';
  }

  @override
  String youtubeGiftEvent(
      String name, String giftName, int jewels, String amountKnown) {
    final intl.NumberFormat jewelsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String jewelsString = jewelsNumberFormat.format(jewels);

    String _temp0 = intl.Intl.selectLogic(
      amountKnown,
      {
        'known': ' ($jewelsString Jewels)',
        'other': '',
      },
    );
    return '<b>$name</b> enviou $giftName$_temp0!';
  }

  @override
  String youtubePollEvent(String question) {
    return 'Enquete: $question';
  }

  @override
  String get youtubeMembersOnlyModeOn =>
      'O modo somente para membros está ativado';

  @override
  String get youtubeMembersOnlyModeOff =>
      'O modo somente para membros está desativado';

  @override
  String get youtubeChatEnded => 'O chat ao vivo terminou';
}
