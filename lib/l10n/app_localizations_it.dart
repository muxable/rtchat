// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get sendAMessage => 'Invia un messaggio...';

  @override
  String get writeSomething => 'Scrivi qualcosa...';

  @override
  String get speakToTheCrowds => 'Parla alle folle...';

  @override
  String get shareYourThoughts => 'Condividi i tuoi pensieri...';

  @override
  String get saySomethingYouLittleBitch => 'Dì qualcosa, piccola stronza...';

  @override
  String get search => 'Cerca';

  @override
  String get notSignedIn => 'Non sei connesso';

  @override
  String get searchChannels => 'Cerca canali';

  @override
  String get raidAChannel => 'Raid un canale';

  @override
  String get noMessagesEmptyState => 'Non ci sono messaggi';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuovi messaggi',
      one: '1 nuovo messaggio',
      zero: 'Nessun nuovo messaggio',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Accedi con Twitch';

  @override
  String get signInError =>
      'Si è verificato un errore durante l\'accesso. Riprova.';

  @override
  String get continueAsGuest => 'Continua come ospite';

  @override
  String get signInToSendMessages => 'Accedi per inviare messaggi';

  @override
  String get currentViewers => 'Spettatori attuali';

  @override
  String get textToSpeech => 'Testo in voce';

  @override
  String get streamPreview => 'Anteprima del flusso';

  @override
  String get activityFeed => 'Feed delle attività';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Flusso online alle $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Flusso offline alle $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Chat cancellata alle $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Configura collegamenti rapidi';

  @override
  String get disableRainMode => 'Disabilita modalità pioggia';

  @override
  String get enableRainMode => 'Abilita modalità pioggia';

  @override
  String get disableRainModeSubtitle => 'L\'interazione sarà abilitata';

  @override
  String get enableRainModeSubtitle => 'L\'interazione sarà disabilitata';

  @override
  String get refreshAudioSources => 'Aggiorna sorgenti audio';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sorgenti audio aggiornate',
      one: '1 sorgente audio aggiornata',
      zero: 'Nessuna sorgente audio aggiornata',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Impostazioni';

  @override
  String get signOut => 'Disconnetti';

  @override
  String get cancel => 'Annulla';

  @override
  String get signOutConfirmation => 'Sei sicuro di voler disconnetterti?';

  @override
  String get broadcaster => 'Emittente';

  @override
  String get moderators => 'Moderatori';

  @override
  String get viewers => 'Spettatori';

  @override
  String get communityVips => 'VIP della comunità';

  @override
  String get searchViewers => 'Cerca spettatori';

  @override
  String get reconnecting => 'Riconnessione in corso...';

  @override
  String get twitchBadges => 'Badge di Twitch';

  @override
  String get selectAll => 'Seleziona tutto';

  @override
  String get quickLinks => 'Collegamenti rapidi';

  @override
  String get swipeToDeleteQuickLinks =>
      'Scorri a sinistra o a destra per eliminare il collegamento rapido';

  @override
  String get quickLinksLabelHint => 'Etichetta';

  @override
  String get invalidUrlErrorText => 'Questo non sembra un URL valido';

  @override
  String get duplicateUrlErrorText => 'Questo collegamento esiste già';

  @override
  String get or => 'o';

  @override
  String get clearCookies => 'Cancella cookie';

  @override
  String get disabled => 'Disabilitato';

  @override
  String get twitchActivityFeed => 'Feed delle attività di Twitch';

  @override
  String get signInToEnable =>
      'Devi essere connesso per abilitare questa funzione';

  @override
  String get customUrl => 'URL personalizzato';

  @override
  String get preview => 'Anteprima';

  @override
  String get audioSources => 'Sorgenti audio';

  @override
  String get enableOffStreamSwitchTitle =>
      'Abilita fuori dal flusso (consuma più batteria)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'L\'audio verrà riprodotto anche quando sei offline';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'L\'audio verrà riprodotto solo quando sei in diretta';

  @override
  String get iosOggWarningTitle => 'Ehi! Ascolta!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS non supporta i file multimediali *.ogg, che sono i file predefiniti su Streamlabs. Assicurati che le tue sorgenti audio utilizzino un altro formato, altrimenti non verranno riprodotte.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Personalizza il tuo feed delle attività';

  @override
  String get audioSourcesSubtitle =>
      'Aggiungi sorgenti web per i suoni di avviso';

  @override
  String get quickLinksSubtitle =>
      'Aggiungi scorciatoie agli strumenti più utilizzati';

  @override
  String get chatHistory => 'Cronologia chat';

  @override
  String get chatHistorySubtitle => 'Cambia l\'aspetto della chat';

  @override
  String get textToSpeechSubtitle => 'Cambia le impostazioni del testo in voce';

  @override
  String get events => 'Eventi';

  @override
  String get eventsSubtitle => 'Configura eventi di Twitch';

  @override
  String get thirdPartyServices => 'Servizi di terze parti';

  @override
  String get thirdPartyServicesSubtitle =>
      'Connettiti a un servizio di terze parti';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> ti sta seguendo';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> e <b>$displayNameTwo</b> ti stanno seguendo';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b> e altri $numOthersString ti stanno seguendo';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Riattiva audio di $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Disattiva audio di $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Timeout per $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Banna $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Rimuovi ban per $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Visualizza il profilo di $displayName';
  }

  @override
  String get copyMessage => 'Copia messaggio';

  @override
  String get deleteMessage => 'Elimina messaggio';

  @override
  String get longScrollNotification =>
      'Stai scorrendo un po\' troppo lontano, non credi?';

  @override
  String get stfu => 'stfu';

  @override
  String get globalEmotes => 'Emote globali';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString follower',
      one: '1 follower',
      zero: '0 follower',
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
      other: '$countString spettatori',
      one: '1 spettatore',
      zero: '0 spettatori',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Ciao! Siamo felici che ti piaccia usare l\'anteprima del flusso, ma attenzione, consuma molta batteria. Leggere la chat senza di essa prolungherà la durata della batteria.';

  @override
  String get okay => 'Ok';

  @override
  String get streamPreviewLoading =>
      'Caricamento in corso (o il flusso è offline)...';

  @override
  String get copiedToClipboard => 'Copiato negli appunti';

  @override
  String get audioSourcesRequirePermissions =>
      'Le sorgenti audio richiedono autorizzazioni';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Approva RealtimeChat per disegnare sopra altre app per utilizzare le sorgenti audio.';

  @override
  String get audioSourcesRemoveButton => 'Rimuovi sorgenti audio';

  @override
  String get audioSourcesOpenSettingsButton => 'Apri impostazioni';

  @override
  String get flashOn => 'Flash acceso';

  @override
  String get flashOff => 'Flash spento';

  @override
  String get durationOneSecond => '1 secondo';

  @override
  String get durationOneMinute => '1 minuto';

  @override
  String get durationTenMinutes => '10 minuti';

  @override
  String get durationOneHour => '1 ora';

  @override
  String get durationSixHours => '6 ore';

  @override
  String get durationOneDay => '1 giorno';

  @override
  String get durationTwoDays => '2 giorni';

  @override
  String get durationOneWeek => '1 settimana';

  @override
  String get durationTwoWeeks => '2 settimane';

  @override
  String get durationOneSecondTimeoutPrompt => 'Timeout per 1 secondo';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Timeout per 1 minuto';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Timeout per 10 minuti';

  @override
  String get durationOneHourTimeoutPrompt => 'Timeout per 1 ora';

  @override
  String get durationSixHoursTimeoutPrompt => 'Timeout per 6 ore';

  @override
  String get durationOneDayTimeoutPrompt => 'Timeout per 1 giorno';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Timeout per 2 giorni';

  @override
  String get durationOneWeekTimeoutPrompt => 'Timeout per 1 settimana';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Timeout per 2 settimane';

  @override
  String get errorFetchingViewerList =>
      'Non siamo riusciti a recuperare l\'elenco degli spettatori per questo canale';

  @override
  String get eventsTitle => 'Eventi';

  @override
  String get followEventConfigTitle => 'Evento di follow';

  @override
  String get customizeYourFollowEvent => 'Personalizza il tuo evento di follow';

  @override
  String get subscribeEventConfigTitle => 'Evento di abbonamento';

  @override
  String get customizeYourSubscriptionEvent =>
      'Personalizza il tuo evento di abbonamento';

  @override
  String get cheerEventConfigTitle => 'Evento di cheer';

  @override
  String get customizeYourCheerEvent => 'Personalizza il tuo evento di cheer';

  @override
  String get raidEventConfigTitle => 'Evento di raid';

  @override
  String get customizeYourRaidEvent => 'Personalizza il tuo evento di raid';

  @override
  String get hostEventConfigTitle => 'Evento di host';

  @override
  String get customizeYourHostEvent => 'Personalizza il tuo evento di host';

  @override
  String get hypetrainEventConfigTitle => 'Evento di Hype Train';

  @override
  String get customizeYourHypetrainEvent =>
      'Personalizza il tuo evento di Hype Train';

  @override
  String get pollEventConfigTitle => 'Evento di sondaggio';

  @override
  String get customizeYourPollEvent =>
      'Personalizza il tuo evento di sondaggio';

  @override
  String get predictionEventConfigTitle => 'Evento di previsione';

  @override
  String get customizeYourPredictionEvent =>
      'Personalizza il tuo evento di previsione';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Evento di riscatto punti canale';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Personalizza il tuo evento di riscatto punti canale';

  @override
  String get outgoingRaidEventConfigTitle => 'Evento di raid in uscita';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Personalizza il tuo evento di raid in uscita';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b> sta facendo un raid con <b>$viewerCountString</b> spettatori!';
  }

  @override
  String get shoutout => 'Shoutout';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Raid su <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Tempo rimanente $secondsString secondi';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> ha fatto un raid!';
  }

  @override
  String get raidingEventJoin => 'Unisciti';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Il raid di <b>$displayName</b> è stato annullato.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> si è abbonato al livello $tier!';
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

    return '<b>$gifterUserName</b> ha regalato $totalString abbonamenti di livello $tier, per un totale di $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> si è abbonato per $cumulativeMonthsString mesi al livello $tier!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> ha dato una mancia di <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonimo ha dato una mancia di <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ha dato una mancia di <b>$formattedAmount</b> su StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ha dato una mancia di <b>$formattedAmount</b> su Streamlabs.';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> ha riscattato <b>$rewardName</b> per <b>$rewardCostString</b> punti. $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> ha riscattato <b>$rewardName</b> per <b>$rewardCostString</b> punti.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> ha fatto il tifo con <b>$bitsString</b> bit. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonimo';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> sta ospitando con un gruppo di <b>$viewersString</b> spettatori.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train al livello <b>$level</b> in corso! Completato al <b>$progressPercent%</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train al livello <b>$levelString</b> completato con successo.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train al livello <b>$levelString</b> non completato con successo.';
  }

  @override
  String get sampleMessage =>
      'Questo è un messaggio di esempio per la sintesi vocale.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author detto: $text';
  }

  @override
  String get textToSpeechEnabled => 'Sintesi vocale abilitata';

  @override
  String get textToSpeechDisabled => 'Sintesi vocale disattivata';

  @override
  String get alertsEnabled => 'Alerts only';

  @override
  String get sidebarActions => 'Sidebar Actions';
}
