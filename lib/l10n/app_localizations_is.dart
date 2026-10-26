// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Icelandic (`is`).
class AppLocalizationsIs extends AppLocalizations {
  AppLocalizationsIs([String locale = 'is']) : super(locale);

  @override
  String get sendAMessage => 'Senda skilaboð...';

  @override
  String get writeSomething => 'Skrifaðu eitthvað...';

  @override
  String get speakToTheCrowds => 'Talaðu til fjöldans...';

  @override
  String get shareYourThoughts => 'Deildu hugsunum þínum...';

  @override
  String get saySomethingYouLittleBitch => 'Segðu eitthvað, litla tíkin þín...';

  @override
  String get search => 'Leita';

  @override
  String get notSignedIn => 'Ekki skráð(ur) inn';

  @override
  String get searchChannels => 'Leita';

  @override
  String get raidAChannel => 'Áhlaup';

  @override
  String get noMessagesEmptyState => 'Það er hljótt hérna inni.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ný skilaboð',
      one: '$count ný skilaboð',
      zero: 'Engin ný skilaboð',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Skrá inn með Twitch';

  @override
  String get signInError => 'Villa kom upp við innskráningu. Reyndu aftur.';

  @override
  String get continueAsGuest => 'Halda áfram sem gestur';

  @override
  String get signInToSendMessages => 'Skráðu þig inn til að senda skilaboð';

  @override
  String get currentViewers => 'Núverandi áhorfendur';

  @override
  String get textToSpeech => 'Talgervill';

  @override
  String get streamPreview => 'Forskoðun streymis';

  @override
  String get activityFeed => 'Virkniveita';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Streymi í loftinu $dateString, kl. $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Streymi óvirkt $dateString, kl. $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Spjall hreinsað $dateString, kl. $timeString';
  }

  @override
  String get configureQuickLinks => 'Stilla flýtitengla';

  @override
  String get disableRainMode => 'Slökkva á regnham';

  @override
  String get enableRainMode => 'Kveikja á regnham';

  @override
  String get disableRainModeSubtitle => 'Gagnvirkni verður virkjuð';

  @override
  String get enableRainModeSubtitle => 'Gagnvirkni verður óvirkjuð';

  @override
  String get refreshAudioSources => 'Endurhlaða hljóðgjafa';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hljóðgjafar endurhlaðnir',
      one: '$count hljóðgjafi endurhlaðinn',
      zero: 'Engir hljóðgjafar endurhlaðnir',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Stillingar';

  @override
  String get signOut => 'Skrá út';

  @override
  String get cancel => 'Hætta við';

  @override
  String get signOutConfirmation => 'Ertu viss um að þú viljir skrá þig út?';

  @override
  String get broadcaster => 'Streymandi';

  @override
  String get moderators => 'Stjórnendur';

  @override
  String get viewers => 'Áhorfendur';

  @override
  String get communityVips => 'VIP-meðlimir samfélagsins';

  @override
  String get searchViewers => 'Leita að áhorfendum';

  @override
  String get reconnecting => 'Endurtengist...';

  @override
  String get twitchBadges => 'Twitch-merki';

  @override
  String get selectAll => 'Velja allt';

  @override
  String get quickLinks => 'Flýtitenglar';

  @override
  String get swipeToDeleteQuickLinks =>
      'Strjúktu til vinstri eða hægri til að eyða flýtitengli';

  @override
  String get quickLinksLabelHint => 'Merki';

  @override
  String get invalidUrlErrorText =>
      'Þetta lítur ekki út fyrir að vera gilt URL';

  @override
  String get duplicateUrlErrorText => 'Þessi tengill er þegar til';

  @override
  String get or => 'eða';

  @override
  String get clearCookies => 'Hreinsa vafrakökur';

  @override
  String get disabled => 'Óvirkt';

  @override
  String get twitchActivityFeed => 'Virkniveita Twitch';

  @override
  String get signInToEnable =>
      'Þú verður að vera skráð(ur) inn til að virkja þetta';

  @override
  String get customUrl => 'Sérsniðið URL';

  @override
  String get preview => 'Forskoðun';

  @override
  String get audioSources => 'Hljóðgjafar';

  @override
  String get enableOffStreamSwitchTitle =>
      'Virkja utan streymis (notar meiri rafhlöðu)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Hljóð spilast líka þegar þú ert ekki í beinni';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Hljóð spilast aðeins þegar þú ert í beinni';

  @override
  String get iosOggWarningTitle => 'Heyrðu! Hlustaðu!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS styður ekki *.ogg margmiðlunarskrár, sem eru sjálfgefnar skrár á Streamlabs. Gakktu úr skugga um að hljóðgjafarnir þínir noti annað snið, annars spilast þeir ekki.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Sérsníddu virkniveituna þína';

  @override
  String get audioSourcesSubtitle =>
      'Bættu við vefgjöfum fyrir tilkynningarhljóð';

  @override
  String get quickLinksSubtitle =>
      'Bættu við flýtileiðum að algengum verkfærum';

  @override
  String get chatHistory => 'Spjallferill';

  @override
  String get chatHistorySubtitle => 'Breyta útliti spjallsins';

  @override
  String get textToSpeechSubtitle => 'Breyta stillingum talgervils';

  @override
  String get events => 'Viðburðir';

  @override
  String get eventsSubtitle => 'Stilla Twitch-viðburði';

  @override
  String get thirdPartyServices => 'Þjónustur þriðja aðila';

  @override
  String get thirdPartyServicesSubtitle => 'Tengjast þjónustu þriðja aðila';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> fylgir þér';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> og <b>$displayNameTwo</b> fylgja þér';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> og $numOthersString aðrir fylgja þér';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Afþagga $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Þagga $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Setja $displayName í tímabundið bann';
  }

  @override
  String banUser(String displayName) {
    return 'Banna $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Aflétta banni á $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Skoða prófíl $displayName';
  }

  @override
  String get copyMessage => 'Afrita skilaboð';

  @override
  String get deleteMessage => 'Eyða skilaboðum';

  @override
  String get longScrollNotification =>
      'Þú ert búin(n) að skrolla svolítið langt, finnst þér ekki?';

  @override
  String get stfu => 'þegiðu';

  @override
  String get globalEmotes => 'Alþjóðleg tjáningartákn';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString fylgjendur',
      one: '$countString fylgjandi',
      zero: '0 fylgjendur',
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
      other: '$countString áhorfendur',
      one: '$countString áhorfandi',
      zero: '0 áhorfendur',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Hæ! Gott að þú kannt vel við forskoðun streymis, en hafðu í huga að hún notar mikla rafhlöðu. Að lesa spjallið án hennar lengir endingu rafhlöðunnar.';

  @override
  String get okay => 'Í lagi';

  @override
  String get streamPreviewLoading => 'Hleður (eða streymi er óvirkt)...';

  @override
  String get copiedToClipboard => 'Afritað á klemmuspjald';

  @override
  String get audioSourcesRequirePermissions => 'Hljóðgjafar krefjast heimilda';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Samþykktu að RealtimeChat megi birtast yfir öðrum forritum til að nota hljóðgjafa.';

  @override
  String get audioSourcesRemoveButton => 'Fjarlægja hljóðgjafa';

  @override
  String get audioSourcesOpenSettingsButton => 'Opna stillingar';

  @override
  String get flashOn => 'Flass á';

  @override
  String get flashOff => 'Flass af';

  @override
  String get durationOneSecond => '1 sekúnda';

  @override
  String get durationOneMinute => '1 mínúta';

  @override
  String get durationTenMinutes => '10 mínútur';

  @override
  String get durationOneHour => '1 klukkustund';

  @override
  String get durationSixHours => '6 klukkustundir';

  @override
  String get durationOneDay => '1 dagur';

  @override
  String get durationTwoDays => '2 dagar';

  @override
  String get durationOneWeek => '1 vika';

  @override
  String get durationTwoWeeks => '2 vikur';

  @override
  String get durationOneSecondTimeoutPrompt => 'Tímabundið bann í 1 sekúndu';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Tímabundið bann í 1 mínútu';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Tímabundið bann í 10 mínútur';

  @override
  String get durationOneHourTimeoutPrompt => 'Tímabundið bann í 1 klukkustund';

  @override
  String get durationSixHoursTimeoutPrompt =>
      'Tímabundið bann í 6 klukkustundir';

  @override
  String get durationOneDayTimeoutPrompt => 'Tímabundið bann í 1 dag';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Tímabundið bann í 2 daga';

  @override
  String get durationOneWeekTimeoutPrompt => 'Tímabundið bann í 1 viku';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Tímabundið bann í 2 vikur';

  @override
  String get errorFetchingViewerList =>
      'Ekki tókst að sækja áhorfendalista fyrir þessa rás';

  @override
  String get eventsTitle => 'Viðburðir';

  @override
  String get followEventConfigTitle => 'Fylgiviðburður';

  @override
  String get customizeYourFollowEvent => 'Sérsníddu fylgiviðburðinn þinn';

  @override
  String get subscribeEventConfigTitle => 'Áskriftarviðburður';

  @override
  String get customizeYourSubscriptionEvent =>
      'Sérsníddu áskriftarviðburðinn þinn';

  @override
  String get cheerEventConfigTitle => 'Cheer-viðburður';

  @override
  String get customizeYourCheerEvent => 'Sérsníddu Cheer-viðburðinn þinn';

  @override
  String get raidEventConfigTitle => 'Áhlaupsviðburður';

  @override
  String get customizeYourRaidEvent => 'Sérsníddu áhlaupsviðburðinn þinn';

  @override
  String get hostEventConfigTitle => 'Hýsingarviðburður';

  @override
  String get customizeYourHostEvent => 'Sérsníddu hýsingarviðburðinn þinn';

  @override
  String get hypetrainEventConfigTitle => 'Hype Train-viðburður';

  @override
  String get customizeYourHypetrainEvent =>
      'Sérsníddu Hype Train-viðburðinn þinn';

  @override
  String get pollEventConfigTitle => 'Könnunarviðburður';

  @override
  String get customizeYourPollEvent => 'Sérsníddu könnunarviðburðinn þinn';

  @override
  String get predictionEventConfigTitle => 'Spáviðburður';

  @override
  String get customizeYourPredictionEvent => 'Sérsníddu spáviðburðinn þinn';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Viðburður innlausnar rásarstiga';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Sérsníddu viðburð innlausnar rásarstiga';

  @override
  String get outgoingRaidEventConfigTitle => 'Viðburður útleiðar áhlaups';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Sérsníddu viðburð útleiðar áhlaups';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> gerir áhlaup með <b>$viewerCountString</b> áhorfendur!';
  }

  @override
  String get shoutout => 'Kveðja';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Gerir áhlaup á <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString sek.';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> hefur gert áhlaup!';
  }

  @override
  String get raidingEventJoin => 'Taka þátt';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Hætt var við áhlaup <b>$displayName</b>.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> er komin(n) í áskrift á þrepi $tier!';
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

    return '<b>$gifterUserName</b> gaf $totalString áskriftir á þrepi $tier, samtals $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> hefur verið í áskrift í $cumulativeMonthsString mánuði á þrepi $tier!';
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

    return '<b>$subscriberUserName</b> hefur keypt áskrift á þrepi $tier í $durationMonthsString mánuði fyrir fram, samtals $cumulativeMonthsString mánuði!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> gaf <b>$value $currency</b> í þjórfé.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Nafnlaus gaf <b>$value $currency</b> í þjórfé.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> gaf <b>$formattedAmount</b> í þjórfé á StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> gaf <b>$formattedAmount</b> í þjórfé á Streamlabs.';
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

    return '<b>$redeemerUsername</b> leysti út <b>$rewardName</b> fyrir <b>$rewardCostString</b> stig. $userInput';
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

    return '<b>$redeemerUsername</b> leysti út <b>$rewardName</b> fyrir <b>$rewardCostString</b> stig.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> sendi Cheer með <b>$bitsString</b> bitum. $cheerMessage';
  }

  @override
  String get anonymous => 'Nafnlaus';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> hýsir með <b>$viewersString</b> áhorfendum.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train á stigi <b>$level</b> í gangi! <b>$progressPercent%</b> lokið!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train á stigi <b>$levelString</b> tókst.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train á stigi <b>$levelString</b> mistókst.';
  }

  @override
  String get sampleMessage => 'Þetta eru prufuskilaboð fyrir talgervil.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author sagði: $text';
  }

  @override
  String get textToSpeechEnabled => 'Talgervill virkur';

  @override
  String get textToSpeechDisabled => 'Talgervill óvirkur';

  @override
  String get alertsEnabled => 'Aðeins tilkynningar';

  @override
  String get pinDuration => 'Lengd festingar';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekúndur',
      one: '$seconds sekúnda',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes mínútur',
      one: '$minutes mínúta',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Virkja viðburð';

  @override
  String get showEventInChatHistory => 'Sýna viðburð í spjallferli';

  @override
  String get enableShoutouts => 'Virkja kveðjur';

  @override
  String get enableShoutoutsSubtitle =>
      'Senda tengil á rásina sem gerir áhlaup í spjallið';

  @override
  String get raidConfigurationTitle => 'Stillingar áhlaups';

  @override
  String get cheerConfigurationTitle => 'Stillingar Cheer';

  @override
  String get followConfigurationTitle => 'Stillingar fylgis';

  @override
  String get outgoingRaidConfigurationTitle => 'Stillingar útleiðar áhlaups';

  @override
  String get hostConfigurationTitle => 'Stillingar hýsingar';

  @override
  String get channelPointConfigurationTitle => 'Stillingar rásarstiga';

  @override
  String get pollConfigurationTitle => 'Stillingar könnunar';

  @override
  String get hypetrainConfigurationTitle => 'Stillingar Hype Train';

  @override
  String get subscriptionConfigurationTitle => 'Stillingar áskriftar';

  @override
  String get predictionConfigurationTitle => 'Stillingar spár';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Viðbótartími festingar fyrir óuppfyllt verðlaun';

  @override
  String get pollPinDuration =>
      'Lengd festingar eftir að niðurstaða liggur fyrir';

  @override
  String get hypetrainPinDuration =>
      'Lengd festingar eftir að Hype Train lýkur';

  @override
  String get enableGiftedSubscriptions => 'Virkja stakar gjafaáskriftir';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Sýna hverja áskrift sem er gefin';

  @override
  String get settingsBackupTitle => 'Öryggisafrit og endurheimt stillinga';

  @override
  String get cloudBackup => 'Skýjaafrit';

  @override
  String get lastBackupNever => 'Síðasta afrit: aldrei';

  @override
  String get backUp => 'Afrita';

  @override
  String get restore => 'Endurheimta';

  @override
  String get localBackup => 'Staðbundið afrit';

  @override
  String get exportSettings => 'Flytja út';

  @override
  String get importSettings => 'Flytja inn';

  @override
  String get showViewerAndFollowerCount => 'Sýna fjölda áhorfenda og fylgjenda';

  @override
  String get screenOrientation => 'Skjástefna';

  @override
  String get appTheme => 'Þema forrits';

  @override
  String get systemDefault => 'Kerfi';

  @override
  String get portrait => 'Lóðrétt';

  @override
  String get landscape => 'Lárétt';

  @override
  String get lightTheme => 'Ljóst';

  @override
  String get darkTheme => 'Dökkt';

  @override
  String get openSourceTitle => 'RealtimeChat er opinn hugbúnaður';

  @override
  String get openSourceSubtitle => 'Finndu okkur á GitHub!';

  @override
  String get discordSubtitle => 'Gakktu í Muxable Discord-þjóninn!';

  @override
  String get earlyTestersThanks =>
      'Þakkir til allra fyrstu prófaranna sem sendu villuskýrslur!';

  @override
  String get discoModeEnabled => '🕺 Diskóhamur virkjaður! :D';

  @override
  String get discoModeDisabled => '🕺 Diskóhamur óvirkjaður D:';

  @override
  String get playSampleMessage => 'Spila prufuskilaboð';

  @override
  String get textToSpeechRate => 'Hraði talgervils';

  @override
  String get textToSpeechPitch => 'Tónhæð talgervils';

  @override
  String get muteBots => 'Þagga talgervil fyrir vélmenni';

  @override
  String get muteEmotes => 'Þagga öll tjáningartákn í talgervli';

  @override
  String get muteViewerNames => 'Þagga nöfn áhorfenda í talgervli';

  @override
  String get subscribersOnly => 'Aðeins áskrifendur';

  @override
  String get fontSize => 'Leturstærð';

  @override
  String get usernameContrastBoost => 'Auka birtuskil notendanafna';

  @override
  String get twitchBadgeSettings => 'Stillingar Twitch-merkja';

  @override
  String get twitchBadgeSettingsSubtitle => 'Stjórnaðu hvaða merki eru sýnileg';

  @override
  String get showDeletedMessages => 'Sýna eydd skilaboð';

  @override
  String get deletedMessagesGreyedOut => 'Eydd skilaboð verða grá';

  @override
  String get deletedMessagesRemoved => 'Eydd skilaboð verða fjarlægð';

  @override
  String get showLoginNames => 'Sýna innskráningarnöfn';

  @override
  String get loginNamesShown =>
      'Innskráningarnöfn verða sýnd ef þau eru frábrugðin birtingarnafni';

  @override
  String get loginNamesHidden => 'Innskráningarnöfn verða falin';

  @override
  String get compactMessages => 'Þjappa skilaboðum';

  @override
  String get dontCompactMessages => 'Ekki þjappa skilaboðum';

  @override
  String get dontCompactMessagesSubtitle => 'Skilaboð birtast óbreytt';

  @override
  String get compactIndividualMessages => 'Þjappa stökum skilaboðum';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Endurtekinn texti í skilaboðum er styttur';

  @override
  String get announcementPinDuration => 'Lengd festingar tilkynninga';

  @override
  String get idleMessageAlertDuration =>
      'Biðtími tilkynningar við aðgerðaleysi í spjalli';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Ef engin skilaboð berast í þennan tíma og ný skilaboð koma inn mun tilkynningarhljóð spilast.';

  @override
  String get realtimeCashSubtitle => 'Tengdu ETH- eða MATIC-veski';

  @override
  String get walletAddress => 'Veskisfang';

  @override
  String get streamlabsSubtitle => 'Sjáðu Streamlabs-framlögin þín';

  @override
  String get streamElementsSubtitle => 'Sjáðu StreamElements-framlögin þín';

  @override
  String get thirdPartyAuthError =>
      'Hmm, þetta virkaði ekki. Reyndu aftur eða spurðu á Discord?';

  @override
  String get companionAuthBrowserTooOld =>
      'Vafrinn þinn er of gamall til að styðja beina innskráningu. Skannaðu þennan QR-kóða með símanum þínum til að skrá þig inn á öðru tæki.';

  @override
  String get companionAuthScanQrCode =>
      'Skannaðu þennan QR-kóða með símanum þínum til að skrá þig inn á öðru tæki.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> er komin(n) í áskrift!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> hefur endurnýjað áskrift í $monthsString mánuði!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> gaf $countString áskriftir!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> sendi $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Skrá inn með Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Það eru of mörg skilaboð. Talgervill óvirkjaður';

  @override
  String get turnOffTextToSpeech => 'Slökkva';

  @override
  String get addToChat => 'Bæta við spjall';

  @override
  String get inChat => 'Í spjalli';

  @override
  String get removeFromChat => 'Fjarlægja úr spjalli';

  @override
  String cantChatWithAccount(String provider) {
    return '$provider-reikningurinn þinn getur ekki spjallað hér';
  }

  @override
  String get cantChatWithAccounts =>
      'Reikningarnir þínir geta ekki spjallað hér';

  @override
  String sendAMessageTo(String channel) {
    return 'Senda skilaboð á $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Skipta út $channel';
  }

  @override
  String get voicePacks => 'Raddpakkar';

  @override
  String get voicePacksDescription =>
      'Raddpakkar lesa spjallið með eðlilegum röddum sem keyra á tækinu þínu, án nettengingar eftir niðurhal. Raddirnar eru búnar til með gervigreind, ekki teknar upp af manneskju.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices raddir',
      one: '$voices rödd',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tungumál',
      one: '$count tungumál',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Leyfi þessa líkans (OpenRAIL-M) bannar skaðlega notkun, svo sem að villa á sér heimildir eða dreifa falsupplýsingum, og þessar takmarkanir gilda einnig um þig.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Eyða $pack? Þetta losar $size.';
  }

  @override
  String get voicePackDownload => 'Sækja';

  @override
  String get voicePackUpdate => 'Uppfæra';

  @override
  String get voicePackWaitingForWifi => 'Bíður eftir Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Nota farsímagögn';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Sækir: $downloaded af $total';
  }

  @override
  String get voicePackInstalling => 'Setur upp';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Ekki tókst að setja upp $pack. Athugaðu tenginguna þína og reyndu aftur.';
  }

  @override
  String get voices => 'Raddir';

  @override
  String get perViewerVoice => 'Rödd á hvern áhorfanda';

  @override
  String get perViewerVoiceSubtitle =>
      'Hver áhorfandi fær sína eigin rödd. Röddin sem þú velur les tilkynningar, eða allt þegar slökkt er á þessu.';

  @override
  String get streamLanguage => 'Tungumál streymis';

  @override
  String get ttsEngineNeural => 'Taugarödd (á tæki)';

  @override
  String get ttsEngineSystem => 'Kerfisrödd';

  @override
  String languageUnsupported(String language) {
    return '$language er ekki stutt af raddpökkunum þínum; kerfisröddin verður notuð';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Þetta tæki hefur ekki nægt minni fyrir taugaraddir, svo spjallið er lesið með kerfisröddinni.';

  @override
  String get neuralFallbackLoadFailed =>
      'Ekki tókst að hlaða taugaröddinni, svo spjallið er lesið með kerfisröddinni.';

  @override
  String get accounts => 'Reikningar';

  @override
  String get accountsSubtitle =>
      'Skráðu þig inn á hvern vettvang sem þú streymir á';

  @override
  String addProviderAccount(String provider) {
    return 'Bæta við $provider-reikningi';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Skrá inn með $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Skrá út af $channel á $provider?';
  }

  @override
  String get signOutOfAll => 'Skrá út af öllum reikningum';
}
