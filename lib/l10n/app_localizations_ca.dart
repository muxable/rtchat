// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get sendAMessage => 'Envia un missatge...';

  @override
  String get writeSomething => 'Escriu alguna cosa...';

  @override
  String get speakToTheCrowds => 'Parla a la multitud...';

  @override
  String get shareYourThoughts => 'Comparteix el que penses...';

  @override
  String get saySomethingYouLittleBitch => 'Digues alguna cosa, covard...';

  @override
  String get search => 'Cerca';

  @override
  String get notSignedIn => 'Sessió no iniciada';

  @override
  String get searchChannels => 'Cerca';

  @override
  String get raidAChannel => 'Fes un raid';

  @override
  String get noMessagesEmptyState => 'Aquí hi ha molta calma.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missatges nous',
      one: '1 missatge nou',
      zero: 'Cap missatge nou',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Inicia la sessió amb Twitch';

  @override
  String get signInError =>
      'S\'ha produït un error en iniciar la sessió. Torna-ho a provar.';

  @override
  String get continueAsGuest => 'Continua com a convidat';

  @override
  String get signInToSendMessages => 'Inicia la sessió per enviar missatges';

  @override
  String get currentViewers => 'Espectadors actuals';

  @override
  String get textToSpeech => 'Text a veu';

  @override
  String get streamPreview => 'Previsualització del directe';

  @override
  String get activityFeed => 'Canal d\'activitat';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Directe en línia el $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Directe fora de línia el $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Xat esborrat el $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Configura els enllaços ràpids';

  @override
  String get disableRainMode => 'Desactiva el mode pluja';

  @override
  String get enableRainMode => 'Activa el mode pluja';

  @override
  String get disableRainModeSubtitle => 'S\'activarà la interacció';

  @override
  String get enableRainModeSubtitle => 'Es desactivarà la interacció';

  @override
  String get refreshAudioSources => 'Actualitza les fonts d\'àudio';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S\'han actualitzat $count fonts d\'àudio',
      one: 'S\'ha actualitzat 1 font d\'àudio',
      zero: 'No s\'ha actualitzat cap font d\'àudio',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Configuració';

  @override
  String get signOut => 'Tanca la sessió';

  @override
  String get cancel => 'Cancel·la';

  @override
  String get signOutConfirmation => 'Segur que vols tancar la sessió?';

  @override
  String get broadcaster => 'Emissor';

  @override
  String get moderators => 'Moderadors';

  @override
  String get viewers => 'Espectadors';

  @override
  String get communityVips => 'VIP de la comunitat';

  @override
  String get searchViewers => 'Cerca espectadors';

  @override
  String get reconnecting => 'S\'està tornant a connectar...';

  @override
  String get twitchBadges => 'Insígnies de Twitch';

  @override
  String get selectAll => 'Selecciona-ho tot';

  @override
  String get quickLinks => 'Enllaços ràpids';

  @override
  String get swipeToDeleteQuickLinks =>
      'Llisca cap a l\'esquerra o cap a la dreta per suprimir l\'enllaç ràpid';

  @override
  String get quickLinksLabelHint => 'Etiqueta';

  @override
  String get invalidUrlErrorText => 'No sembla un URL vàlid';

  @override
  String get duplicateUrlErrorText => 'Aquest enllaç ja existeix';

  @override
  String get or => 'o';

  @override
  String get clearCookies => 'Esborra les galetes';

  @override
  String get disabled => 'Desactivat';

  @override
  String get twitchActivityFeed => 'Canal d\'activitat de Twitch';

  @override
  String get signInToEnable =>
      'Has d\'iniciar la sessió per activar aquesta opció';

  @override
  String get customUrl => 'URL personalitzat';

  @override
  String get preview => 'Previsualització';

  @override
  String get audioSources => 'Fonts d\'àudio';

  @override
  String get enableOffStreamSwitchTitle =>
      'Activa fora de directe (consumeix més bateria)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'L\'àudio també es reproduirà quan no estiguis en directe';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'L\'àudio només es reproduirà quan estiguis en directe';

  @override
  String get iosOggWarningTitle => 'Ei! Escolta!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS no admet fitxers multimèdia *.ogg, que són els fitxers predeterminats a Streamlabs. Assegura\'t que les teves fonts d\'àudio utilitzin un altre format; altrament, no es reproduiran.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Personalitza el teu canal d\'activitat';

  @override
  String get audioSourcesSubtitle => 'Afegeix fonts web per als sons d\'alerta';

  @override
  String get quickLinksSubtitle =>
      'Afegeix dreceres a les eines més utilitzades';

  @override
  String get chatHistory => 'Historial del xat';

  @override
  String get chatHistorySubtitle => 'Canvia l\'aparença del xat';

  @override
  String get textToSpeechSubtitle => 'Canvia la configuració de text a veu';

  @override
  String get events => 'Esdeveniments';

  @override
  String get eventsSubtitle => 'Configura els esdeveniments de Twitch';

  @override
  String get thirdPartyServices => 'Serveis de tercers';

  @override
  String get thirdPartyServicesSubtitle => 'Connecta\'t a un servei de tercers';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> et segueix';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> i <b>$displayNameTwo</b> et segueixen';
  }

  @override
  String followingEvent3(
    String displayName,
    String displayNameTwo,
    int numOthers,
  ) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b> i $numOthersString més et segueixen';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Activa el so de $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Silencia $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Expulsa temporalment $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Prohibeix l\'accés a $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Aixeca la prohibició a $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Mostra el perfil de $displayName';
  }

  @override
  String get copyMessage => 'Copia el missatge';

  @override
  String get deleteMessage => 'Suprimeix el missatge';

  @override
  String get longScrollNotification =>
      'Estàs desplaçant-te molt amunt, no trobes?';

  @override
  String get stfu => 'calla';

  @override
  String get globalEmotes => 'Emoticones globals';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString seguidors',
      one: '1 seguidor',
      zero: '0 seguidors',
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
      other: '$countString espectadors',
      one: '1 espectador',
      zero: '0 espectadors',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Hola! Ens alegra que t\'agradi fer servir la previsualització del directe, però tingues en compte que consumeix molta bateria. Llegir el xat sense activar-la allargarà la durada de la bateria.';

  @override
  String get okay => 'D\'acord';

  @override
  String get streamPreviewLoading =>
      'S\'està carregant (o el directe està fora de línia)...';

  @override
  String get copiedToClipboard => 'S\'ha copiat al porta-retalls';

  @override
  String get audioSourcesRequirePermissions =>
      'Les fonts d\'àudio requereixen permisos';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Autoritza RealtimeChat a mostrar-se per sobre d\'altres aplicacions per utilitzar les fonts d\'àudio.';

  @override
  String get audioSourcesRemoveButton => 'Elimina les fonts d\'àudio';

  @override
  String get audioSourcesOpenSettingsButton => 'Obre la configuració';

  @override
  String get flashOn => 'Flaix activat';

  @override
  String get flashOff => 'Flaix desactivat';

  @override
  String get durationOneSecond => '1 segon';

  @override
  String get durationOneMinute => '1 minut';

  @override
  String get durationTenMinutes => '10 minuts';

  @override
  String get durationOneHour => '1 hora';

  @override
  String get durationSixHours => '6 hores';

  @override
  String get durationOneDay => '1 dia';

  @override
  String get durationTwoDays => '2 dies';

  @override
  String get durationOneWeek => '1 setmana';

  @override
  String get durationTwoWeeks => '2 setmanes';

  @override
  String get durationOneSecondTimeoutPrompt =>
      'Expulsa temporalment durant 1 segon';

  @override
  String get durationOneMinuteTimeoutPrompt =>
      'Expulsa temporalment durant 1 minut';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      'Expulsa temporalment durant 10 minuts';

  @override
  String get durationOneHourTimeoutPrompt =>
      'Expulsa temporalment durant 1 hora';

  @override
  String get durationSixHoursTimeoutPrompt =>
      'Expulsa temporalment durant 6 hores';

  @override
  String get durationOneDayTimeoutPrompt => 'Expulsa temporalment durant 1 dia';

  @override
  String get durationTwoDaysTimeoutPrompt =>
      'Expulsa temporalment durant 2 dies';

  @override
  String get durationOneWeekTimeoutPrompt =>
      'Expulsa temporalment durant 1 setmana';

  @override
  String get durationTwoWeeksTimeoutPrompt =>
      'Expulsa temporalment durant 2 setmanes';

  @override
  String get errorFetchingViewerList =>
      'No hem pogut obtenir la llista d\'espectadors d\'aquest canal';

  @override
  String get eventsTitle => 'Esdeveniments';

  @override
  String get followEventConfigTitle => 'Esdeveniment de seguiment';

  @override
  String get customizeYourFollowEvent =>
      'Personalitza l\'esdeveniment de seguiment';

  @override
  String get subscribeEventConfigTitle => 'Esdeveniment de subscripció';

  @override
  String get customizeYourSubscriptionEvent =>
      'Personalitza l\'esdeveniment de subscripció';

  @override
  String get cheerEventConfigTitle => 'Esdeveniment de Cheer';

  @override
  String get customizeYourCheerEvent => 'Personalitza l\'esdeveniment de Cheer';

  @override
  String get raidEventConfigTitle => 'Esdeveniment de raid';

  @override
  String get customizeYourRaidEvent => 'Personalitza l\'esdeveniment de raid';

  @override
  String get hostEventConfigTitle => 'Esdeveniment d\'allotjament';

  @override
  String get customizeYourHostEvent =>
      'Personalitza l\'esdeveniment d\'allotjament';

  @override
  String get hypetrainEventConfigTitle => 'Esdeveniment de Tren de l\'Hype';

  @override
  String get customizeYourHypetrainEvent =>
      'Personalitza l\'esdeveniment de Tren de l\'Hype';

  @override
  String get pollEventConfigTitle => 'Esdeveniment d\'enquesta';

  @override
  String get customizeYourPollEvent =>
      'Personalitza l\'esdeveniment d\'enquesta';

  @override
  String get predictionEventConfigTitle => 'Esdeveniment de predicció';

  @override
  String get customizeYourPredictionEvent =>
      'Personalitza l\'esdeveniment de predicció';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Esdeveniment de bescanvi de punts del canal';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Personalitza l\'esdeveniment de bescanvi de punts del canal';

  @override
  String get outgoingRaidEventConfigTitle => 'Esdeveniment de raid sortint';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Personalitza l\'esdeveniment de raid sortint';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> està fent un raid amb <b>$viewerCountString</b> espectadors!';
  }

  @override
  String get shoutout => 'Menció';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Fent un raid a <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString s';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> ha fet un raid!';
  }

  @override
  String get raidingEventJoin => 'Uneix-t\'hi';

  @override
  String raidingEventCanceled(String displayName) {
    return 'S\'ha cancel·lat el raid de <b>$displayName</b>.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> s\'ha subscrit al nivell $tier!';
  }

  @override
  String subscriptionGiftEvent(
    String gifterUserName,
    int total,
    String tier,
    int cumulativeTotal,
  ) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat cumulativeTotalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeTotalString = cumulativeTotalNumberFormat.format(
      cumulativeTotal,
    );

    return '<b>$gifterUserName</b> ha regalat $totalString subscripcions de nivell $tier, amb un total de $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
    String subscriberUserName,
    int cumulativeMonths,
    String tier,
  ) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString = cumulativeMonthsNumberFormat.format(
      cumulativeMonths,
    );

    return '<b>$subscriberUserName</b> s\'ha subscrit durant $cumulativeMonthsString mesos al nivell $tier!';
  }

  @override
  String subscriptionMessageMultiMonthEvent(
    String subscriberUserName,
    String tier,
    int durationMonths,
    int cumulativeMonths,
  ) {
    final intl.NumberFormat durationMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String durationMonthsString = durationMonthsNumberFormat.format(
      durationMonths,
    );
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString = cumulativeMonthsNumberFormat.format(
      cumulativeMonths,
    );

    return '<b>$subscriberUserName</b> s\'ha subscrit al nivell $tier durant $durationMonthsString mesos per avançat, $cumulativeMonthsString mesos en total!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> ha donat una propina de <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anònim ha donat una propina de <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ha donat una propina de <b>$formattedAmount</b> a StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ha donat una propina de <b>$formattedAmount</b> a Streamlabs.';
  }

  @override
  String channelPointRedemptionWithUserInput(
    String redeemerUsername,
    String rewardName,
    int rewardCost,
    String userInput,
  ) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> ha bescanviat <b>$rewardName</b> per <b>$rewardCostString</b> punts. $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
    String redeemerUsername,
    String rewardName,
    int rewardCost,
  ) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> ha bescanviat <b>$rewardName</b> per <b>$rewardCostString</b> punts.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> ha enviat <b>$bitsString</b> bits. $cheerMessage';
  }

  @override
  String get anonymous => 'Anònim';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> està allotjant el canal amb un grup de <b>$viewersString</b>.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Tren de l\'Hype de nivell <b>$level</b> en curs! <b>$progressPercent%</b> completat!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'El Tren de l\'Hype de nivell <b>$levelString</b> s\'ha completat amb èxit.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'El Tren de l\'Hype de nivell <b>$levelString</b> ha fallat.';
  }

  @override
  String get sampleMessage =>
      'Aquest és un missatge de mostra per a la síntesi de veu.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author ha dit: $text';
  }

  @override
  String get textToSpeechEnabled => 'Text a veu activat';

  @override
  String get textToSpeechDisabled => 'Text a veu desactivat';

  @override
  String get alertsEnabled => 'Només alertes';

  @override
  String get pinDuration => 'Durada de la fixació';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds segons',
      one: '1 segon',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuts',
      one: '1 minut',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Activa l\'esdeveniment';

  @override
  String get showEventInChatHistory =>
      'Mostra l\'esdeveniment a l\'historial del xat';

  @override
  String get enableShoutouts => 'Activa les mencions';

  @override
  String get enableShoutoutsSubtitle =>
      'Envia un enllaç del canal que fa el raid al xat';

  @override
  String get raidConfigurationTitle => 'Configuració de raid';

  @override
  String get cheerConfigurationTitle => 'Configuració de Cheer';

  @override
  String get followConfigurationTitle => 'Configuració de seguiment';

  @override
  String get outgoingRaidConfigurationTitle => 'Configuració de raid sortint';

  @override
  String get hostConfigurationTitle => 'Configuració d\'allotjament';

  @override
  String get channelPointConfigurationTitle =>
      'Configuració de punts del canal';

  @override
  String get pollConfigurationTitle => 'Configuració d\'enquestes';

  @override
  String get hypetrainConfigurationTitle => 'Configuració del Tren de l\'Hype';

  @override
  String get subscriptionConfigurationTitle => 'Configuració de subscripcions';

  @override
  String get predictionConfigurationTitle => 'Configuració de prediccions';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Durada de fixació addicional per a recompenses pendents';

  @override
  String get pollPinDuration =>
      'Durada de la fixació un cop finalitzat el resultat';

  @override
  String get hypetrainPinDuration =>
      'Durada de la fixació un cop acabat el Tren de l\'Hype';

  @override
  String get enableGiftedSubscriptions =>
      'Activa les subscripcions regalades individuals';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Mostra cada subscripció que es regali';

  @override
  String get settingsBackupTitle =>
      'Còpia de seguretat i restauració de la configuració';

  @override
  String get cloudBackup => 'Còpia de seguretat al núvol';

  @override
  String get lastBackupNever => 'Última còpia de seguretat: mai';

  @override
  String get backUp => 'Fes una còpia de seguretat';

  @override
  String get restore => 'Restaura';

  @override
  String get localBackup => 'Còpia de seguretat local';

  @override
  String get exportSettings => 'Exporta';

  @override
  String get importSettings => 'Importa';

  @override
  String get showViewerAndFollowerCount =>
      'Mostra el nombre d\'espectadors i seguidors';

  @override
  String get screenOrientation => 'Orientació de la pantalla';

  @override
  String get appTheme => 'Tema de l\'aplicació';

  @override
  String get systemDefault => 'Sistema';

  @override
  String get portrait => 'Vertical';

  @override
  String get landscape => 'Horitzontal';

  @override
  String get lightTheme => 'Clar';

  @override
  String get darkTheme => 'Fosc';

  @override
  String get openSourceTitle => 'RealtimeChat és de codi obert';

  @override
  String get openSourceSubtitle => 'Troba\'ns a GitHub!';

  @override
  String get discordSubtitle => 'Uneix-te al Discord de Muxable!';

  @override
  String get earlyTestersThanks =>
      'Gràcies a tots els primers provadors que van enviar informes d\'errors!';

  @override
  String get discoModeEnabled => '🕺 Mode discoteca activat! :D';

  @override
  String get discoModeDisabled => '🕺 Mode discoteca desactivat D:';

  @override
  String get playSampleMessage => 'Reprodueix el missatge de mostra';

  @override
  String get textToSpeechRate => 'Velocitat de text a veu';

  @override
  String get textToSpeechPitch => 'To de text a veu';

  @override
  String get muteBots => 'Silencia el text a veu per als bots';

  @override
  String get muteEmotes => 'Silencia totes les emoticones en el text a veu';

  @override
  String get muteViewerNames =>
      'Silencia els noms dels espectadors en el text a veu';

  @override
  String get subscribersOnly => 'Només subscriptors';

  @override
  String get fontSize => 'Mida de la lletra';

  @override
  String get usernameContrastBoost => 'Augment del contrast del nom d\'usuari';

  @override
  String get twitchBadgeSettings => 'Configuració de les insígnies de Twitch';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Controla quines insígnies són visibles';

  @override
  String get showDeletedMessages => 'Mostra els missatges suprimits';

  @override
  String get deletedMessagesGreyedOut =>
      'Els missatges suprimits es mostraran en gris';

  @override
  String get deletedMessagesRemoved => 'Els missatges suprimits s\'eliminaran';

  @override
  String get showLoginNames => 'Mostra els noms d\'inici de sessió';

  @override
  String get loginNamesShown =>
      'Els noms d\'inici de sessió es mostraran si són diferents del nom visible';

  @override
  String get loginNamesHidden => 'Els noms d\'inici de sessió s\'ocultaran';

  @override
  String get compactMessages => 'Compacta els missatges';

  @override
  String get dontCompactMessages => 'No compactis els missatges';

  @override
  String get dontCompactMessagesSubtitle =>
      'Els missatges es mostren sense canvis';

  @override
  String get compactIndividualMessages => 'Compacta els missatges individuals';

  @override
  String get compactIndividualMessagesSubtitle =>
      'El text repetitiu dels missatges s\'escurça';

  @override
  String get announcementPinDuration => 'Durada de la fixació dels anuncis';

  @override
  String get idleMessageAlertDuration =>
      'Durada de l\'alerta d\'inactivitat de missatges';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Si no hi ha cap missatge durant aquest període de temps i n\'arriba un de nou, es reproduirà un so d\'alerta.';

  @override
  String get realtimeCashSubtitle => 'Connecta una cartera ETH o MATIC';

  @override
  String get walletAddress => 'Adreça de la cartera';

  @override
  String get streamlabsSubtitle => 'Consulta les teves donacions de Streamlabs';

  @override
  String get streamElementsSubtitle =>
      'Consulta les teves donacions de StreamElements';

  @override
  String get thirdPartyAuthError =>
      'Mmm, això no ha funcionat. Torna-ho a provar o pregunta-ho a Discord.';

  @override
  String get companionAuthBrowserTooOld =>
      'El teu navegador és massa antic per admetre l\'inici de sessió directe. Escaneja aquest codi QR amb el telèfon per iniciar la sessió en un altre dispositiu.';

  @override
  String get companionAuthScanQrCode =>
      'Escaneja aquest codi QR amb el telèfon per iniciar la sessió en un altre dispositiu.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> s\'ha subscrit!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> ha renovat la subscripció durant $monthsString mesos!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> ha regalat $countString subscripcions!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> ha enviat $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Inicia la sessió amb Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Hi ha massa missatges. S\'ha desactivat el text a veu';

  @override
  String get turnOffTextToSpeech => 'Desactiva';

  @override
  String get addToChat => 'Afegeix al xat';

  @override
  String get inChat => 'Al xat';

  @override
  String get removeFromChat => 'Elimina del xat';

  @override
  String cantChatWithAccount(String provider) {
    return 'El teu compte de $provider no pot xatejar aquí';
  }

  @override
  String get cantChatWithAccounts => 'Els teus comptes no poden xatejar aquí';

  @override
  String sendAMessageTo(String channel) {
    return 'Envia un missatge a $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Substitueix $channel';
  }

  @override
  String get voicePacks => 'Paquets de veu';

  @override
  String get voicePacksDescription =>
      'Els paquets de veu llegeixen el xat amb veus naturals que s\'executen al dispositiu, fora de línia un cop baixats. Les veus són generades automàticament per IA, no pas enregistrades per cap persona.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices veus',
      one: '1 veu',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count idiomes',
      one: '1 idioma',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'La llicència d\'aquest model (OpenRAIL-M) prohibeix usos perjudicials, com ara suplantar la identitat de persones o difondre desinformació, i aquestes restriccions també s\'apliquen a tu.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Vols suprimir $pack? S\'alliberaran $size.';
  }

  @override
  String get voicePackDownload => 'Baixa';

  @override
  String get voicePackUpdate => 'Actualitza';

  @override
  String get voicePackWaitingForWifi => 'S\'està esperant connexió Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Utilitza les dades mòbils';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'S\'està baixant: $downloaded de $total';
  }

  @override
  String get voicePackInstalling => 'S\'està instal·lant';

  @override
  String voicePackInstallFailed(String pack) {
    return 'No s\'ha pogut instal·lar $pack. Comprova la connexió i torna-ho a provar.';
  }

  @override
  String get voices => 'Veus';

  @override
  String get perViewerVoice => 'Veu per espectador';

  @override
  String get perViewerVoiceSubtitle =>
      'Cada espectador té la seva pròpia veu. La veu que triïs llegeix les alertes, o bé tot quan aquesta opció està desactivada.';

  @override
  String get streamLanguage => 'Idioma del directe';

  @override
  String get ttsEngineNeural => 'Veu neuronal (al dispositiu)';

  @override
  String get ttsEngineSystem => 'Veu del sistema';

  @override
  String languageUnsupported(String language) {
    return 'Els teus paquets de veu no admeten l\'idioma $language; s\'utilitzarà la veu del sistema';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Aquest dispositiu no té prou memòria per a les veus neuronals, de manera que el xat es llegeix amb la veu del sistema.';

  @override
  String get neuralFallbackLoadFailed =>
      'No s\'ha pogut carregar la veu neuronal, de manera que el xat es llegeix amb la veu del sistema.';

  @override
  String get accounts => 'Comptes';

  @override
  String get accountsSubtitle =>
      'Inicia la sessió a cada plataforma on facis directes';

  @override
  String addProviderAccount(String provider) {
    return 'Afegeix un compte de $provider';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Inicia la sessió amb $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Vols tancar la sessió de $channel a $provider?';
  }

  @override
  String get signOutOfAll => 'Tanca la sessió de tots els comptes';
}
