// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'package:rtchat/l10n/app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Afrikaans (`af`).
class AppLocalizationsAf extends AppLocalizations {
  AppLocalizationsAf([String locale = 'af']) : super(locale);

  @override
  String get sendAMessage => 'Stuur \'n boodskap...';

  @override
  String get writeSomething => 'Skryf iets...';

  @override
  String get speakToTheCrowds => 'Praat met die skare...';

  @override
  String get shareYourThoughts => 'Deel jou gedagtes...';

  @override
  String get saySomethingYouLittleBitch => 'Sê iets, jou klein teef...';

  @override
  String get search => 'Soek';

  @override
  String get notSignedIn => 'Nie aangemeld nie';

  @override
  String get searchChannels => 'Soek kanale';

  @override
  String get raidAChannel => 'Raid \'n kanaal';

  @override
  String get noMessagesEmptyState => 'Dit is stil hier binne.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuwe boodskappe',
      one: '1 nuwe boodskap',
      zero: 'Geen nuwe boodskappe nie',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Meld aan met Twitch';

  @override
  String get signInError =>
      '\'n Fout het voorgekom tydens aanmelding. Probeer asseblief weer.';

  @override
  String get continueAsGuest => 'Gaan voort as gas';

  @override
  String get signInToSendMessages => 'Meld aan om boodskappe te stuur';

  @override
  String get currentViewers => 'Huidige kykers';

  @override
  String get textToSpeech => 'Teks-na-spraak';

  @override
  String get streamPreview => 'Stroomvoorskou';

  @override
  String get activityFeed => 'Aktiwiteitsvoer';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stroom aanlyn op $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stroom aflyn op $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Klets skoongemaak op $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Stel vinnige skakels op';

  @override
  String get disableRainMode => 'Deaktiveer reënmodus';

  @override
  String get enableRainMode => 'Aktiveer reënmodus';

  @override
  String get disableRainModeSubtitle => 'Interaksie sal geaktiveer word';

  @override
  String get enableRainModeSubtitle => 'Interaksie sal gedeaktiveer word';

  @override
  String get refreshAudioSources => 'Verfris oudiobronne';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oudiobronne verfris',
      one: '1 oudiobron verfris',
      zero: 'Geen oudiobronne verfris nie',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Instellings';

  @override
  String get signOut => 'Meld af';

  @override
  String get cancel => 'Kanselleer';

  @override
  String get signOutConfirmation => 'Is jy seker jy wil afmeld?';

  @override
  String get broadcaster => 'Uitsaaier';

  @override
  String get moderators => 'Moderateure';

  @override
  String get viewers => 'Kykers';

  @override
  String get communityVips => 'Gemeenskap-VIP\'s';

  @override
  String get searchViewers => 'Soek kykers';

  @override
  String get reconnecting => 'Herverbind tans...';

  @override
  String get twitchBadges => 'Twitch-kentekens';

  @override
  String get selectAll => 'Kies alles';

  @override
  String get quickLinks => 'Vinnige skakels';

  @override
  String get swipeToDeleteQuickLinks =>
      'Vee links of regs om vinnige skakel uit te vee';

  @override
  String get quickLinksLabelHint => 'Etiket';

  @override
  String get invalidUrlErrorText => 'Dit lyk nie soos \'n geldige URL nie';

  @override
  String get duplicateUrlErrorText => 'Hierdie skakel bestaan reeds';

  @override
  String get or => 'of';

  @override
  String get clearCookies => 'Vee koekies uit';

  @override
  String get disabled => 'Gedeaktiveer';

  @override
  String get twitchActivityFeed => 'Twitch-aktiwiteitsvoer';

  @override
  String get signInToEnable => 'Jy moet aangemeld wees om dit te aktiveer';

  @override
  String get customUrl => 'Pasgemaakte URL';

  @override
  String get preview => 'Voorskou';

  @override
  String get audioSources => 'Oudiobronne';

  @override
  String get enableOffStreamSwitchTitle =>
      'Aktiveer buite-stroom (gebruik meer battery)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Oudio sal ook speel wanneer jy aflyn is';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Oudio sal slegs speel wanneer jy regstreeks uitsaai';

  @override
  String get iosOggWarningTitle => 'Haai! Luister!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS ondersteun nie *.ogg-medialêers nie, wat die versteklêers op Streamlabs is. Maak seker dat jou oudiobronne \'n ander formaat gebruik, anders sal hulle nie speel nie.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Pasmaak jou aktiwiteitsvoer';

  @override
  String get audioSourcesSubtitle => 'Voeg webbronne by vir waarskuwingsklanke';

  @override
  String get quickLinksSubtitle =>
      'Voeg kortpaaie by na algemeen gebruikte hulpmiddels';

  @override
  String get chatHistory => 'Kletsgeskiedenis';

  @override
  String get chatHistorySubtitle => 'Verander die kletsvoorkoms';

  @override
  String get textToSpeechSubtitle => 'Verander teks-na-spraak-instellings';

  @override
  String get events => 'Gebeurtenisse';

  @override
  String get eventsSubtitle => 'Stel Twitch-gebeurtenisse op';

  @override
  String get thirdPartyServices => 'Derdepartydienste';

  @override
  String get thirdPartyServicesSubtitle => 'Koppel aan \'n derdepartydiens';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> volg jou nou';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> en <b>$displayNameTwo</b> volg jou nou';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> en $numOthersString ander volg jou nou';
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
    return 'Skors $displayName tydelik';
  }

  @override
  String banUser(String displayName) {
    return 'Verban $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Hef verbanning van $displayName op';
  }

  @override
  String viewProfile(String displayName) {
    return 'Bekyk $displayName se profiel';
  }

  @override
  String get copyMessage => 'Kopieer boodskap';

  @override
  String get deleteMessage => 'Vee boodskap uit';

  @override
  String get longScrollNotification =>
      'Jy rol nou nogal ver terug, dink jy nie?';

  @override
  String get stfu => 'hou jou bek';

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
      other: '$countString kykers',
      one: '1 kyker',
      zero: '0 kykers',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Haai daar! Bly jy hou daarvan om stroomvoorskou te gebruik, maar let daarop dat dit baie batterykrag gebruik. Om die klets daarsonder te lees sal jou batterylewe verleng.';

  @override
  String get okay => 'Reg so';

  @override
  String get streamPreviewLoading => 'Laai tans (of stroom is aflyn)...';

  @override
  String get copiedToClipboard => 'Na knipbord gekopieer';

  @override
  String get audioSourcesRequirePermissions =>
      'Oudiobronne vereis toestemmings';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Gee RealtimeChat toestemming om bo-oor ander toepassings te vertoon om oudiobronne te gebruik.';

  @override
  String get audioSourcesRemoveButton => 'Verwyder oudiobronne';

  @override
  String get audioSourcesOpenSettingsButton => 'Maak instellings oop';

  @override
  String get flashOn => 'Flits aan';

  @override
  String get flashOff => 'Flits af';

  @override
  String get durationOneSecond => '1 sekonde';

  @override
  String get durationOneMinute => '1 minuut';

  @override
  String get durationTenMinutes => '10 minute';

  @override
  String get durationOneHour => '1 uur';

  @override
  String get durationSixHours => '6 ure';

  @override
  String get durationOneDay => '1 dag';

  @override
  String get durationTwoDays => '2 dae';

  @override
  String get durationOneWeek => '1 week';

  @override
  String get durationTwoWeeks => '2 weke';

  @override
  String get durationOneSecondTimeoutPrompt => 'Skors tydelik vir 1 sekonde';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Skors tydelik vir 1 minuut';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Skors tydelik vir 10 minute';

  @override
  String get durationOneHourTimeoutPrompt => 'Skors tydelik vir 1 uur';

  @override
  String get durationSixHoursTimeoutPrompt => 'Skors tydelik vir 6 ure';

  @override
  String get durationOneDayTimeoutPrompt => 'Skors tydelik vir 1 dag';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Skors tydelik vir 2 dae';

  @override
  String get durationOneWeekTimeoutPrompt => 'Skors tydelik vir 1 week';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Skors tydelik vir 2 weke';

  @override
  String get errorFetchingViewerList =>
      'Ons kon nie die kykerslys vir hierdie kanaal ophaal nie';

  @override
  String get eventsTitle => 'Gebeurtenisse';

  @override
  String get followEventConfigTitle => 'Volg-gebeurtenis';

  @override
  String get customizeYourFollowEvent => 'Pasmaak jou volg-gebeurtenis';

  @override
  String get subscribeEventConfigTitle => 'Inteken-gebeurtenis';

  @override
  String get customizeYourSubscriptionEvent =>
      'Pasmaak jou inteken-gebeurtenis';

  @override
  String get cheerEventConfigTitle => 'Cheer-gebeurtenis';

  @override
  String get customizeYourCheerEvent => 'Pasmaak jou cheer-gebeurtenis';

  @override
  String get raidEventConfigTitle => 'Raid-gebeurtenis';

  @override
  String get customizeYourRaidEvent => 'Pasmaak jou raid-gebeurtenis';

  @override
  String get hostEventConfigTitle => 'Gasheer-gebeurtenis';

  @override
  String get customizeYourHostEvent => 'Pasmaak jou gasheer-gebeurtenis';

  @override
  String get hypetrainEventConfigTitle => 'Hype Train-gebeurtenis';

  @override
  String get customizeYourHypetrainEvent =>
      'Pasmaak jou Hype Train-gebeurtenis';

  @override
  String get pollEventConfigTitle => 'Meningspeiling-gebeurtenis';

  @override
  String get customizeYourPollEvent => 'Pasmaak jou meningspeiling-gebeurtenis';

  @override
  String get predictionEventConfigTitle => 'Voorspelling-gebeurtenis';

  @override
  String get customizeYourPredictionEvent =>
      'Pasmaak jou voorspelling-gebeurtenis';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Kanaalpunt-inlossingsgebeurtenis';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Pasmaak jou kanaalpunt-inlossingsgebeurtenis';

  @override
  String get outgoingRaidEventConfigTitle => 'Uitgaande raid-gebeurtenis';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Pasmaak jou uitgaande raid-gebeurtenis';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> voer \'n raid uit met <b>$viewerCountString</b> kykers!';
  }

  @override
  String get shoutout => 'Eervermelding';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Voer \'n raid uit op <b>$displayName</b>...';
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
    return '<b>$displayName</b> het \'n raid uitgevoer!';
  }

  @override
  String get raidingEventJoin => 'Sluit aan';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> se raid is gekanselleer.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> het op Vlak $tier ingeteken!';
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

    return '<b>$gifterUserName</b> het $totalString Vlak $tier-intekeninge geskenk, vir \'n totaal van $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> het vir $cumulativeMonthsString maande op Vlak $tier ingeteken!';
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

    return '<b>$subscriberUserName</b> het vir $durationMonthsString maande vooruit op Vlak $tier ingeteken, $cumulativeMonthsString maande in totaal!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> het \'n fooitjie van <b>$value $currency</b> gegee.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anoniem het \'n fooitjie van <b>$value $currency</b> gegee.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> het \'n fooitjie van <b>$formattedAmount</b> op StreamElements gegee.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> het \'n fooitjie van <b>$formattedAmount</b> op Streamlabs gegee.';
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

    return '<b>$redeemerUsername</b> het <b>$rewardName</b> vir <b>$rewardCostString</b> punte ingelos. $userInput';
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

    return '<b>$redeemerUsername</b> het <b>$rewardName</b> vir <b>$rewardCostString</b> punte ingelos.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> het <b>$bitsString</b> bits gecheer. $cheerMessage';
  }

  @override
  String get anonymous => 'Anoniem';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> tree op as gasheer met \'n groep van <b>$viewersString</b>.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train vlak <b>$level</b> aan die gang! <b>$progressPercent%</b> voltooi!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train vlak <b>$levelString</b> was suksesvol.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train vlak <b>$levelString</b> het misluk.';
  }

  @override
  String get sampleMessage =>
      'Hierdie is ’n voorbeeldboodskap vir teks-na-spraak.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author het gesê: $text';
  }

  @override
  String get textToSpeechEnabled => 'Teks-na-spraak geaktiveer';

  @override
  String get textToSpeechDisabled => 'Teks-na-spraak gedeaktiveer';

  @override
  String get alertsEnabled => 'Slegs waarskuwings';

  @override
  String get pinDuration => 'Vaspen-tydsduur';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekondes',
      one: '1 sekonde',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minute',
      one: '1 minuut',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Aktiveer gebeurtenis';

  @override
  String get showEventInChatHistory => 'Wys gebeurtenis in kletsgeskiedenis';

  @override
  String get enableShoutouts => 'Aktiveer eervermeldings';

  @override
  String get enableShoutoutsSubtitle =>
      'Stuur \'n skakel na die kanaal wat \'n raid uitvoer in die klets';

  @override
  String get raidConfigurationTitle => 'Raid-opstelling';

  @override
  String get cheerConfigurationTitle => 'Cheer-opstelling';

  @override
  String get followConfigurationTitle => 'Volg-opstelling';

  @override
  String get outgoingRaidConfigurationTitle => 'Uitgaande raid-opstelling';

  @override
  String get hostConfigurationTitle => 'Gasheer-opstelling';

  @override
  String get channelPointConfigurationTitle => 'Kanaalpunt-opstelling';

  @override
  String get pollConfigurationTitle => 'Meningspeiling-opstelling';

  @override
  String get hypetrainConfigurationTitle => 'Hype Train-opstelling';

  @override
  String get subscriptionConfigurationTitle => 'Intekening-opstelling';

  @override
  String get predictionConfigurationTitle => 'Voorspelling-opstelling';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Bykomende vaspen-tydsduur vir onvervulde belonings';

  @override
  String get pollPinDuration =>
      'Vaspen-tydsduur nadat die uitslag gefinaliseer is';

  @override
  String get hypetrainPinDuration =>
      'Vaspen-tydsduur nadat Hype Train verby is';

  @override
  String get enableGiftedSubscriptions =>
      'Aktiveer individuele geskenkte intekeninge';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Wys elke intekening wat geskenk word';

  @override
  String get settingsBackupTitle => 'Rugsteun en herstel van instellings';

  @override
  String get cloudBackup => 'Wolkrugsteun';

  @override
  String get lastBackupNever => 'Laaste rugsteun: nooit';

  @override
  String get backUp => 'Rugsteun';

  @override
  String get restore => 'Herstel';

  @override
  String get localBackup => 'Plaaslike rugsteun';

  @override
  String get exportSettings => 'Voer uit';

  @override
  String get importSettings => 'Voer in';

  @override
  String get showViewerAndFollowerCount => 'Wys kyker- en volgertal';

  @override
  String get screenOrientation => 'Skermoriëntasie';

  @override
  String get appTheme => 'Toepassingtema';

  @override
  String get systemDefault => 'Stelsel';

  @override
  String get portrait => 'Portret';

  @override
  String get landscape => 'Landskap';

  @override
  String get lightTheme => 'Lig';

  @override
  String get darkTheme => 'Donker';

  @override
  String get openSourceTitle => 'RealtimeChat is oopbron';

  @override
  String get openSourceSubtitle => 'Vind ons op GitHub!';

  @override
  String get discordSubtitle => 'Sluit aan by die Muxable Discord!';

  @override
  String get earlyTestersThanks =>
      'Dankie aan al die vroeë toetsers wat foutverslae gestuur het!';

  @override
  String get discoModeEnabled => '🕺 Diskomodus geaktiveer! :D';

  @override
  String get discoModeDisabled => '🕺 Diskomodus gedeaktiveer D:';

  @override
  String get playSampleMessage => 'Speel voorbeeldboodskap';

  @override
  String get textToSpeechRate => 'Teks-na-spraak-spoed';

  @override
  String get textToSpeechPitch => 'Teks-na-spraak-toonhoogte';

  @override
  String get muteBots => 'Demp teks-na-spraak vir botte';

  @override
  String get muteEmotes => 'Demp alle emotes in teks-na-spraak';

  @override
  String get muteViewerNames => 'Demp kykersname in teks-na-spraak';

  @override
  String get subscribersOnly => 'Slegs intekenare';

  @override
  String get fontSize => 'Lettergrootte';

  @override
  String get usernameContrastBoost => 'Gebruikernaam-kontrasversterking';

  @override
  String get twitchBadgeSettings => 'Twitch-kentekeninstellings';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Beheer watter kentekens sigbaar is';

  @override
  String get showDeletedMessages => 'Wys uitgeveëde boodskappe';

  @override
  String get deletedMessagesGreyedOut =>
      'Uitgeveëde boodskappe sal grys vertoon word';

  @override
  String get deletedMessagesRemoved =>
      'Uitgeveëde boodskappe sal verwyder word';

  @override
  String get showLoginNames => 'Wys aanmeldname';

  @override
  String get loginNamesShown =>
      'Aanmeldname sal gewys word as dit van die vertoonnaam verskil';

  @override
  String get loginNamesHidden => 'Aanmeldname sal versteek word';

  @override
  String get compactMessages => 'Kompakte boodskappe';

  @override
  String get dontCompactMessages => 'Moenie boodskappe kompak maak nie';

  @override
  String get dontCompactMessagesSubtitle => 'Boodskappe word onveranderd gewys';

  @override
  String get compactIndividualMessages => 'Maak individuele boodskappe kompak';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Herhalende teks in boodskappe word verkort';

  @override
  String get announcementPinDuration => 'Vaspen-tydsduur vir aankondigings';

  @override
  String get idleMessageAlertDuration =>
      'Tydsduur vir onaktiewe boodskapwaarskuwing';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'As daar vir hierdie tydperk geen boodskappe is nie en \'n nuwe een kom in, sal \'n waarskuwingsklank speel.';

  @override
  String get realtimeCashSubtitle => 'Koppel \'n ETH- of MATIC-beursie';

  @override
  String get walletAddress => 'Beursie-adres';

  @override
  String get streamlabsSubtitle => 'Sien jou Streamlabs-skenkings';

  @override
  String get streamElementsSubtitle => 'Sien jou StreamElements-skenkings';

  @override
  String get thirdPartyAuthError =>
      'Hmm, dit het nie gewerk nie. Probeer weer, of vra op Discord?';

  @override
  String get companionAuthBrowserTooOld =>
      'Jou blaaier is te oud om direkte aanmelding te ondersteun. Skandeer hierdie QR-kode met jou foon om op \'n ander toestel aan te meld.';

  @override
  String get companionAuthScanQrCode =>
      'Skandeer hierdie QR-kode met jou foon om op \'n ander toestel aan te meld.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> het ingeteken!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> het weer vir $monthsString maande ingeteken!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> het $countString intekeninge geskenk!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> het $amountString Kicks gestuur!';
  }

  @override
  String get signInWithKick => 'Meld aan met Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Daar is te veel boodskappe. Teks-na-spraak is gedeaktiveer';

  @override
  String get turnOffTextToSpeech => 'Skakel af';

  @override
  String get addToChat => 'Voeg by klets';

  @override
  String get inChat => 'In klets';

  @override
  String get removeFromChat => 'Verwyder uit klets';

  @override
  String cantChatWithAccount(String provider) {
    return 'Jou $provider-rekening kan nie hier klets nie';
  }

  @override
  String get cantChatWithAccounts => 'Jou rekeninge kan nie hier klets nie';

  @override
  String sendAMessageTo(String channel) {
    return 'Stuur \'n boodskap aan $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Vervang $channel';
  }

  @override
  String get voicePacks => 'Stempakkette';

  @override
  String get voicePacksDescription =>
      'Stempakkette lees die klets met natuurlik-klinkende stemme wat op jou toestel werk, aflyn sodra dit afgelaai is. Die stemme is masjien-gegenereer deur KI, nie deur \'n persoon opgeneem nie.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices stemme',
      one: '1 stem',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tale',
      one: '1 taal',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Hierdie model se lisensie (OpenRAIL-M) verbied skadelike gebruike, soos om mense na te boots of disinformasie te versprei, en hierdie beperkings geld ook vir jou.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Vee $pack uit? Dit stel $size vry.';
  }

  @override
  String get voicePackDownload => 'Laai af';

  @override
  String get voicePackUpdate => 'Dateer op';

  @override
  String get voicePackWaitingForWifi => 'Wag vir Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Gebruik mobiele data';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Laai tans af: $downloaded van $total';
  }

  @override
  String get voicePackInstalling => 'Installeer tans';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Kon nie $pack installeer nie. Gaan jou verbinding na en probeer weer.';
  }

  @override
  String get voices => 'Stemme';

  @override
  String get perViewerVoice => 'Stem per kyker';

  @override
  String get perViewerVoiceSubtitle =>
      'Elke kyker kry hul eie stem. Die stem wat jy kies lees waarskuwings, of alles wanneer dit af is.';

  @override
  String get streamLanguage => 'Stroomtaal';

  @override
  String get ttsEngineNeural => 'Neurale stem (op toestel)';

  @override
  String get ttsEngineSystem => 'Stelselstem';

  @override
  String languageUnsupported(String language) {
    return '$language word nie deur jou stempakkette ondersteun nie; die stelselstem sal gebruik word';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Hierdie toestel het nie genoeg geheue vir neurale stemme nie, daarom word die klets met die stelselstem gelees.';

  @override
  String get neuralFallbackLoadFailed =>
      'Die neurale stem kon nie laai nie, daarom word die klets met die stelselstem gelees.';

  @override
  String get accounts => 'Rekeninge';

  @override
  String get accountsSubtitle => 'Meld aan by elke platform waarop jy stroom';

  @override
  String addProviderAccount(String provider) {
    return 'Voeg $provider-rekening by';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Meld aan met $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Meld af by $channel op $provider?';
  }

  @override
  String get signOutOfAll => 'Meld af by alle rekeninge';
}
