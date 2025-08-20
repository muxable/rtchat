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
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream online um $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream offline um $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
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
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
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
  String get durationOneMinute => '1 minute';

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
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

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
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
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
      String gifterUserName, int total, String tier, int cumulativeTotal) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat cumulativeTotalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeTotalString =
        cumulativeTotalNumberFormat.format(cumulativeTotal);

    return '<b>$gifterUserName</b> hat $totalString Abonnements der Stufe $tier verschenkt, insgesamt $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> hat seit $cumulativeMonthsString Monaten ein Abonnement der Stufe $tier!';
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
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> hat <b>$rewardName</b> für <b>$rewardCostString</b> Punkte eingelöst. $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> hat <b>$rewardName</b> für <b>$rewardCostString</b> Punkte eingelöst.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> hat <b>$bitsString</b> Bits gejubelt. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonym';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> hostet mit einer Party von <b>$viewersString</b>.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train Level <b>$level</b> in Bearbeitung! <b>$progressPercent%</b> abgeschlossen!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train Level <b>$levelString</b> erfolgreich abgeschlossen.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
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
  String get alertsEnabled => 'Alerts only';

  @override
  String get sidebarActions => 'Sidebar Actions';
}
