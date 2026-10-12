// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get sendAMessage => 'Skicka ett meddelande...';

  @override
  String get writeSomething => 'Skriv något...';

  @override
  String get speakToTheCrowds => 'Tala till folkmassorna...';

  @override
  String get shareYourThoughts => 'Dela dina tankar...';

  @override
  String get saySomethingYouLittleBitch => 'Säg något, din lilla bitch...';

  @override
  String get search => 'Sök';

  @override
  String get notSignedIn => 'Inte inloggad';

  @override
  String get searchChannels => 'Sök kanaler';

  @override
  String get raidAChannel => 'Raid en kanal';

  @override
  String get noMessagesEmptyState => 'Inga meddelanden';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nya meddelanden',
      one: '1 nytt meddelande',
      zero: 'Inga nya meddelanden',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Logga in med Twitch';

  @override
  String get signInError => 'Ett fel uppstod vid inloggning. Försök igen.';

  @override
  String get continueAsGuest => 'Fortsätt som gäst';

  @override
  String get signInToSendMessages => 'Logga in för att skicka meddelanden';

  @override
  String get currentViewers => 'Nuvarande tittare';

  @override
  String get textToSpeech => 'Text till tal';

  @override
  String get streamPreview => 'Strömförhandsvisning';

  @override
  String get activityFeed => 'Aktivitetsflöde';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Ström online vid $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Ström offline vid $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Chatt rensad vid $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Konfigurera snabblänkar';

  @override
  String get disableRainMode => 'Inaktivera regnläge';

  @override
  String get enableRainMode => 'Aktivera regnläge';

  @override
  String get disableRainModeSubtitle => 'Interaktion kommer att aktiveras';

  @override
  String get enableRainModeSubtitle => 'Interaktion kommer att inaktiveras';

  @override
  String get refreshAudioSources => 'Uppdatera ljudkällor';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ljudkällor uppdaterade',
      one: '1 ljudkälla uppdaterad',
      zero: 'Inga ljudkällor uppdaterade',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Inställningar';

  @override
  String get signOut => 'Logga ut';

  @override
  String get cancel => 'Avbryt';

  @override
  String get signOutConfirmation => 'Är du säker på att du vill logga ut?';

  @override
  String get broadcaster => 'Sändare';

  @override
  String get moderators => 'Moderatorer';

  @override
  String get viewers => 'Tittare';

  @override
  String get communityVips => 'Community VIPs';

  @override
  String get searchViewers => 'Sök tittare';

  @override
  String get reconnecting => 'Återansluter...';

  @override
  String get twitchBadges => 'Twitch-märken';

  @override
  String get selectAll => 'Välj alla';

  @override
  String get quickLinks => 'Snabblänkar';

  @override
  String get swipeToDeleteQuickLinks =>
      'Svep åt vänster eller höger för att ta bort snabblänk';

  @override
  String get quickLinksLabelHint => 'Etikett';

  @override
  String get invalidUrlErrorText => 'Detta ser inte ut som en giltig URL';

  @override
  String get duplicateUrlErrorText => 'Denna länk finns redan';

  @override
  String get or => 'eller';

  @override
  String get clearCookies => 'Rensa cookies';

  @override
  String get disabled => 'Inaktiverad';

  @override
  String get twitchActivityFeed => 'Twitch aktivitetsflöde';

  @override
  String get signInToEnable => 'Du måste vara inloggad för att aktivera detta';

  @override
  String get customUrl => 'Anpassad URL';

  @override
  String get preview => 'Förhandsvisning';

  @override
  String get audioSources => 'Ljudkällor';

  @override
  String get enableOffStreamSwitchTitle =>
      'Aktivera off-stream (använder mer batteri)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Ljud kommer också att spelas när du är offline';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Ljud kommer endast att spelas när du är live';

  @override
  String get iosOggWarningTitle => 'Hej! Lyssna!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS stöder inte *.ogg mediefiler, som är standardfilerna på Streamlabs. Se till att dina ljudkällor använder ett annat format, annars kommer de inte att spelas.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Anpassa ditt aktivitetsflöde';

  @override
  String get audioSourcesSubtitle => 'Lägg till webbkällor för varningsljud';

  @override
  String get quickLinksSubtitle => 'Lägg till genvägar till vanliga verktyg';

  @override
  String get chatHistory => 'Chatthistorik';

  @override
  String get chatHistorySubtitle => 'Ändra chattens utseende';

  @override
  String get textToSpeechSubtitle => 'Ändra inställningar för text till tal';

  @override
  String get events => 'Händelser';

  @override
  String get eventsSubtitle => 'Konfigurera Twitch-händelser';

  @override
  String get thirdPartyServices => 'Tredjepartstjänster';

  @override
  String get thirdPartyServicesSubtitle => 'Anslut till en tredjepartstjänst';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> följer dig';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> och <b>$displayNameTwo</b> följer dig';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b> och $numOthersString andra följer dig';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Avaktivera ljud för $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Stäng av ljud för $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Timeout för $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Banna $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Avbanna $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Visa ${displayName}s profil';
  }

  @override
  String get copyMessage => 'Kopiera meddelande';

  @override
  String get deleteMessage => 'Radera meddelande';

  @override
  String get longScrollNotification =>
      'Du scrollar ganska långt, tycker du inte?';

  @override
  String get stfu => 'håll käften';

  @override
  String get globalEmotes => 'Globala emotes';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString följare',
      one: '1 följare',
      zero: '0 följare',
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
      other: '$countString tittare',
      one: '1 tittare',
      zero: '0 tittare',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Hej där! Vi är glada att du gillar att använda strömförhandsvisningen, men tänk på att den använder mycket batteri. Att läsa chatten utan den kommer att förlänga batteritiden.';

  @override
  String get okay => 'Okej';

  @override
  String get streamPreviewLoading => 'Laddar (eller strömmen är offline)...';

  @override
  String get copiedToClipboard => 'Kopierat till urklipp';

  @override
  String get audioSourcesRequirePermissions => 'Ljudkällor kräver behörigheter';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Godkänn att RealtimeChat får rita över andra appar för att använda ljudkällor.';

  @override
  String get audioSourcesRemoveButton => 'Ta bort ljudkällor';

  @override
  String get audioSourcesOpenSettingsButton => 'Öppna inställningar';

  @override
  String get flashOn => 'Blixt på';

  @override
  String get flashOff => 'Blixt av';

  @override
  String get durationOneSecond => '1 sekund';

  @override
  String get durationOneMinute => '1 minut';

  @override
  String get durationTenMinutes => '10 minuter';

  @override
  String get durationOneHour => '1 timme';

  @override
  String get durationSixHours => '6 timmar';

  @override
  String get durationOneDay => '1 dag';

  @override
  String get durationTwoDays => '2 dagar';

  @override
  String get durationOneWeek => '1 vecka';

  @override
  String get durationTwoWeeks => '2 veckor';

  @override
  String get durationOneSecondTimeoutPrompt => 'Timeout i 1 sekund';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Timeout i 1 minut';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Timeout i 10 minuter';

  @override
  String get durationOneHourTimeoutPrompt => 'Timeout i 1 timme';

  @override
  String get durationSixHoursTimeoutPrompt => 'Timeout i 6 timmar';

  @override
  String get durationOneDayTimeoutPrompt => 'Timeout i 1 dag';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Timeout i 2 dagar';

  @override
  String get durationOneWeekTimeoutPrompt => 'Timeout i 1 vecka';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Timeout i 2 veckor';

  @override
  String get errorFetchingViewerList =>
      'Vi kunde inte hämta tittarlistan för denna kanal';

  @override
  String get eventsTitle => 'Händelser';

  @override
  String get followEventConfigTitle => 'Följ händelse';

  @override
  String get customizeYourFollowEvent => 'Anpassa din följhändelse';

  @override
  String get subscribeEventConfigTitle => 'Prenumerera händelse';

  @override
  String get customizeYourSubscriptionEvent =>
      'Anpassa din prenumerationshändelse';

  @override
  String get cheerEventConfigTitle => 'Heja händelse';

  @override
  String get customizeYourCheerEvent => 'Anpassa din hejahändelse';

  @override
  String get raidEventConfigTitle => 'Raid händelse';

  @override
  String get customizeYourRaidEvent => 'Anpassa din raidhändelse';

  @override
  String get hostEventConfigTitle => 'Värd händelse';

  @override
  String get customizeYourHostEvent => 'Anpassa din värdhändelse';

  @override
  String get hypetrainEventConfigTitle => 'Hype Train händelse';

  @override
  String get customizeYourHypetrainEvent => 'Anpassa din Hype Train händelse';

  @override
  String get pollEventConfigTitle => 'Omröstning händelse';

  @override
  String get customizeYourPollEvent => 'Anpassa din omröstningshändelse';

  @override
  String get predictionEventConfigTitle => 'Förutsägelse händelse';

  @override
  String get customizeYourPredictionEvent => 'Anpassa din förutsägelsehändelse';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Kanalpoäng inlösen händelse';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Anpassa din kanalpoäng inlösen händelse';

  @override
  String get outgoingRaidEventConfigTitle => 'Utgående raid händelse';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Anpassa din utgående raidhändelse';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b> raider med <b>$viewerCountString</b> tittare!';
  }

  @override
  String get shoutout => 'Shoutout';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Raider <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString sekunder kvar';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> har raidat!';
  }

  @override
  String get raidingEventJoin => 'Gå med';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b>s raid avbröts.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> har prenumererat på nivå $tier!';
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

    return '<b>$gifterUserName</b> har gett $totalString prenumerationer på nivå $tier, totalt $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> har prenumererat i $cumulativeMonthsString månader på nivå $tier!';
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

    return '<b>$subscriberUserName</b> har prenumererat på nivå $tier i $durationMonthsString månader i förväg, $cumulativeMonthsString månader totalt!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> gav en dricks på <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonym gav en dricks på <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> gav en dricks på <b>$formattedAmount</b> på StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> gav en dricks på <b>$formattedAmount</b> på Streamlabs.';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> löste in <b>$rewardName</b> för <b>$rewardCostString</b> poäng. $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> löste in <b>$rewardName</b> för <b>$rewardCostString</b> poäng.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> hejade med <b>$bitsString</b> bits. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonym';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> är värd med en grupp på <b>$viewersString</b> tittare.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train nivå <b>$level</b> pågår! <b>$progressPercent%</b> slutfört!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train nivå <b>$levelString</b> lyckades.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train nivå <b>$levelString</b> misslyckades.';
  }

  @override
  String get sampleMessage =>
      'Detta är ett exempelmeddelande för text till tal.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author sa: $text';
  }

  @override
  String get textToSpeechEnabled => 'Text till tal aktiverat';

  @override
  String get textToSpeechDisabled => 'Text till tal inaktiverad';

  @override
  String get alertsEnabled => 'Endast aviseringar';

  @override
  String get pinDuration => 'Fäst tid';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekunder',
      one: '1 sekund',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuter',
      one: '1 minut',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Aktivera händelse';

  @override
  String get showEventInChatHistory => 'Visa händelsen i chatthistoriken';

  @override
  String get enableShoutouts => 'Aktivera shoutouts';

  @override
  String get enableShoutoutsSubtitle =>
      'Skicka en länk till den raidande kanalen i chatten';

  @override
  String get raidConfigurationTitle => 'Raidinställningar';

  @override
  String get cheerConfigurationTitle => 'Cheerinställningar';

  @override
  String get followConfigurationTitle => 'Följinställningar';

  @override
  String get outgoingRaidConfigurationTitle =>
      'Inställningar för utgående raids';

  @override
  String get hostConfigurationTitle => 'Hostinställningar';

  @override
  String get channelPointConfigurationTitle => 'Inställningar för kanalpoäng';

  @override
  String get pollConfigurationTitle => 'Omröstningsinställningar';

  @override
  String get hypetrainConfigurationTitle => 'Hype Train-inställningar';

  @override
  String get subscriptionConfigurationTitle => 'Prenumerationsinställningar';

  @override
  String get predictionConfigurationTitle => 'Förutsägelseinställningar';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Extra fäst tid för ouppfyllda belöningar';

  @override
  String get pollPinDuration => 'Fäst tid efter slutresultatet';

  @override
  String get hypetrainPinDuration => 'Fäst tid efter att Hype Train är över';

  @override
  String get enableGiftedSubscriptions =>
      'Aktivera enskilda gåvoprenumerationer';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Visa varje prenumeration som ges bort';

  @override
  String get settingsBackupTitle =>
      'Säkerhetskopiera och återställ inställningar';

  @override
  String get cloudBackup => 'Molnsäkerhetskopia';

  @override
  String get lastBackupNever => 'Senaste säkerhetskopia: aldrig';

  @override
  String get backUp => 'Säkerhetskopiera';

  @override
  String get restore => 'Återställ';

  @override
  String get localBackup => 'Lokal säkerhetskopia';

  @override
  String get exportSettings => 'Exportera';

  @override
  String get importSettings => 'Importera';

  @override
  String get showViewerAndFollowerCount => 'Visa antal tittare och följare';

  @override
  String get screenOrientation => 'Skärmorientering';

  @override
  String get appTheme => 'Apptema';

  @override
  String get systemDefault => 'System';

  @override
  String get portrait => 'Stående';

  @override
  String get landscape => 'Liggande';

  @override
  String get lightTheme => 'Ljust';

  @override
  String get darkTheme => 'Mörkt';

  @override
  String get openSourceTitle => 'RealtimeChat är öppen källkod';

  @override
  String get openSourceSubtitle => 'Hitta oss på GitHub!';

  @override
  String get discordSubtitle => 'Gå med i Muxables Discord!';

  @override
  String get earlyTestersThanks =>
      'Tack till alla tidiga testare som rapporterade buggar!';

  @override
  String get discoModeEnabled => '🕺 Discoläge aktiverat! :D';

  @override
  String get discoModeDisabled => '🕺 Discoläge inaktiverat D:';

  @override
  String get cloudTts => 'Moln-TTS';

  @override
  String get languages => 'Språk';

  @override
  String get voices => 'Röster';

  @override
  String get perViewerVoice => 'Röst per tittare';

  @override
  String get perViewerVoiceSubtitle => 'Känn igen dina tittare på rösten';

  @override
  String get randomVoice => 'Slumpmässig';

  @override
  String get playSampleMessage => 'Spela upp exempelmeddelande';

  @override
  String get textToSpeechRate => 'Talhastighet';

  @override
  String get textToSpeechPitch => 'Tonhöjd';

  @override
  String get unlockHighQualityVoices => 'Lås upp röster av hög kvalitet';

  @override
  String get muteBots => 'Stäng av text-till-tal för bottar';

  @override
  String get muteEmotes => 'Stäng av alla emotes i text-till-tal';

  @override
  String get muteViewerNames => 'Stäng av tittarnamn i text-till-tal';

  @override
  String get subscribersOnly => 'Endast prenumeranter';

  @override
  String get storeNotAvailable => 'Butiken är inte tillgänglig';

  @override
  String get unavailable => 'Inte tillgänglig';

  @override
  String get subscribe => 'Prenumerera';

  @override
  String get pending => 'Väntar';

  @override
  String get subscribed => 'Prenumererar';

  @override
  String get pleaseSignIn => 'Logga in';

  @override
  String get searchLanguages => 'Sök språk';

  @override
  String get closeSearch => 'Stäng sökning';

  @override
  String get playSample => 'Spela upp exempel';

  @override
  String get fontSize => 'Teckenstorlek';

  @override
  String get usernameContrastBoost => 'Kontrastförstärkning för användarnamn';

  @override
  String get twitchBadgeSettings => 'Inställningar för Twitch-märken';

  @override
  String get twitchBadgeSettingsSubtitle => 'Välj vilka märken som syns';

  @override
  String get showDeletedMessages => 'Visa raderade meddelanden';

  @override
  String get deletedMessagesGreyedOut => 'Raderade meddelanden gråas ut';

  @override
  String get deletedMessagesRemoved => 'Raderade meddelanden tas bort';

  @override
  String get showLoginNames => 'Visa inloggningsnamn';

  @override
  String get loginNamesShown =>
      'Inloggningsnamn visas om de skiljer sig från visningsnamnet';

  @override
  String get loginNamesHidden => 'Inloggningsnamn döljs';

  @override
  String get compactMessages => 'Komprimera meddelanden';

  @override
  String get dontCompactMessages => 'Komprimera inte meddelanden';

  @override
  String get dontCompactMessagesSubtitle => 'Meddelanden visas oförändrade';

  @override
  String get compactIndividualMessages => 'Komprimera enskilda meddelanden';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Upprepad text i meddelanden förkortas';

  @override
  String get announcementPinDuration => 'Fäst tid för meddelanden';

  @override
  String get idleMessageAlertDuration => 'Varning vid tyst chatt';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Om det inte kommer några meddelanden under den här tiden och sedan kommer ett nytt spelas ett varningsljud.';

  @override
  String get realtimeCashSubtitle => 'Anslut en ETH- eller MATIC-plånbok';

  @override
  String get walletAddress => 'Plånboksadress';

  @override
  String get streamlabsSubtitle => 'Se dina Streamlabs-donationer';

  @override
  String get streamElementsSubtitle => 'Se dina StreamElements-donationer';

  @override
  String get thirdPartyAuthError =>
      'Hmm, det fungerade inte. Försök igen, eller fråga på Discord?';

  @override
  String get companionAuthBrowserTooOld =>
      'Din webbläsare är för gammal för att logga in direkt. Skanna den här QR-koden med telefonen för att logga in på en annan enhet.';

  @override
  String get companionAuthScanQrCode =>
      'Skanna den här QR-koden med telefonen för att logga in på en annan enhet.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> har prenumererat!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> har förnyat sin prenumeration i $monthsString månader!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> har gett bort $countString prenumerationer!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> skickade $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Logga in med Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Det finns för många meddelanden. Text till tal avstängt';

  @override
  String get turnOffTextToSpeech => 'Stäng av';

  @override
  String get sendToAllChannels => 'Skicka till alla kanaler';
}
