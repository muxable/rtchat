// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'package:rtchat/l10n/app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get sendAMessage => 'Send en besked...';

  @override
  String get writeSomething => 'Skriv noget...';

  @override
  String get speakToTheCrowds => 'Tal til publikum...';

  @override
  String get shareYourThoughts => 'Del dine tanker...';

  @override
  String get saySomethingYouLittleBitch => 'Sig noget, din lille kælling...';

  @override
  String get search => 'Søg';

  @override
  String get notSignedIn => 'Ikke logget ind';

  @override
  String get searchChannels => 'Søg';

  @override
  String get raidAChannel => 'Raid';

  @override
  String get noMessagesEmptyState => 'Her er stille.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nye beskeder',
      one: '1 ny besked',
      zero: 'Ingen nye beskeder',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Log ind med Twitch';

  @override
  String get signInError => 'Der opstod en fejl under login. Prøv igen.';

  @override
  String get continueAsGuest => 'Fortsæt som gæst';

  @override
  String get signInToSendMessages => 'Log ind for at sende beskeder';

  @override
  String get currentViewers => 'Aktuelle seere';

  @override
  String get textToSpeech => 'Tekst til tale';

  @override
  String get streamPreview => 'Streamforhåndsvisning';

  @override
  String get activityFeed => 'Aktivitetsoversigt';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream startet den $dateString kl. $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream afsluttet den $dateString kl. $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Chat ryddet den $dateString kl. $timeString';
  }

  @override
  String get configureQuickLinks => 'Indstil hurtiglinks';

  @override
  String get disableRainMode => 'Slå regntilstand fra';

  @override
  String get enableRainMode => 'Slå regntilstand til';

  @override
  String get disableRainModeSubtitle => 'Interaktion bliver aktiveret';

  @override
  String get enableRainModeSubtitle => 'Interaktion bliver deaktiveret';

  @override
  String get refreshAudioSources => 'Opdater lydkilder';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lydkilder opdateret',
      one: '1 lydkilde opdateret',
      zero: 'Ingen lydkilder opdateret',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Indstillinger';

  @override
  String get signOut => 'Log ud';

  @override
  String get cancel => 'Annuller';

  @override
  String get signOutConfirmation => 'Er du sikker på, at du vil logge ud?';

  @override
  String get broadcaster => 'Streamer';

  @override
  String get moderators => 'Moderatorer';

  @override
  String get viewers => 'Seere';

  @override
  String get communityVips => 'Fællesskabets VIP\'er';

  @override
  String get searchViewers => 'Søg efter seere';

  @override
  String get reconnecting => 'Opretter forbindelse igen...';

  @override
  String get twitchBadges => 'Twitch-mærker';

  @override
  String get selectAll => 'Vælg alle';

  @override
  String get quickLinks => 'Hurtiglinks';

  @override
  String get swipeToDeleteQuickLinks =>
      'Stryg til venstre eller højre for at slette et hurtiglink';

  @override
  String get quickLinksLabelHint => 'Navn';

  @override
  String get invalidUrlErrorText => 'Det ligner ikke en gyldig URL';

  @override
  String get duplicateUrlErrorText => 'Dette link findes allerede';

  @override
  String get or => 'eller';

  @override
  String get clearCookies => 'Ryd cookies';

  @override
  String get disabled => 'Deaktiveret';

  @override
  String get twitchActivityFeed => 'Twitch-aktivitetsoversigt';

  @override
  String get signInToEnable => 'Du skal være logget ind for at aktivere dette';

  @override
  String get customUrl => 'Brugerdefineret URL';

  @override
  String get preview => 'Forhåndsvisning';

  @override
  String get audioSources => 'Lydkilder';

  @override
  String get enableOffStreamSwitchTitle =>
      'Aktivér uden for stream (bruger mere batteri)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Lyd afspilles også, når du er offline';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Lyd afspilles kun, når du er live';

  @override
  String get iosOggWarningTitle => 'Hey! Lyt lige!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS understøtter ikke *.ogg-mediefiler, som er standardformatet på Streamlabs. Sørg for, at dine lydkilder bruger et andet format, ellers kan de ikke afspilles.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Tilpas din aktivitetsoversigt';

  @override
  String get audioSourcesSubtitle => 'Tilføj webkilder til notifikationslyde';

  @override
  String get quickLinksSubtitle => 'Tilføj genveje til ofte anvendte værktøjer';

  @override
  String get chatHistory => 'Chathistorik';

  @override
  String get chatHistorySubtitle => 'Skift chattens udseende';

  @override
  String get textToSpeechSubtitle => 'Skift indstillinger for tekst til tale';

  @override
  String get events => 'Begivenheder';

  @override
  String get eventsSubtitle => 'Indstil Twitch-begivenheder';

  @override
  String get thirdPartyServices => 'Tredjepartstjenester';

  @override
  String get thirdPartyServicesSubtitle =>
      'Opret forbindelse til en tredjepartstjeneste';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> følger dig';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> og <b>$displayNameTwo</b> følger dig';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> og $numOthersString andre følger dig';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Slå lyden til for $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Slå lyden fra for $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Giv $displayName en timeout';
  }

  @override
  String banUser(String displayName) {
    return 'Udeluk $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Ophæv udelukkelsen af $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Se profilen for $displayName';
  }

  @override
  String get copyMessage => 'Kopiér besked';

  @override
  String get deleteMessage => 'Slet besked';

  @override
  String get longScrollNotification =>
      'Du er vist ved at rulle ret langt tilbage, synes du ikke?';

  @override
  String get stfu => 'stfu';

  @override
  String get globalEmotes => 'Globale emotes';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString følgere',
      one: '1 følger',
      zero: '0 følgere',
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
      other: '$countString seere',
      one: '1 seer',
      zero: '0 seere',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Hej! Dejligt, at du kan lide streamforhåndsvisningen, men den bruger meget batteri. Hvis du læser chatten uden den, holder batteriet længere.';

  @override
  String get okay => 'Okay';

  @override
  String get streamPreviewLoading => 'Indlæser (eller streamen er offline)...';

  @override
  String get copiedToClipboard => 'Kopieret til udklipsholder';

  @override
  String get audioSourcesRequirePermissions => 'Lydkilder kræver tilladelser';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Giv RealtimeChat tilladelse til at vise indhold oven på andre apps for at bruge lydkilder.';

  @override
  String get audioSourcesRemoveButton => 'Fjern lydkilder';

  @override
  String get audioSourcesOpenSettingsButton => 'Åbn indstillinger';

  @override
  String get flashOn => 'Blitz til';

  @override
  String get flashOff => 'Blitz fra';

  @override
  String get durationOneSecond => '1 sekund';

  @override
  String get durationOneMinute => '1 minut';

  @override
  String get durationTenMinutes => '10 minutter';

  @override
  String get durationOneHour => '1 time';

  @override
  String get durationSixHours => '6 timer';

  @override
  String get durationOneDay => '1 dag';

  @override
  String get durationTwoDays => '2 dage';

  @override
  String get durationOneWeek => '1 uge';

  @override
  String get durationTwoWeeks => '2 uger';

  @override
  String get durationOneSecondTimeoutPrompt => 'Timeout: 1 sekund';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Timeout: 1 minut';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Timeout: 10 minutter';

  @override
  String get durationOneHourTimeoutPrompt => 'Timeout: 1 time';

  @override
  String get durationSixHoursTimeoutPrompt => 'Timeout: 6 timer';

  @override
  String get durationOneDayTimeoutPrompt => 'Timeout: 1 dag';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Timeout: 2 dage';

  @override
  String get durationOneWeekTimeoutPrompt => 'Timeout: 1 uge';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Timeout: 2 uger';

  @override
  String get errorFetchingViewerList =>
      'Vi kunne ikke hente seerlisten for denne kanal';

  @override
  String get eventsTitle => 'Begivenheder';

  @override
  String get followEventConfigTitle => 'Følgebegivenhed';

  @override
  String get customizeYourFollowEvent => 'Tilpas: Følgebegivenhed';

  @override
  String get subscribeEventConfigTitle => 'Abonnementsbegivenhed';

  @override
  String get customizeYourSubscriptionEvent => 'Tilpas: Abonnementsbegivenhed';

  @override
  String get cheerEventConfigTitle => 'Heppebegivenhed';

  @override
  String get customizeYourCheerEvent => 'Tilpas: Heppebegivenhed';

  @override
  String get raidEventConfigTitle => 'Raidbegivenhed';

  @override
  String get customizeYourRaidEvent => 'Tilpas: Raidbegivenhed';

  @override
  String get hostEventConfigTitle => 'Værtsbegivenhed';

  @override
  String get customizeYourHostEvent => 'Tilpas: Værtsbegivenhed';

  @override
  String get hypetrainEventConfigTitle => 'Hype Train-begivenhed';

  @override
  String get customizeYourHypetrainEvent => 'Tilpas: Hype Train-begivenhed';

  @override
  String get pollEventConfigTitle => 'Afstemningsbegivenhed';

  @override
  String get customizeYourPollEvent => 'Tilpas: Afstemningsbegivenhed';

  @override
  String get predictionEventConfigTitle => 'Forudsigelsesbegivenhed';

  @override
  String get customizeYourPredictionEvent => 'Tilpas: Forudsigelsesbegivenhed';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Indløsning af kanalpoint';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Tilpas: Indløsning af kanalpoint';

  @override
  String get outgoingRaidEventConfigTitle => 'Udgående raid';

  @override
  String get customizeYourOutgoingRaidEvent => 'Tilpas: Udgående raid';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> raider med <b>$viewerCountString</b> seere!';
  }

  @override
  String get shoutout => 'Kanalomtale';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Raider <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString s';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> har raidet!';
  }

  @override
  String get raidingEventJoin => 'Deltag';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Raidet fra <b>$displayName</b> blev annulleret.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> har abonneret på niveau $tier!';
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

    return '<b>$gifterUserName</b> har givet $totalString abonnementer på niveau $tier, i alt $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> har abonneret i $cumulativeMonthsString måneder på niveau $tier!';
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

    return '<b>$subscriberUserName</b> har forudbetalt $durationMonthsString måneders abonnement på niveau $tier, i alt $cumulativeMonthsString måneder!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> gav <b>$value $currency</b> i drikkepenge.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'En anonym gav <b>$value $currency</b> i drikkepenge.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> gav <b>$formattedAmount</b> i drikkepenge på StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> gav <b>$formattedAmount</b> i drikkepenge på Streamlabs.';
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

    return '<b>$redeemerUsername</b> indløste <b>$rewardName</b> for <b>$rewardCostString</b> point. $userInput';
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

    return '<b>$redeemerUsername</b> indløste <b>$rewardName</b> for <b>$rewardCostString</b> point.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> heppede med <b>$bitsString</b> bits. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonym';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> er vært for et selskab på <b>$viewersString</b>.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train på niveau <b>$level</b> er i gang! <b>$progressPercent%</b> fuldført!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train på niveau <b>$levelString</b> lykkedes.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train på niveau <b>$levelString</b> mislykkedes.';
  }

  @override
  String get sampleMessage => 'Dette er en eksempelbesked til tekst til tale.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author sagde: $text';
  }

  @override
  String get textToSpeechEnabled => 'Tekst til tale aktiveret';

  @override
  String get textToSpeechDisabled => 'Tekst til tale deaktiveret';

  @override
  String get alertsEnabled => 'Kun notifikationer';

  @override
  String get pinDuration => 'Fastgørelsesvarighed';

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
      other: '$minutes minutter',
      one: '1 minut',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Aktivér begivenhed';

  @override
  String get showEventInChatHistory => 'Vis begivenhed i chathistorikken';

  @override
  String get enableShoutouts => 'Aktivér kanalomtaler';

  @override
  String get enableShoutoutsSubtitle =>
      'Send et link til den raidede kanal i chatten';

  @override
  String get raidConfigurationTitle => 'Konfiguration: Raidbegivenhed';

  @override
  String get cheerConfigurationTitle => 'Konfiguration: Heppebegivenhed';

  @override
  String get followConfigurationTitle => 'Konfiguration: Følgebegivenhed';

  @override
  String get outgoingRaidConfigurationTitle => 'Konfiguration: Udgående raid';

  @override
  String get hostConfigurationTitle => 'Konfiguration: Værtsbegivenhed';

  @override
  String get channelPointConfigurationTitle =>
      'Konfiguration: Indløsning af kanalpoint';

  @override
  String get pollConfigurationTitle => 'Konfiguration: Afstemningsbegivenhed';

  @override
  String get hypetrainConfigurationTitle =>
      'Konfiguration: Hype Train-begivenhed';

  @override
  String get subscriptionConfigurationTitle =>
      'Konfiguration: Abonnementsbegivenhed';

  @override
  String get predictionConfigurationTitle =>
      'Konfiguration: Forudsigelsesbegivenhed';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Ekstra fastgørelsestid for uopfyldte belønninger';

  @override
  String get pollPinDuration => 'Fastgørelsestid efter det endelige resultat';

  @override
  String get hypetrainPinDuration => 'Fastgørelsestid efter Hype Train er slut';

  @override
  String get enableGiftedSubscriptions =>
      'Aktivér individuelle gaveabonnementer';

  @override
  String get enableGiftedSubscriptionsSubtitle => 'Vis hvert gaveabonnement';

  @override
  String get settingsBackupTitle =>
      'Sikkerhedskopiering og gendannelse af indstillinger';

  @override
  String get cloudBackup => 'Sikkerhedskopi i skyen';

  @override
  String get lastBackupNever => 'Seneste sikkerhedskopi: aldrig';

  @override
  String get backUp => 'Sikkerhedskopiér';

  @override
  String get restore => 'Gendan';

  @override
  String get localBackup => 'Lokal sikkerhedskopi';

  @override
  String get exportSettings => 'Eksportér';

  @override
  String get importSettings => 'Importér';

  @override
  String get showViewerAndFollowerCount => 'Vis antal seere og følgere';

  @override
  String get screenOrientation => 'Skærmretning';

  @override
  String get appTheme => 'Appens tema';

  @override
  String get systemDefault => 'System';

  @override
  String get portrait => 'Stående';

  @override
  String get landscape => 'Liggende';

  @override
  String get lightTheme => 'Lyst';

  @override
  String get darkTheme => 'Mørkt';

  @override
  String get openSourceTitle => 'RealtimeChat er open source';

  @override
  String get openSourceSubtitle => 'Find os på GitHub!';

  @override
  String get discordSubtitle => 'Deltag i Muxables Discord!';

  @override
  String get earlyTestersThanks =>
      'Tak til alle de tidlige testere, der indsendte fejlrapporter!';

  @override
  String get discoModeEnabled => '🕺 Discotilstand aktiveret! :D';

  @override
  String get discoModeDisabled => '🕺 Discotilstand deaktiveret D:';

  @override
  String get playSampleMessage => 'Afspil eksempelbesked';

  @override
  String get textToSpeechRate => 'Talehastighed';

  @override
  String get textToSpeechPitch => 'Tonehøjde';

  @override
  String get muteBots => 'Slå tekst til tale fra for bots';

  @override
  String get muteEmotes => 'Slå alle emotes fra i tekst til tale';

  @override
  String get muteViewerNames => 'Undlad at oplæse seernavne';

  @override
  String get subscribersOnly => 'Kun abonnenter';

  @override
  String get fontSize => 'Skriftstørrelse';

  @override
  String get usernameContrastBoost => 'Øget kontrast for brugernavne';

  @override
  String get twitchBadgeSettings => 'Indstillinger for Twitch-mærker';

  @override
  String get twitchBadgeSettingsSubtitle => 'Vælg, hvilke mærker der vises';

  @override
  String get showDeletedMessages => 'Vis slettede beskeder';

  @override
  String get deletedMessagesGreyedOut => 'Slettede beskeder vises nedtonet';

  @override
  String get deletedMessagesRemoved => 'Slettede beskeder fjernes';

  @override
  String get showLoginNames => 'Vis loginnavne';

  @override
  String get loginNamesShown =>
      'Loginnavne vises, hvis de er forskellige fra visningsnavnet';

  @override
  String get loginNamesHidden => 'Loginnavne skjules';

  @override
  String get compactMessages => 'Forkort beskeder';

  @override
  String get dontCompactMessages => 'Forkort ikke beskeder';

  @override
  String get dontCompactMessagesSubtitle => 'Beskeder vises uændret';

  @override
  String get compactIndividualMessages => 'Forkort enkelte beskeder';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Gentagen tekst i beskeder forkortes';

  @override
  String get announcementPinDuration => 'Fastgørelsesvarighed for meddelelser';

  @override
  String get idleMessageAlertDuration => 'Lydalarm ved inaktiv chat';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Hvis der ikke er kommet beskeder i dette tidsrum, afspilles en lyd, når en ny besked ankommer.';

  @override
  String get realtimeCashSubtitle => 'Tilknyt en ETH- eller MATIC-wallet';

  @override
  String get walletAddress => 'Walletadresse';

  @override
  String get streamlabsSubtitle => 'Se dine Streamlabs-donationer';

  @override
  String get streamElementsSubtitle => 'Se dine StreamElements-donationer';

  @override
  String get thirdPartyAuthError =>
      'Hmm, det virkede ikke. Prøv igen, eller spørg på Discord.';

  @override
  String get companionAuthBrowserTooOld =>
      'Din browser er for gammel til direkte login. Scan QR-koden med din telefon for at logge ind på en anden enhed.';

  @override
  String get companionAuthScanQrCode =>
      'Scan QR-koden med din telefon for at logge ind på en anden enhed.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> har abonneret!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> har fornyet abonnementet i $monthsString måneder!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> har givet $countString abonnementer!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> sendte $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Log ind med Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Der er for mange beskeder. Tekst til tale er slået fra';

  @override
  String get turnOffTextToSpeech => 'Slå fra';

  @override
  String get addToChat => 'Føj til chat';

  @override
  String get inChat => 'I chatten';

  @override
  String get removeFromChat => 'Fjern fra chat';

  @override
  String cantChatWithAccount(String provider) {
    return 'Din $provider-konto kan ikke chatte her';
  }

  @override
  String get cantChatWithAccounts => 'Dine konti kan ikke chatte her';

  @override
  String sendAMessageTo(String channel) {
    return 'Send en besked til $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Skift til $channel';
  }

  @override
  String get voicePacks => 'Stemmepakker';

  @override
  String get voicePacksDescription =>
      'Stemmepakker læser chatten op med naturlige stemmer direkte på din enhed og fungerer offline efter download. Stemmerne er skabt af AI og ikke optaget af en person.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices stemmer',
      one: '1 stemme',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sprog',
      one: '1 sprog',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Modellens licens (OpenRAIL-M) forbyder skadelig brug, såsom at udgive sig for andre eller sprede misinformation. Disse begrænsninger gælder også dig.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Slet $pack? Det frigør $size.';
  }

  @override
  String get voicePackDownload => 'Download';

  @override
  String get voicePackUpdate => 'Opdater';

  @override
  String get voicePackWaitingForWifi => 'Venter på Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Brug mobildata';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Downloader: $downloaded af $total';
  }

  @override
  String get voicePackInstalling => 'Installerer';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Kunne ikke installere $pack. Kontrollér forbindelsen, og prøv igen.';
  }

  @override
  String get voices => 'Stemmer';

  @override
  String get perViewerVoice => 'En stemme pr. seer';

  @override
  String get perViewerVoiceSubtitle =>
      'Hver seer får sin egen stemme. Den valgte stemme læser notifikationer eller alt, når dette er slået fra.';

  @override
  String get streamLanguage => 'Streamens sprog';

  @override
  String get ttsEngineNeural => 'Neural stemme (på enheden)';

  @override
  String get ttsEngineSystem => 'Systemstemme';

  @override
  String languageUnsupported(String language) {
    return 'Dine stemmepakker understøtter ikke $language; systemstemmen bruges';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Denne enhed har ikke nok hukommelse til neurale stemmer, så chatten læses med systemstemmen.';

  @override
  String get neuralFallbackLoadFailed =>
      'Den neurale stemme kunne ikke indlæses, så chatten læses med systemstemmen.';

  @override
  String get accounts => 'Konti';

  @override
  String get accountsSubtitle => 'Log ind på hver platform, du streamer på';

  @override
  String addProviderAccount(String provider) {
    return 'Tilføj en $provider-konto';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Log ind med $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Log ud af $channel på $provider?';
  }

  @override
  String get signOutOfAll => 'Log ud af alle konti';
}
