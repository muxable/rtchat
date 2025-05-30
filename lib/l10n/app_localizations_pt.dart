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
  String get quickLinksLabelHint => 'Label';

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
    return 'Timeout $displayName';
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
  String get okay => 'Okay';

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
  String get alertsEnabled => 'Alerts only';
}
