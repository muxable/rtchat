// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get sendAMessage => 'Verstuur een bericht...';

  @override
  String get writeSomething => 'Typ iets...';

  @override
  String get speakToTheCrowds => 'Spreek tegen het publiek...';

  @override
  String get shareYourThoughts => 'Deel je gedachtes...';

  @override
  String get saySomethingYouLittleBitch => 'Zeg iets, jij kleine trut...';

  @override
  String get search => 'Zoeken';

  @override
  String get notSignedIn => 'Niet ingelogd';

  @override
  String get searchChannels => 'Zoek';

  @override
  String get raidAChannel => 'Raid';

  @override
  String get noMessagesEmptyState => 'Het is still hier';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieuwe berichten',
      one: '1 nieuw bericht',
      zero: 'Geen nieuwe berichten',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Log in met Twitch';

  @override
  String get signInError =>
      'Er is een fout opgetreden tijdens het inloggen, Probeer het later opnieuw';

  @override
  String get continueAsGuest => 'Ga door als gast';

  @override
  String get signInToSendMessages => 'Log in om berichten te versturen';

  @override
  String get currentViewers => 'Huidige kijkers';

  @override
  String get textToSpeech => 'Tekst naar spraak';

  @override
  String get streamPreview => 'Stream voorvertoningen';

  @override
  String get activityFeed => 'Activiteitenfeed';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream online op $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream offline op $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Chat gewist op $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Configureer snelle links';

  @override
  String get disableRainMode => 'Regen modes uitschakelen';

  @override
  String get enableRainMode => 'Regen modes inschakelen';

  @override
  String get disableRainModeSubtitle => 'Interactie zal worden ingeschakeld';

  @override
  String get enableRainModeSubtitle => 'Interactie zal worden uitgeschakeld';

  @override
  String get refreshAudioSources => 'Herlaad audio bronnen';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count audio bronnen herladen',
      one: '1 audio bron herladen',
      zero: 'Geen audio bronnen herladen',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Instellingen';

  @override
  String get signOut => 'Log uit';

  @override
  String get cancel => 'Annuleren';

  @override
  String get signOutConfirmation => 'Weet je zeker dat je uit wil logen?';

  @override
  String get broadcaster => 'Broadcaster';

  @override
  String get moderators => 'Moderatoren';

  @override
  String get viewers => 'Kijkers';

  @override
  String get communityVips => 'Community VIPs';

  @override
  String get searchViewers => 'Kijkers zoeken';

  @override
  String get reconnecting => 'Opnieuw verbinden';

  @override
  String get twitchBadges => 'Twitch-badges';

  @override
  String get selectAll => 'Alles selecteren';

  @override
  String get quickLinks => 'Snelle link';

  @override
  String get swipeToDeleteQuickLinks =>
      'Swipe naar links of rechts om een snelle link te verwijderen';

  @override
  String get quickLinksLabelHint => 'Label';

  @override
  String get invalidUrlErrorText => 'Dit ziet er niet uit als een geldige URL';

  @override
  String get duplicateUrlErrorText => 'Deze link bestaat all';

  @override
  String get or => 'of';

  @override
  String get clearCookies => 'Cookies ';

  @override
  String get disabled => 'Uitschakelen';

  @override
  String get twitchActivityFeed => 'Twitch activiteitenfeed';

  @override
  String get signInToEnable =>
      'Je moet ingelogd zijn om dit aan te kunnen zetten';

  @override
  String get customUrl => 'Aangepaste URL';

  @override
  String get preview => 'Voorbeeld';

  @override
  String get audioSources => 'Audio bronnen';

  @override
  String get enableOffStreamSwitchTitle =>
      'Offline inschakelen (gebruikt meer batterij)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Audio zal ook afspelen als je offline bent';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Audio zal alleen afspelen als je live bent';

  @override
  String get iosOggWarningTitle => 'Hey! Luister!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS ondersteunt geen *.ogg media bestanden, wat de standaard formaat voor audio bestanden op Streamlabs is, Zorg er voor dat je andere een ander audio formaat gebruikt, anders zullen ze niet afspelen.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Personaliseer je Activiteitenfeed';

  @override
  String get audioSourcesSubtitle => 'Voeg web bronnen toe voor audio alerts';

  @override
  String get quickLinksSubtitle =>
      'Voeg snelkoppelingen toe aan de meest gebruikte tools';

  @override
  String get chatHistory => 'Chat geschiedenis';

  @override
  String get chatHistorySubtitle => 'Verander de chat weergave';

  @override
  String get textToSpeechSubtitle =>
      'Verander de audio naar spraak instellingen';

  @override
  String get events => 'Gebeurtenissen';

  @override
  String get eventsSubtitle => 'Configureer Twitch gebeurtenissen';

  @override
  String get thirdPartyServices => 'Diensten van derden';

  @override
  String get thirdPartyServicesSubtitle => 'Verbind met een dienst van derden';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> volgt je nu';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> en <b>$displayNameTwo</b> volgen je nu';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b>, en $numOthersString volgen je nu';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Ontdemp $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Demp $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Time-out $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Verban $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return '$displayName\'s verbanning opheffen';
  }

  @override
  String viewProfile(String displayName) {
    return 'Bekijk $displayName\'s profiel';
  }

  @override
  String get copyMessage => 'Kopieer bericht';

  @override
  String get deleteMessage => 'Verwijder bericht';

  @override
  String get longScrollNotification =>
      'Je scrolt een beetje ver, vind je niet?';

  @override
  String get stfu => 'hjb';

  @override
  String get globalEmotes => 'Globale Emotes';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString volgers',
      one: '1 volger',
      zero: '0 volgers',
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
      other: '$countString kijkers',
      one: '1 kijker',
      zero: '0 kijkers',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Hallo daar! We zijn blij dat je de voorvertoningen van de stream gebruikt, maar let er op dit gebruikt veen batterij, Chat lezen zonder de voorvertoningen verlengt je barrerij duur';

  @override
  String get okay => 'Oké';

  @override
  String get streamPreviewLoading => 'Stream laden (of de stream is offline)..';

  @override
  String get copiedToClipboard => 'Naar klembord gekopieerd';

  @override
  String get audioSourcesRequirePermissions =>
      'Audio bronnen vereisen toestemming';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Stem toe dat RealtimeChat over ander apps weergeeft om audio bronnen te gebruiken';

  @override
  String get audioSourcesRemoveButton => 'Verwijder audio bronnen';

  @override
  String get audioSourcesOpenSettingsButton => 'Open instellingen';

  @override
  String get flashOn => 'Flash aan';

  @override
  String get flashOff => 'Flash uit';

  @override
  String get durationOneSecond => '1 seconde';

  @override
  String get durationOneMinute => '1 minuut';

  @override
  String get durationTenMinutes => '10 minuten';

  @override
  String get durationOneHour => '1 uur';

  @override
  String get durationSixHours => '6 uur';

  @override
  String get durationOneDay => '1 dag';

  @override
  String get durationTwoDays => '2 dagen';

  @override
  String get durationOneWeek => '1 week';

  @override
  String get durationTwoWeeks => '2 weken';

  @override
  String get durationOneSecondTimeoutPrompt => 'Time-out voor 1 seconde';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Time-out voor 1 minuut';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Time-out voor 10 minuten';

  @override
  String get durationOneHourTimeoutPrompt => 'Time-out voor 1 uur';

  @override
  String get durationSixHoursTimeoutPrompt => 'Time-out voor 6 uur';

  @override
  String get durationOneDayTimeoutPrompt => 'Time-out voor 1 dag';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Time-out voor 2 dagen';

  @override
  String get durationOneWeekTimeoutPrompt => 'Time-out voor 1 week';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Time-out voor 2 weken';

  @override
  String get errorFetchingViewerList =>
      'We konden de kijkerslijst voor dit kanaal niet ophalen';

  @override
  String get eventsTitle => 'Evenementen';

  @override
  String get followEventConfigTitle => 'Volg evenement';

  @override
  String get customizeYourFollowEvent => 'Pas je volg evenement aan';

  @override
  String get subscribeEventConfigTitle => 'Abonneer evenement';

  @override
  String get customizeYourSubscriptionEvent => 'Pas je abonneer evenement aan';

  @override
  String get cheerEventConfigTitle => 'Juich evenement';

  @override
  String get customizeYourCheerEvent => 'Pas je juich evenement aan';

  @override
  String get raidEventConfigTitle => 'Raid evenement';

  @override
  String get customizeYourRaidEvent => 'Pas je raid evenement aan';

  @override
  String get hostEventConfigTitle => 'Host evenement';

  @override
  String get customizeYourHostEvent => 'Pas je host evenement aan';

  @override
  String get hypetrainEventConfigTitle => 'Hype Train evenement';

  @override
  String get customizeYourHypetrainEvent => 'Pas je Hype Train evenement aan';

  @override
  String get pollEventConfigTitle => 'Poll evenement';

  @override
  String get customizeYourPollEvent => 'Pas je poll evenement aan';

  @override
  String get predictionEventConfigTitle => 'Voorspellings evenement';

  @override
  String get customizeYourPredictionEvent =>
      'Pas je voorspellings evenement aan';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Kanaal punt inwissel evenement';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Pas je kanaal punt inwissel evenement aan';

  @override
  String get outgoingRaidEventConfigTitle => 'Uitgaande raid evenement';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Pas je uitgaande raid evenement aan';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b> is aan het raiden met <b>$viewerCountString</b> kijkers!';
  }

  @override
  String get shoutout => 'Shoutout';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Raiden <b>$displayName</b>...';
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
    return '<b>$displayName</b> heeft geraid!';
  }

  @override
  String get raidingEventJoin => 'Deelnemen';

  @override
  String raidingEventCanceled(String displayName) {
    return 'De raid van <b>$displayName</b> is geannuleerd.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> heeft zich geabonneerd op Tier $tier!';
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

    return '<b>$gifterUserName</b> heeft $totalString Tier $tier abonnementen cadeau gedaan, in totaal $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> is $cumulativeMonthsString maanden geabonneerd op Tier $tier!';
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

    return '<b>$subscriberUserName</b> heeft zich geabonneerd op niveau $tier voor $durationMonthsString maanden vooruit, $cumulativeMonthsString maanden in totaal!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> heeft <b>$value $currency</b> getipt.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anoniem heeft <b>$value $currency</b> getipt.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> heeft <b>$formattedAmount</b> getipt op StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> heeft <b>$formattedAmount</b> getipt op Streamlabs.';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> heeft <b>$rewardName</b> ingewisseld voor <b>$rewardCostString</b> punten. $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> heeft <b>$rewardName</b> ingewisseld voor <b>$rewardCostString</b> punten.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> heeft <b>$bitsString</b> bits gejuicht. $cheerMessage';
  }

  @override
  String get anonymous => 'Anoniem';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> is aan het hosten met een groep van <b>$viewersString</b> kijkers.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train level <b>$level</b> is bezig! <b>$progressPercent%</b> voltooid!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train level <b>$levelString</b> is geslaagd.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train level <b>$levelString</b> is mislukt.';
  }

  @override
  String get sampleMessage =>
      'Dit is een voorbeeldbericht voor tekst-naar-spraak.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author zei: $text';
  }

  @override
  String get textToSpeechEnabled => 'Text-to-Speech geactiveerd';

  @override
  String get textToSpeechDisabled => 'Text-to-Speech gedeactiveerd';

  @override
  String get alertsEnabled => 'Alleen meldingen';

  @override
  String get pinDuration => 'Vastpinduur';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconden',
      one: '1 seconde',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuten',
      one: '1 minuut',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Gebeurtenis inschakelen';

  @override
  String get showEventInChatHistory =>
      'Gebeurtenis tonen in de chatgeschiedenis';

  @override
  String get enableShoutouts => 'Shoutouts inschakelen';

  @override
  String get enableShoutoutsSubtitle =>
      'Een link naar het raidende kanaal in de chat plaatsen';

  @override
  String get raidConfigurationTitle => 'Raid-instellingen';

  @override
  String get cheerConfigurationTitle => 'Cheer-instellingen';

  @override
  String get followConfigurationTitle => 'Volg-instellingen';

  @override
  String get outgoingRaidConfigurationTitle =>
      'Instellingen voor uitgaande raids';

  @override
  String get hostConfigurationTitle => 'Host-instellingen';

  @override
  String get channelPointConfigurationTitle => 'Kanaalpunten-instellingen';

  @override
  String get pollConfigurationTitle => 'Poll-instellingen';

  @override
  String get hypetrainConfigurationTitle => 'Hype Train-instellingen';

  @override
  String get subscriptionConfigurationTitle => 'Abonnement-instellingen';

  @override
  String get predictionConfigurationTitle => 'Voorspelling-instellingen';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Extra vastpinduur voor niet-uitgevoerde beloningen';

  @override
  String get pollPinDuration => 'Vastpinduur na de definitieve uitslag';

  @override
  String get hypetrainPinDuration => 'Vastpinduur na afloop van de Hype Train';

  @override
  String get enableGiftedSubscriptions =>
      'Afzonderlijke cadeau-abonnementen inschakelen';

  @override
  String get enableGiftedSubscriptionsSubtitle => 'Elk cadeau-abonnement tonen';

  @override
  String get settingsBackupTitle => 'Instellingen back-uppen en herstellen';

  @override
  String get cloudBackup => 'Cloudback-up';

  @override
  String get lastBackupNever => 'Laatste back-up: nooit';

  @override
  String get backUp => 'Back-up maken';

  @override
  String get restore => 'Herstellen';

  @override
  String get localBackup => 'Lokale back-up';

  @override
  String get exportSettings => 'Exporteren';

  @override
  String get importSettings => 'Importeren';

  @override
  String get showViewerAndFollowerCount => 'Aantal kijkers en volgers tonen';

  @override
  String get screenOrientation => 'Schermoriëntatie';

  @override
  String get appTheme => 'App-thema';

  @override
  String get systemDefault => 'Systeem';

  @override
  String get portrait => 'Staand';

  @override
  String get landscape => 'Liggend';

  @override
  String get lightTheme => 'Licht';

  @override
  String get darkTheme => 'Donker';

  @override
  String get openSourceTitle => 'RealtimeChat is open source';

  @override
  String get openSourceSubtitle => 'Vind ons op GitHub!';

  @override
  String get discordSubtitle => 'Word lid van de Muxable-Discord!';

  @override
  String get earlyTestersThanks =>
      'Dank aan alle vroege testers die bugs hebben gemeld!';

  @override
  String get discoModeEnabled => '🕺 Discomodus ingeschakeld! :D';

  @override
  String get discoModeDisabled => '🕺 Discomodus uitgeschakeld D:';

  @override
  String get cloudTts => 'Cloud-TTS';

  @override
  String get languages => 'Talen';

  @override
  String get voices => 'Stemmen';

  @override
  String get perViewerVoice => 'Stem per kijker';

  @override
  String get perViewerVoiceSubtitle => 'Herken je kijkers aan hun stem';

  @override
  String get randomVoice => 'Willekeurig';

  @override
  String get playSampleMessage => 'Voorbeeldbericht afspelen';

  @override
  String get textToSpeechRate => 'Spreeksnelheid';

  @override
  String get textToSpeechPitch => 'Toonhoogte';

  @override
  String get unlockHighQualityVoices =>
      'Stemmen van hoge kwaliteit ontgrendelen';

  @override
  String get muteBots => 'Tekst-naar-spraak dempen voor bots';

  @override
  String get muteEmotes => 'Alle emotes dempen in tekst-naar-spraak';

  @override
  String get muteViewerNames => 'Kijkersnamen dempen in tekst-naar-spraak';

  @override
  String get subscribersOnly => 'Alleen abonnees';

  @override
  String get storeNotAvailable => 'Winkel niet beschikbaar';

  @override
  String get unavailable => 'Niet beschikbaar';

  @override
  String get subscribe => 'Abonneren';

  @override
  String get pending => 'In behandeling';

  @override
  String get subscribed => 'Geabonneerd';

  @override
  String get pleaseSignIn => 'Log in';

  @override
  String get searchLanguages => 'Talen zoeken';

  @override
  String get closeSearch => 'Zoeken sluiten';

  @override
  String get playSample => 'Voorbeeld afspelen';

  @override
  String get fontSize => 'Lettergrootte';

  @override
  String get usernameContrastBoost => 'Contrastverhoging gebruikersnamen';

  @override
  String get twitchBadgeSettings => 'Twitch-badge-instellingen';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Bepaal welke badges zichtbaar zijn';

  @override
  String get showDeletedMessages => 'Verwijderde berichten tonen';

  @override
  String get deletedMessagesGreyedOut =>
      'Verwijderde berichten worden grijs weergegeven';

  @override
  String get deletedMessagesRemoved => 'Verwijderde berichten worden verborgen';

  @override
  String get showLoginNames => 'Inlognamen tonen';

  @override
  String get loginNamesShown =>
      'Inlognamen worden getoond als ze verschillen van de weergavenaam';

  @override
  String get loginNamesHidden => 'Inlognamen worden verborgen';

  @override
  String get compactMessages => 'Berichten inkorten';

  @override
  String get dontCompactMessages => 'Berichten niet inkorten';

  @override
  String get dontCompactMessagesSubtitle =>
      'Berichten worden ongewijzigd getoond';

  @override
  String get compactIndividualMessages => 'Afzonderlijke berichten inkorten';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Herhaalde tekst in berichten wordt ingekort';

  @override
  String get announcementPinDuration => 'Vastpinduur van aankondigingen';

  @override
  String get idleMessageAlertDuration => 'Melding bij stille chat';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Als er zo lang geen berichten zijn en er komt een nieuw bericht binnen, klinkt er een meldingsgeluid.';

  @override
  String get realtimeCashSubtitle => 'Koppel een ETH- of MATIC-wallet';

  @override
  String get walletAddress => 'Walletadres';

  @override
  String get streamlabsSubtitle => 'Bekijk je Streamlabs-donaties';

  @override
  String get streamElementsSubtitle => 'Bekijk je StreamElements-donaties';

  @override
  String get thirdPartyAuthError =>
      'Hmm, dat werkte niet. Probeer het opnieuw, of vraag het op Discord?';

  @override
  String get companionAuthBrowserTooOld =>
      'Je browser is te oud om direct in te loggen. Scan deze QR-code met je telefoon om op een ander apparaat in te loggen.';

  @override
  String get companionAuthScanQrCode =>
      'Scan deze QR-code met je telefoon om op een ander apparaat in te loggen.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> heeft geabonneerd!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> heeft het abonnement verlengd voor $monthsString maanden!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> heeft $countString abonnementen cadeau gegeven!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> heeft $amountString Kicks gestuurd!';
  }

  @override
  String get signInWithKick => 'Log in met Kick';

  @override
  String get signInWithYouTube => 'Log in met YouTube';

  @override
  String get textToSpeechTooManyMessages =>
      'Er zijn te veel berichten. Tekst-naar-spraak uitgeschakeld';

  @override
  String get turnOffTextToSpeech => 'Uitschakelen';

  @override
  String youtubeSuperChatEvent(String name, String amount) {
    return '<b>$name</b> heeft een Super Chat van $amount gestuurd!';
  }

  @override
  String youtubeSuperStickerEvent(String name, String amount) {
    return '<b>$name</b> heeft een Super Sticker van $amount gestuurd!';
  }

  @override
  String youtubeNewMemberEvent(String name) {
    return '<b>$name</b> is lid geworden!';
  }

  @override
  String youtubeMemberUpgradeEvent(String name, String level) {
    return '<b>$name</b> is geüpgraded naar $level!';
  }

  @override
  String youtubeMemberMilestoneEvent(String name, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$name</b> is al $monthsString maanden lid!';
  }

  @override
  String youtubeMembershipGiftingEvent(String name, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '<b>$name</b> heeft $countString lidmaatschappen cadeau gegeven!',
      one: '<b>$name</b> heeft een lidmaatschap cadeau gegeven!',
    );
    return '$_temp0';
  }

  @override
  String youtubeGiftMembershipReceivedEvent(String name) {
    return '<b>$name</b> heeft een cadeaulidmaatschap ontvangen!';
  }

  @override
  String youtubeGiftEvent(String name, String giftName, int jewels) {
    final intl.NumberFormat jewelsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String jewelsString = jewelsNumberFormat.format(jewels);

    return '<b>$name</b> heeft $giftName gestuurd ($jewelsString Jewels)!';
  }

  @override
  String youtubePollEvent(String question) {
    return 'Poll: $question';
  }

  @override
  String get youtubeMembersOnlyModeOn => 'Alleen-leden-modus staat aan';

  @override
  String get youtubeMembersOnlyModeOff => 'Alleen-leden-modus staat uit';

  @override
  String get youtubeChatEnded => 'De livechat is afgelopen';
}
