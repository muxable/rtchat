// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get sendAMessage => 'Nachricht senden...';

  @override
  String get writeSomething => 'Schreibe etwas...';

  @override
  String get speakToTheCrowds => 'Sprich zu den Massen...';

  @override
  String get shareYourThoughts => 'Teile deine Meinung...';

  @override
  String get saySomethingYouLittleBitch => 'Sag etwas, du kleine Hure...';

  @override
  String get search => 'Suche';

  @override
  String get notSignedIn => 'Nicht eingeloggt';

  @override
  String get searchChannels => 'Kanal suchen';

  @override
  String get raidAChannel => 'Kanal raiden';

  @override
  String get noMessagesEmptyState => 'keine Nachricht';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Nachrichten',
      one: '1 neue Nachricht',
      zero: 'Keine neuen Nachrichten',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Mit Twitch anmelden';

  @override
  String get signInError =>
      'Etwas ist mit der Anmeldung falsch gelaufen. Erneut versuchen';

  @override
  String get continueAsGuest => 'Als Gastnutzer fortsetzen';

  @override
  String get signInToSendMessages =>
      'Melden Sie sich an, um Nachrichten zu senden';

  @override
  String get currentViewers => 'aktuelle Zuschauer';

  @override
  String get textToSpeech => 'Text zu Sprache';

  @override
  String get streamPreview => 'Stream Vorschau';

  @override
  String get activityFeed => 'Aktivitäts-Feed';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream online um $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream offline um $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Chat gelöscht um $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Schnell-Links erstellen';

  @override
  String get disableRainMode => 'Regen-Modus deaktivieren';

  @override
  String get enableRainMode => 'Regen-Modus aktivieren';

  @override
  String get disableRainModeSubtitle => 'Regen-Modus Untertitel deaktivieren';

  @override
  String get enableRainModeSubtitle => 'Regen-Modus Untertitel aktivieren';

  @override
  String get refreshAudioSources => 'Audioquellen aktualisieren';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktualisierten Audioquellen',
      one: '1 aktualisierte Audioquelle ',
      zero: 'Keine aktualisierten Audioquellen',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Einstellungen';

  @override
  String get signOut => 'abmelden';

  @override
  String get cancel => 'absagen';

  @override
  String get signOutConfirmation =>
      'Sind Sie sicher, dass Sie sich abmelden wollen?';

  @override
  String get broadcaster => 'Streamer';

  @override
  String get moderators => 'Moderatoren';

  @override
  String get viewers => 'Zuschauer';

  @override
  String get communityVips => 'Gemeindschafts VIP';

  @override
  String get searchViewers => 'Zuschauer suchen';

  @override
  String get reconnecting => 'Verbindungs Wiederherstellung...';

  @override
  String get twitchBadges => 'Twitch-Abzeichen';

  @override
  String get selectAll => 'alles auswählen';

  @override
  String get quickLinks => 'Schnell-Links';

  @override
  String get swipeToDeleteQuickLinks =>
      'Wischen Sie um Schnell-Links zu löschen';

  @override
  String get quickLinksLabelHint => 'Name';

  @override
  String get invalidUrlErrorText => 'Dieser Link scheint ungültig zu sein.';

  @override
  String get duplicateUrlErrorText => 'Dieser Link existiert schon';

  @override
  String get or => 'oder';

  @override
  String get clearCookies => 'cookies löschen';

  @override
  String get disabled => 'deaktiviert';

  @override
  String get twitchActivityFeed => 'Twitch Aktivitäts-Feed';

  @override
  String get signInToEnable => 'Melden Sie sich an, um zu aktivieren';

  @override
  String get customUrl => 'persönliche URL';

  @override
  String get preview => 'Vorschau';

  @override
  String get audioSources => 'Audioquellen';

  @override
  String get enableOffStreamSwitchTitle =>
      'Offline aktivieren (benutzt mehr Batterie)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Audioabspielung finden auch offline statt';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Audioabspielung findet nur online statt';

  @override
  String get iosOggWarningTitle => 'Achtung, aufpassen!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS unterstütz das *.ogg Format nicht, welches automatisch von Streamlabs benutzt wird. Bitte benutzen Sie ein unterstüztes Format, damit die Alerts gespielt werden.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Aktivitäts-Feed personalisieren';

  @override
  String get audioSourcesSubtitle =>
      'Webseiten hinzufügen um Sound Alerts zu spielen';

  @override
  String get quickLinksSubtitle =>
      'Abkürzungen zu den gemeinsamen Werkzeugen hinzufügen';

  @override
  String get chatHistory => 'Chat-Ablauf';

  @override
  String get chatHistorySubtitle => 'Chat-Erscheinung ändern';

  @override
  String get textToSpeechSubtitle =>
      'Einstellungen zu Text zu Sprache wechseln';

  @override
  String get events => 'Events';

  @override
  String get eventsSubtitle => 'Twitch-Events einrichten';

  @override
  String get thirdPartyServices => 'Drittanbieter-Dienst';

  @override
  String get thirdPartyServicesSubtitle => 'Drittanbieter-Dienst verbinden';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> ist dir gefolgt';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> und <b>$displayNameTwo</b> sind dir gefolgt';
  }

  @override
  String followingEvent3(
    String displayName,
    String displayNameTwo,
    int numOthers,
  ) {
    final intl.NumberFormat numOthersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b>, und $numOthersString sind dir gefolgt';
  }

  @override
  String unmuteUser(String displayName) {
    return '$displayName Stummschaltung aufheben';
  }

  @override
  String muteUser(String displayName) {
    return '$displayName stumm schalten';
  }

  @override
  String timeoutUser(String displayName) {
    return '$displayName vorübergehend sperren ';
  }

  @override
  String banUser(String displayName) {
    return '$displayName sperren';
  }

  @override
  String unbanUser(String displayName) {
    return '$displayName entsperren';
  }

  @override
  String viewProfile(String displayName) {
    return '$displayName Profil anschauen';
  }

  @override
  String get copyMessage => 'Nachricht kopieren';

  @override
  String get deleteMessage => 'Nachricht löschen';

  @override
  String get longScrollNotification =>
      'Du scrollst ganz schön weit, findest du nicht?';

  @override
  String get stfu => 'stfu';

  @override
  String get globalEmotes => 'Globale Emotionen';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString anhänger',
      one: '1 anhänger',
      zero: '0 anhänger',
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
      other: '$countString zuschauer',
      one: '1 zuschauer',
      zero: '0 zuschauer',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Hallo zusammen! Schön, dass dir die Stream-Vorschau gefällt, aber Vorsicht: Sie verbraucht eine Menge Akku. Wenn du den Chat ohne sie liest, verlängert sich deine Akkulaufzeit.';

  @override
  String get okay => 'okay';

  @override
  String get streamPreviewLoading => 'Laden (oder der stream ist offline)...';

  @override
  String get copiedToClipboard => 'Kopiert in die zwischenablage';

  @override
  String get audioSourcesRequirePermissions =>
      'Audioquellen erfordern Berechtigungen';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Genehmigen Sie RealtimeChat, über andere Anwendungen zu ziehen, um Audioquellen zu nutzen.';

  @override
  String get audioSourcesRemoveButton => 'Audioquellen entfernen';

  @override
  String get audioSourcesOpenSettingsButton => 'Einstellungen öffnen';

  @override
  String get flashOn => 'Blitzlicht an';

  @override
  String get flashOff => 'Blitz aus';

  @override
  String get durationOneSecond => '1 sekunde';

  @override
  String get durationOneMinute => '1 Minute';

  @override
  String get durationTenMinutes => '10 minuten';

  @override
  String get durationOneHour => '1 stunde';

  @override
  String get durationSixHours => '6 stunden';

  @override
  String get durationOneDay => '1 tag';

  @override
  String get durationTwoDays => '2 tage';

  @override
  String get durationOneWeek => '1 woche';

  @override
  String get durationTwoWeeks => '2 wochen';

  @override
  String get durationOneSecondTimeoutPrompt => 'Timeout für 1 sekunde';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Timeout für 1 minute';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Timeout für 10 minuten';

  @override
  String get durationOneHourTimeoutPrompt => 'Timeout für 1 stunde';

  @override
  String get durationSixHoursTimeoutPrompt => 'Timeout für 6 stunden';

  @override
  String get durationOneDayTimeoutPrompt => 'Timeout für 1 tag';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Timeout für 2 tage';

  @override
  String get durationOneWeekTimeoutPrompt => 'Timeout für 1 woche';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Timeout für 2 wochen';

  @override
  String get errorFetchingViewerList =>
      'Wir konnten die Zuschauerliste für diesen Kanal nicht abrufen';

  @override
  String get eventsTitle => 'Veranstaltungen';

  @override
  String get followEventConfigTitle => 'Folgenereignis';

  @override
  String get customizeYourFollowEvent => 'Passen Sie Ihr Folgeereignis an';

  @override
  String get subscribeEventConfigTitle => 'Ereignis abonnieren';

  @override
  String get customizeYourSubscriptionEvent =>
      'Passen Sie Ihr Abonnementereignis an';

  @override
  String get cheerEventConfigTitle => 'Jubelereignis';

  @override
  String get customizeYourCheerEvent => 'Passen Sie Ihr Jubelereignis an';

  @override
  String get raidEventConfigTitle => 'Raid-Ereignis';

  @override
  String get customizeYourRaidEvent => 'Passen Sie Ihr Raid-Ereignis an';

  @override
  String get hostEventConfigTitle => 'Host-Ereignis';

  @override
  String get customizeYourHostEvent => 'Passen Sie Ihr Host-Ereignis an';

  @override
  String get hypetrainEventConfigTitle => 'Hype Train-Ereignis';

  @override
  String get customizeYourHypetrainEvent =>
      'Passen Sie Ihr Hype Train-Ereignis an';

  @override
  String get pollEventConfigTitle => 'Umfrage-Ereignis';

  @override
  String get customizeYourPollEvent => 'Passen Sie Ihr Umfrage-Ereignis an';

  @override
  String get predictionEventConfigTitle => 'Vorhersage-Ereignis';

  @override
  String get customizeYourPredictionEvent =>
      'Passen Sie Ihr Vorhersage-Ereignis an';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Kanalpunkt-Einlösung-Ereignis';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Passen Sie Ihr Kanalpunkt-Einlösung-Ereignis an';

  @override
  String get outgoingRaidEventConfigTitle => 'Ausgehendes Raid-Ereignis';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Passen Sie Ihr ausgehendes Raid-Ereignis an';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> raidet mit <b>$viewerCountString</b> Zuschauern!';
  }

  @override
  String get shoutout => 'Shoutout';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Raid auf <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '${secondsString}s';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> hat geraidet!';
  }

  @override
  String get raidingEventJoin => 'Beitreten';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Der Raid von <b>$displayName</b> wurde abgebrochen.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> hat ein Abonnement der Stufe $tier abgeschlossen!';
  }

  @override
  String subscriptionGiftEvent(
    String gifterUserName,
    int total,
    String tier,
    int cumulativeTotal,
  ) {
    final intl.NumberFormat totalNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat cumulativeTotalNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String cumulativeTotalString = cumulativeTotalNumberFormat.format(
      cumulativeTotal,
    );

    return '<b>$gifterUserName</b> hat $totalString Abonnements der Stufe $tier verschenkt, insgesamt $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
    String subscriberUserName,
    int cumulativeMonths,
    String tier,
  ) {
    final intl.NumberFormat cumulativeMonthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString = cumulativeMonthsNumberFormat.format(
      cumulativeMonths,
    );

    return '<b>$subscriberUserName</b> hat seit $cumulativeMonthsString Monaten ein Abonnement der Stufe $tier!';
  }

  @override
  String subscriptionMessageMultiMonthEvent(
    String subscriberUserName,
    String tier,
    int durationMonths,
    int cumulativeMonths,
  ) {
    final intl.NumberFormat durationMonthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String durationMonthsString = durationMonthsNumberFormat.format(
      durationMonths,
    );
    final intl.NumberFormat cumulativeMonthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString = cumulativeMonthsNumberFormat.format(
      cumulativeMonths,
    );

    return '<b>$subscriberUserName</b> hat ein Abonnement der Stufe $tier für $durationMonthsString Monate im Voraus abgeschlossen, insgesamt $cumulativeMonthsString Monate!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> hat <b>$value $currency</b> getippt.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonym hat <b>$value $currency</b> getippt.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> hat <b>$formattedAmount</b> auf StreamElements getippt.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> hat <b>$formattedAmount</b> auf Streamlabs getippt.';
  }

  @override
  String channelPointRedemptionWithUserInput(
    String redeemerUsername,
    String rewardName,
    int rewardCost,
    String userInput,
  ) {
    final intl.NumberFormat rewardCostNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> hat <b>$rewardName</b> für <b>$rewardCostString</b> Punkte eingelöst. $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
    String redeemerUsername,
    String rewardName,
    int rewardCost,
  ) {
    final intl.NumberFormat rewardCostNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> hat <b>$rewardName</b> für <b>$rewardCostString</b> Punkte eingelöst.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> hat <b>$bitsString</b> Bits gejubelt. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonym';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> hostet mit einer Party von <b>$viewersString</b>.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train Level <b>$level</b> in Bearbeitung! <b>$progressPercent%</b> abgeschlossen!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train Level <b>$levelString</b> erfolgreich abgeschlossen.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train Level <b>$levelString</b> nicht erfolgreich abgeschlossen.';
  }

  @override
  String get sampleMessage =>
      'Dies ist eine Beispielnachricht für Text-to-Speech.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author sagte: $text';
  }

  @override
  String get textToSpeechEnabled => 'Text-to-Speech aktiviert';

  @override
  String get textToSpeechDisabled => 'Text-to-Speech deaktiviert';

  @override
  String get alertsEnabled => 'Nur Benachrichtigungen';

  @override
  String get pinDuration => 'Anheftdauer';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds Sekunden',
      one: '1 Sekunde',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Minuten',
      one: '1 Minute',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Ereignis aktivieren';

  @override
  String get showEventInChatHistory => 'Ereignis im Chatverlauf anzeigen';

  @override
  String get enableShoutouts => 'Shoutouts aktivieren';

  @override
  String get enableShoutoutsSubtitle =>
      'Einen Link zum raidenden Kanal in den Chat senden';

  @override
  String get raidConfigurationTitle => 'Raid-Einstellungen';

  @override
  String get cheerConfigurationTitle => 'Cheer-Einstellungen';

  @override
  String get followConfigurationTitle => 'Follow-Einstellungen';

  @override
  String get outgoingRaidConfigurationTitle =>
      'Einstellungen für ausgehende Raids';

  @override
  String get hostConfigurationTitle => 'Host-Einstellungen';

  @override
  String get channelPointConfigurationTitle => 'Kanalpunkte-Einstellungen';

  @override
  String get pollConfigurationTitle => 'Umfrage-Einstellungen';

  @override
  String get hypetrainConfigurationTitle => 'Hype-Train-Einstellungen';

  @override
  String get subscriptionConfigurationTitle => 'Abonnement-Einstellungen';

  @override
  String get predictionConfigurationTitle => 'Vorhersage-Einstellungen';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Zusätzliche Anheftdauer für unerfüllte Belohnungen';

  @override
  String get pollPinDuration => 'Anheftdauer nach dem Endergebnis';

  @override
  String get hypetrainPinDuration =>
      'Anheftdauer nach dem Ende des Hype-Trains';

  @override
  String get enableGiftedSubscriptions =>
      'Einzelne verschenkte Abonnements aktivieren';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Jedes verschenkte Abonnement anzeigen';

  @override
  String get settingsBackupTitle =>
      'Einstellungen sichern und wiederherstellen';

  @override
  String get cloudBackup => 'Cloud-Sicherung';

  @override
  String get lastBackupNever => 'Letzte Sicherung: nie';

  @override
  String get backUp => 'Sichern';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get localBackup => 'Lokale Sicherung';

  @override
  String get exportSettings => 'Exportieren';

  @override
  String get importSettings => 'Importieren';

  @override
  String get showViewerAndFollowerCount =>
      'Zuschauer- und Followerzahl anzeigen';

  @override
  String get screenOrientation => 'Bildschirmausrichtung';

  @override
  String get appTheme => 'App-Design';

  @override
  String get systemDefault => 'System';

  @override
  String get portrait => 'Hochformat';

  @override
  String get landscape => 'Querformat';

  @override
  String get lightTheme => 'Hell';

  @override
  String get darkTheme => 'Dunkel';

  @override
  String get openSourceTitle => 'RealtimeChat ist Open Source';

  @override
  String get openSourceSubtitle => 'Finde uns auf GitHub!';

  @override
  String get discordSubtitle => 'Tritt dem Muxable-Discord bei!';

  @override
  String get earlyTestersThanks =>
      'Danke an alle frühen Tester, die Fehler gemeldet haben!';

  @override
  String get discoModeEnabled => '🕺 Disco-Modus aktiviert! :D';

  @override
  String get discoModeDisabled => '🕺 Disco-Modus deaktiviert D:';

  @override
  String get playSampleMessage => 'Beispielnachricht abspielen';

  @override
  String get textToSpeechRate => 'Sprechgeschwindigkeit';

  @override
  String get textToSpeechPitch => 'Tonhöhe';

  @override
  String get muteBots => 'Text-to-Speech für Bots stummschalten';

  @override
  String get muteEmotes => 'Alle Emotes in Text-to-Speech stummschalten';

  @override
  String get muteViewerNames =>
      'Zuschauernamen in Text-to-Speech stummschalten';

  @override
  String get subscribersOnly => 'Nur Abonnenten';

  @override
  String get fontSize => 'Schriftgröße';

  @override
  String get usernameContrastBoost => 'Kontrastverstärkung für Benutzernamen';

  @override
  String get twitchBadgeSettings => 'Twitch-Abzeichen-Einstellungen';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Lege fest, welche Abzeichen sichtbar sind';

  @override
  String get showDeletedMessages => 'Gelöschte Nachrichten anzeigen';

  @override
  String get deletedMessagesGreyedOut =>
      'Gelöschte Nachrichten werden ausgegraut';

  @override
  String get deletedMessagesRemoved => 'Gelöschte Nachrichten werden entfernt';

  @override
  String get showLoginNames => 'Anmeldenamen anzeigen';

  @override
  String get loginNamesShown =>
      'Anmeldenamen werden angezeigt, wenn sie vom Anzeigenamen abweichen';

  @override
  String get loginNamesHidden => 'Anmeldenamen werden ausgeblendet';

  @override
  String get compactMessages => 'Nachrichten komprimieren';

  @override
  String get dontCompactMessages => 'Nachrichten nicht komprimieren';

  @override
  String get dontCompactMessagesSubtitle =>
      'Nachrichten werden unverändert angezeigt';

  @override
  String get compactIndividualMessages => 'Einzelne Nachrichten komprimieren';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Wiederholter Text in Nachrichten wird gekürzt';

  @override
  String get announcementPinDuration => 'Anheftdauer für Ankündigungen';

  @override
  String get idleMessageAlertDuration => 'Dauer für Inaktivitätsalarm';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Wenn so lange keine Nachrichten kommen und dann eine neue eintrifft, wird ein Signalton abgespielt.';

  @override
  String get realtimeCashSubtitle => 'Verbinde eine ETH- oder MATIC-Wallet';

  @override
  String get walletAddress => 'Wallet-Adresse';

  @override
  String get streamlabsSubtitle => 'Sieh dir deine Streamlabs-Spenden an';

  @override
  String get streamElementsSubtitle =>
      'Sieh dir deine StreamElements-Spenden an';

  @override
  String get thirdPartyAuthError =>
      'Hm, das hat nicht funktioniert. Versuche es erneut oder frag auf Discord?';

  @override
  String get companionAuthBrowserTooOld =>
      'Dein Browser ist zu alt, um dich direkt anzumelden. Scanne diesen QR-Code mit deinem Handy, um dich auf einem anderen Gerät anzumelden.';

  @override
  String get companionAuthScanQrCode =>
      'Scanne diesen QR-Code mit deinem Handy, um dich auf einem anderen Gerät anzumelden.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> hat abonniert!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> hat das Abo um $monthsString Monate verlängert!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> hat $countString Abos verschenkt!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> hat $amountString Kicks gesendet!';
  }

  @override
  String get signInWithKick => 'Mit Kick anmelden';

  @override
  String get textToSpeechTooManyMessages =>
      'Es gibt zu viele Nachrichten. Sprachausgabe deaktiviert';

  @override
  String get turnOffTextToSpeech => 'Ausschalten';

  @override
  String get addChannel => 'Kanal hinzufügen';

  @override
  String get addToChat => 'Zum Chat hinzufügen';

  @override
  String get defaultChannels => 'Standardkanäle';

  @override
  String get defaultChannelsSubtitle =>
      'Die Kanäle, die beim Öffnen der App angezeigt werden';

  @override
  String get save => 'Speichern';

  @override
  String get resetToMyChannel => 'Auf meinen Kanal zurücksetzen';

  @override
  String get inChat => 'Im Chat';

  @override
  String get removeFromChat => 'Aus dem Chat entfernen';

  @override
  String cantChatWithAccount(String provider) {
    return 'Ihr $provider-Konto kann hier nicht chatten';
  }

  @override
  String get cantChatWithAccounts => 'Deine Konten können hier nicht chatten';

  @override
  String sendAMessageTo(String channel) {
    return 'Nachricht an $channel senden...';
  }

  @override
  String replaceChannel(String channel) {
    return '$channel ersetzen';
  }

  @override
  String get removeChannel => 'Entfernen';

  @override
  String get voicePacks => 'Sprachpakete';

  @override
  String get voicePacksDescription =>
      'Sprachpakete lesen den Chat mit natürlich klingenden Stimmen vor, die auf deinem Gerät laufen und nach dem Herunterladen offline funktionieren. Die Stimmen werden von KI erzeugt und sind keine Aufnahmen von Menschen.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices Stimmen',
      one: '1 Stimme',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sprachen',
      one: '1 Sprache',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Die Lizenz dieses Modells (OpenRAIL-M) verbietet schädliche Nutzungen, etwa das Vortäuschen fremder Identitäten oder das Verbreiten von Desinformation. Diese Einschränkungen gelten auch für dich.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return '$pack löschen? Dadurch werden $size frei.';
  }

  @override
  String get voicePackDownload => 'Herunterladen';

  @override
  String get voicePackUpdate => 'Aktualisieren';

  @override
  String get voicePackWaitingForWifi => 'Warten auf WLAN';

  @override
  String get voicePackUseMobileData => 'Mobile Daten verwenden';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Download: $downloaded von $total';
  }

  @override
  String get voicePackInstalling => 'Wird installiert';

  @override
  String voicePackInstallFailed(String pack) {
    return '$pack konnte nicht installiert werden. Prüfe deine Verbindung und versuche es erneut.';
  }

  @override
  String get voices => 'Stimmen';

  @override
  String get perViewerVoice => 'Stimme pro Zuschauer';

  @override
  String get perViewerVoiceSubtitle =>
      'Jeder Zuschauer erhält eine eigene Stimme. Die ausgewählte Stimme liest Benachrichtigungen vor, oder alles, wenn diese Option ausgeschaltet ist.';

  @override
  String get streamLanguage => 'Stream-Sprache';

  @override
  String get ttsEngineNeural => 'Neuronale Stimme (auf dem Gerät)';

  @override
  String get ttsEngineSystem => 'Systemstimme';

  @override
  String languageUnsupported(String language) {
    return 'Deine Sprachpakete unterstützen $language nicht; die Systemstimme wird verwendet';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Dieses Gerät hat nicht genug Arbeitsspeicher für neuronale Stimmen. Der Chat wird daher mit der Systemstimme vorgelesen.';

  @override
  String get neuralFallbackLoadFailed =>
      'Die neuronale Stimme konnte nicht geladen werden. Der Chat wird daher mit der Systemstimme vorgelesen.';

  @override
  String get accounts => 'Konten';

  @override
  String get accountsSubtitle =>
      'Melde dich auf jeder Plattform an, auf der du streamst';

  @override
  String addProviderAccount(String provider) {
    return '$provider-Konto hinzufügen';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Mit $provider anmelden';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return '$channel bei $provider abmelden?';
  }

  @override
  String get signOutOfAll => 'Von allen Konten abmelden';
}
