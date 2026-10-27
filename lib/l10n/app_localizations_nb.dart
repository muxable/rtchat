// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'package:rtchat/l10n/app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get sendAMessage => 'Send en melding...';

  @override
  String get writeSomething => 'Skriv noe...';

  @override
  String get speakToTheCrowds => 'Tal til folkemengden...';

  @override
  String get shareYourThoughts => 'Del tankene dine...';

  @override
  String get saySomethingYouLittleBitch => 'Si noe, din lille tispe...';

  @override
  String get search => 'Søk';

  @override
  String get notSignedIn => 'Ikke pålogget';

  @override
  String get searchChannels => 'Søk etter kanaler';

  @override
  String get raidAChannel => 'Raid en kanal';

  @override
  String get noMessagesEmptyState => 'Det er stille her inne.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nye meldinger',
      one: '1 ny melding',
      zero: 'Ingen nye meldinger',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Logg inn med Twitch';

  @override
  String get signInError => 'Det oppstod en feil under innlogging. Prøv igjen.';

  @override
  String get continueAsGuest => 'Fortsett som gjest';

  @override
  String get signInToSendMessages => 'Logg inn for å sende meldinger';

  @override
  String get currentViewers => 'Nåværende seere';

  @override
  String get textToSpeech => 'Tekst til tale';

  @override
  String get streamPreview => 'Forhåndsvisning av strøm';

  @override
  String get activityFeed => 'Aktivitetsstrøm';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Strømmen gikk direkte $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Strømmen gikk av $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Chatten ble tømt $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Konfigurer hurtiglenker';

  @override
  String get disableRainMode => 'Deaktiver regnmodus';

  @override
  String get enableRainMode => 'Aktiver regnmodus';

  @override
  String get disableRainModeSubtitle => 'Interaksjon vil bli aktivert';

  @override
  String get enableRainModeSubtitle => 'Interaksjon vil bli deaktivert';

  @override
  String get refreshAudioSources => 'Oppdater lydkilder';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lydkilder oppdatert',
      one: '1 lydkilde oppdatert',
      zero: 'Ingen lydkilder oppdatert',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Innstillinger';

  @override
  String get signOut => 'Logg ut';

  @override
  String get cancel => 'Avbryt';

  @override
  String get signOutConfirmation => 'Er du sikker på at du vil logge ut?';

  @override
  String get broadcaster => 'Kringkaster';

  @override
  String get moderators => 'Moderatorer';

  @override
  String get viewers => 'Seere';

  @override
  String get communityVips => 'Fellesskaps-VIP-er';

  @override
  String get searchViewers => 'Søk etter seere';

  @override
  String get reconnecting => 'Kobler til på nytt...';

  @override
  String get twitchBadges => 'Twitch-merker';

  @override
  String get selectAll => 'Velg alle';

  @override
  String get quickLinks => 'Hurtiglenker';

  @override
  String get swipeToDeleteQuickLinks =>
      'Sveip til venstre eller høyre for å slette hurtiglenken';

  @override
  String get quickLinksLabelHint => 'Etikett';

  @override
  String get invalidUrlErrorText =>
      'Dette ser ikke ut som en gyldig nettadresse';

  @override
  String get duplicateUrlErrorText => 'Denne lenken finnes allerede';

  @override
  String get or => 'eller';

  @override
  String get clearCookies => 'Tøm informasjonskapsler';

  @override
  String get disabled => 'Deaktivert';

  @override
  String get twitchActivityFeed => 'Twitch-aktivitetsstrøm';

  @override
  String get signInToEnable => 'Du må være pålogget for å aktivere dette';

  @override
  String get customUrl => 'Egendefinert URL';

  @override
  String get preview => 'Forhåndsvisning';

  @override
  String get audioSources => 'Lydkilder';

  @override
  String get enableOffStreamSwitchTitle =>
      'Aktiver utenom strøm (bruker mer batteri)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Lyd spilles også av når du er frakoblet';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Lyd spilles bare av når du sender direkte';

  @override
  String get iosOggWarningTitle => 'Hei! Hør her!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS støtter ikke *.ogg-mediefiler, som er standardfilene på Streamlabs. Sørg for at lydkildene dine bruker et annet format, ellers spilles de ikke av.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Tilpass aktivitetsstrømmen din';

  @override
  String get audioSourcesSubtitle => 'Legg til nettkilder for varsellyder';

  @override
  String get quickLinksSubtitle => 'Legg til snarveier til ofte brukte verktøy';

  @override
  String get chatHistory => 'Chathistorikk';

  @override
  String get chatHistorySubtitle => 'Endre utseendet på chatten';

  @override
  String get textToSpeechSubtitle => 'Endre innstillinger for tekst til tale';

  @override
  String get events => 'Hendelser';

  @override
  String get eventsSubtitle => 'Konfigurer Twitch-hendelser';

  @override
  String get thirdPartyServices => 'Tredjepartstjenester';

  @override
  String get thirdPartyServicesSubtitle => 'Koble til en tredjepartstjeneste';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> følger deg';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> og <b>$displayNameTwo</b> følger deg';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> og $numOthersString andre følger deg';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Opphev demping av $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Demp $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Utesteng $displayName midlertidig';
  }

  @override
  String banUser(String displayName) {
    return 'Utesteng $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Opphev utestengelse av $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Vis profilen til $displayName';
  }

  @override
  String get copyMessage => 'Kopier melding';

  @override
  String get deleteMessage => 'Slett melding';

  @override
  String get longScrollNotification =>
      'Du ruller ganske langt tilbake, synes du ikke?';

  @override
  String get stfu => 'hold kjeft';

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
      'Hei der! Hyggelig at du liker forhåndsvisningen av strømmen, men vær obs på at den bruker mye batteri. Å lese chatten uten den vil forlenge batteritiden.';

  @override
  String get okay => 'Greit';

  @override
  String get streamPreviewLoading =>
      'Laster inn (eller strømmen er frakoblet)...';

  @override
  String get copiedToClipboard => 'Kopiert til utklippstavlen';

  @override
  String get audioSourcesRequirePermissions => 'Lydkilder krever tillatelser';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Gi RealtimeChat tillatelse til å vises over andre apper for å bruke lydkilder.';

  @override
  String get audioSourcesRemoveButton => 'Fjern lydkilder';

  @override
  String get audioSourcesOpenSettingsButton => 'Åpne innstillinger';

  @override
  String get flashOn => 'Blits på';

  @override
  String get flashOff => 'Blits av';

  @override
  String get durationOneSecond => '1 sekund';

  @override
  String get durationOneMinute => '1 minutt';

  @override
  String get durationTenMinutes => '10 minutter';

  @override
  String get durationOneHour => '1 time';

  @override
  String get durationSixHours => '6 timer';

  @override
  String get durationOneDay => '1 dag';

  @override
  String get durationTwoDays => '2 dager';

  @override
  String get durationOneWeek => '1 uke';

  @override
  String get durationTwoWeeks => '2 uker';

  @override
  String get durationOneSecondTimeoutPrompt =>
      'Utesteng midlertidig i 1 sekund';

  @override
  String get durationOneMinuteTimeoutPrompt =>
      'Utesteng midlertidig i 1 minutt';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      'Utesteng midlertidig i 10 minutter';

  @override
  String get durationOneHourTimeoutPrompt => 'Utesteng midlertidig i 1 time';

  @override
  String get durationSixHoursTimeoutPrompt => 'Utesteng midlertidig i 6 timer';

  @override
  String get durationOneDayTimeoutPrompt => 'Utesteng midlertidig i 1 dag';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Utesteng midlertidig i 2 dager';

  @override
  String get durationOneWeekTimeoutPrompt => 'Utesteng midlertidig i 1 uke';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Utesteng midlertidig i 2 uker';

  @override
  String get errorFetchingViewerList =>
      'Vi kunne ikke hente seerlisten for denne kanalen';

  @override
  String get eventsTitle => 'Hendelser';

  @override
  String get followEventConfigTitle => 'Følgehendelse';

  @override
  String get customizeYourFollowEvent => 'Tilpass følgehendelsen din';

  @override
  String get subscribeEventConfigTitle => 'Abonnementshendelse';

  @override
  String get customizeYourSubscriptionEvent =>
      'Tilpass abonnementshendelsen din';

  @override
  String get cheerEventConfigTitle => 'Cheer-hendelse';

  @override
  String get customizeYourCheerEvent => 'Tilpass cheer-hendelsen din';

  @override
  String get raidEventConfigTitle => 'Raid-hendelse';

  @override
  String get customizeYourRaidEvent => 'Tilpass raid-hendelsen din';

  @override
  String get hostEventConfigTitle => 'Vertshendelse';

  @override
  String get customizeYourHostEvent => 'Tilpass vertshendelsen din';

  @override
  String get hypetrainEventConfigTitle => 'Hype Train-hendelse';

  @override
  String get customizeYourHypetrainEvent => 'Tilpass Hype Train-hendelsen din';

  @override
  String get pollEventConfigTitle => 'Avstemningshendelse';

  @override
  String get customizeYourPollEvent => 'Tilpass avstemningshendelsen din';

  @override
  String get predictionEventConfigTitle => 'Spådomshendelse';

  @override
  String get customizeYourPredictionEvent => 'Tilpass spådomshendelsen din';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Hendelse for innløsning av kanalpoeng';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Tilpass hendelsen for innløsning av kanalpoeng';

  @override
  String get outgoingRaidEventConfigTitle => 'Utgående raid-hendelse';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Tilpass den utgående raid-hendelsen din';

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
  String get shoutout => 'Anbefaling';

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
  String get raidingEventJoin => 'Bli med';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Raidet til <b>$displayName</b> ble avbrutt.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> har abonnert på nivå $tier!';
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

    return '<b>$gifterUserName</b> har gitt $totalString abonnementer på nivå $tier i gave, totalt $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> har abonnert i $cumulativeMonthsString måneder på nivå $tier!';
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

    return '<b>$subscriberUserName</b> har abonnert på nivå $tier i $durationMonthsString måneder på forskudd, $cumulativeMonthsString måneder totalt!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> ga <b>$value $currency</b> i tips.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonym ga <b>$value $currency</b> i tips.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ga <b>$formattedAmount</b> i tips på StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ga <b>$formattedAmount</b> i tips på Streamlabs.';
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

    return '<b>$redeemerUsername</b> løste inn <b>$rewardName</b> for <b>$rewardCostString</b> poeng. $userInput';
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

    return '<b>$redeemerUsername</b> løste inn <b>$rewardName</b> for <b>$rewardCostString</b> poeng.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> cheeret <b>$bitsString</b> bits. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonym';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> er vert med en gruppe på <b>$viewersString</b>.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train nivå <b>$level</b> pågår! <b>$progressPercent%</b> fullført!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train nivå <b>$levelString</b> lyktes.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train nivå <b>$levelString</b> mislyktes.';
  }

  @override
  String get sampleMessage => 'Dette er en eksempelmelding for tekst til tale.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author sa: $text';
  }

  @override
  String get textToSpeechEnabled => 'Tekst til tale aktivert';

  @override
  String get textToSpeechDisabled => 'Tekst til tale deaktivert';

  @override
  String get alertsEnabled => 'Kun varsler';

  @override
  String get pinDuration => 'Festevarighet';

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
      one: '1 minutt',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Aktiver hendelse';

  @override
  String get showEventInChatHistory => 'Vis hendelse i chathistorikken';

  @override
  String get enableShoutouts => 'Aktiver anbefalinger';

  @override
  String get enableShoutoutsSubtitle =>
      'Send en lenke til kanalen som raider i chatten';

  @override
  String get raidConfigurationTitle => 'Raid-konfigurasjon';

  @override
  String get cheerConfigurationTitle => 'Cheer-konfigurasjon';

  @override
  String get followConfigurationTitle => 'Følgekonfigurasjon';

  @override
  String get outgoingRaidConfigurationTitle =>
      'Konfigurasjon for utgående raid';

  @override
  String get hostConfigurationTitle => 'Vertskonfigurasjon';

  @override
  String get channelPointConfigurationTitle => 'Kanalpoengkonfigurasjon';

  @override
  String get pollConfigurationTitle => 'Avstemningskonfigurasjon';

  @override
  String get hypetrainConfigurationTitle => 'Hype Train-konfigurasjon';

  @override
  String get subscriptionConfigurationTitle => 'Abonnementskonfigurasjon';

  @override
  String get predictionConfigurationTitle => 'Spådomskonfigurasjon';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Ekstra festevarighet for uinnfridde belønninger';

  @override
  String get pollPinDuration => 'Festevarighet etter at resultatet er klart';

  @override
  String get hypetrainPinDuration =>
      'Festevarighet etter at Hype Train er over';

  @override
  String get enableGiftedSubscriptions =>
      'Aktiver individuelle gaveabonnementer';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Vis hvert abonnement som gis i gave';

  @override
  String get settingsBackupTitle =>
      'Sikkerhetskopiering og gjenoppretting av innstillinger';

  @override
  String get cloudBackup => 'Skysikkerhetskopi';

  @override
  String get lastBackupNever => 'Siste sikkerhetskopi: aldri';

  @override
  String get backUp => 'Sikkerhetskopier';

  @override
  String get restore => 'Gjenopprett';

  @override
  String get localBackup => 'Lokal sikkerhetskopi';

  @override
  String get exportSettings => 'Eksporter';

  @override
  String get importSettings => 'Importer';

  @override
  String get showViewerAndFollowerCount => 'Vis antall seere og følgere';

  @override
  String get screenOrientation => 'Skjermretning';

  @override
  String get appTheme => 'Apptema';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get portrait => 'Stående';

  @override
  String get landscape => 'Liggende';

  @override
  String get lightTheme => 'Lys';

  @override
  String get darkTheme => 'Mørk';

  @override
  String get openSourceTitle => 'RealtimeChat har åpen kildekode';

  @override
  String get openSourceSubtitle => 'Finn oss på GitHub!';

  @override
  String get discordSubtitle => 'Bli med på Muxable Discord!';

  @override
  String get earlyTestersThanks =>
      'Takk til alle de tidlige testerne som sendte inn feilrapporter!';

  @override
  String get discoModeEnabled => '🕺 Diskomodus aktivert! :D';

  @override
  String get discoModeDisabled => '🕺 Diskomodus deaktivert D:';

  @override
  String get playSampleMessage => 'Spill av eksempelmelding';

  @override
  String get textToSpeechRate => 'Hastighet for tekst til tale';

  @override
  String get textToSpeechPitch => 'Tonehøyde for tekst til tale';

  @override
  String get muteBots => 'Demp tekst til tale for boter';

  @override
  String get muteEmotes => 'Demp alle emotes i tekst til tale';

  @override
  String get muteViewerNames => 'Demp seernavn i tekst til tale';

  @override
  String get subscribersOnly => 'Kun abonnenter';

  @override
  String get fontSize => 'Skriftstørrelse';

  @override
  String get usernameContrastBoost => 'Kontrastforsterkning for brukernavn';

  @override
  String get twitchBadgeSettings => 'Innstillinger for Twitch-merker';

  @override
  String get twitchBadgeSettingsSubtitle => 'Styr hvilke merker som er synlige';

  @override
  String get showDeletedMessages => 'Vis slettede meldinger';

  @override
  String get deletedMessagesGreyedOut => 'Slettede meldinger blir vist i grått';

  @override
  String get deletedMessagesRemoved => 'Slettede meldinger blir fjernet';

  @override
  String get showLoginNames => 'Vis brukernavn';

  @override
  String get loginNamesShown =>
      'Brukernavn vises hvis de er forskjellige fra visningsnavnet';

  @override
  String get loginNamesHidden => 'Brukernavn blir skjult';

  @override
  String get compactMessages => 'Komprimer meldinger';

  @override
  String get dontCompactMessages => 'Ikke komprimer meldinger';

  @override
  String get dontCompactMessagesSubtitle => 'Meldinger vises uendret';

  @override
  String get compactIndividualMessages => 'Komprimer enkeltmeldinger';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Gjentakende tekst i meldinger forkortes';

  @override
  String get announcementPinDuration => 'Festevarighet for kunngjøringer';

  @override
  String get idleMessageAlertDuration => 'Varslingsvarighet ved inaktiv chat';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Hvis det ikke kommer noen meldinger i løpet av denne tiden og en ny melding mottas, spilles det av en varsellyd.';

  @override
  String get realtimeCashSubtitle => 'Koble til en ETH- eller MATIC-lommebok';

  @override
  String get walletAddress => 'Lommebokadresse';

  @override
  String get streamlabsSubtitle => 'Se Streamlabs-donasjonene dine';

  @override
  String get streamElementsSubtitle => 'Se StreamElements-donasjonene dine';

  @override
  String get thirdPartyAuthError =>
      'Hmm, det fungerte ikke. Prøv igjen, eller spør på Discord?';

  @override
  String get companionAuthBrowserTooOld =>
      'Nettleseren din er for gammel til å støtte direkte innlogging. Skann denne QR-koden med telefonen din for å logge inn på en annen enhet.';

  @override
  String get companionAuthScanQrCode =>
      'Skann denne QR-koden med telefonen din for å logge inn på en annen enhet.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> har abonnert!';
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

    return '<b>$gifterName</b> har gitt $countString abonnementer i gave!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> sendte $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Logg inn med Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Det er for mange meldinger. Tekst til tale er deaktivert';

  @override
  String get turnOffTextToSpeech => 'Slå av';

  @override
  String get addToChat => 'Legg til i chat';

  @override
  String get inChat => 'I chatten';

  @override
  String get removeFromChat => 'Fjern fra chat';

  @override
  String cantChatWithAccount(String provider) {
    return '$provider-kontoen din kan ikke chatte her';
  }

  @override
  String get cantChatWithAccounts => 'Kontoene dine kan ikke chatte her';

  @override
  String sendAMessageTo(String channel) {
    return 'Send en melding til $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Erstatt $channel';
  }

  @override
  String get voicePacks => 'Stemmepakker';

  @override
  String get voicePacksDescription =>
      'Stemmepakker leser opp chatten med naturlige stemmer som kjører på enheten din, og fungerer frakoblet når de er lastet ned. Stemmene er maskingenerert av KI, ikke spilt inn av en person.';

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
      other: '$count språk',
      one: '1 språk',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Lisensen til denne modellen (OpenRAIL-M) forbyr skadelig bruk, som å utgi seg for å være andre personer eller spre desinformasjon, og disse begrensningene gjelder også for deg.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Slette $pack? Dette frigjør $size.';
  }

  @override
  String get voicePackDownload => 'Last ned';

  @override
  String get voicePackUpdate => 'Oppdater';

  @override
  String get voicePackWaitingForWifi => 'Venter på Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Bruk mobildata';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Laster ned: $downloaded av $total';
  }

  @override
  String get voicePackInstalling => 'Installerer';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Kunne ikke installere $pack. Sjekk tilkoblingen din og prøv igjen.';
  }

  @override
  String get voices => 'Stemmer';

  @override
  String get perViewerVoice => 'Stemme per seer';

  @override
  String get perViewerVoiceSubtitle =>
      'Hver seer får sin egen stemme. Stemmen du velger leser opp varsler, eller alt når dette er slått av.';

  @override
  String get streamLanguage => 'Strømspråk';

  @override
  String get ttsEngineNeural => 'Nevral stemme (på enheten)';

  @override
  String get ttsEngineSystem => 'Systemstemme';

  @override
  String languageUnsupported(String language) {
    return '$language støttes ikke av stemmepakkene dine; systemstemmen vil bli brukt';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Denne enheten har ikke nok minne for nevrale stemmer, så chatten leses opp med systemstemmen.';

  @override
  String get neuralFallbackLoadFailed =>
      'Den nevrale stemmen kunne ikke lastes inn, så chatten leses opp med systemstemmen.';

  @override
  String get accounts => 'Kontoer';

  @override
  String get accountsSubtitle => 'Logg inn på hver plattform du strømmer på';

  @override
  String addProviderAccount(String provider) {
    return 'Legg til $provider-konto';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Logg inn med $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Logge ut av $channel på $provider?';
  }

  @override
  String get signOutOfAll => 'Logg ut av alle kontoer';
}
