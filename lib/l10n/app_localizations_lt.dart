// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class AppLocalizationsLt extends AppLocalizations {
  AppLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get sendAMessage => 'Siųsti žinutę...';

  @override
  String get writeSomething => 'Parašykite ką nors...';

  @override
  String get speakToTheCrowds => 'Prabilkite į minią...';

  @override
  String get shareYourThoughts => 'Pasidalykite savo mintimis...';

  @override
  String get saySomethingYouLittleBitch =>
      'Pasakyk ką nors, mažas kalės vaike...';

  @override
  String get search => 'Ieškoti';

  @override
  String get notSignedIn => 'Neprisijungta';

  @override
  String get searchChannels => 'Paieška';

  @override
  String get raidAChannel => 'Reidas';

  @override
  String get noMessagesEmptyState => 'Čia tylu.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count naujų žinučių',
      many: '$count naujos žinutės',
      few: '$count naujos žinutės',
      one: '$count nauja žinutė',
      zero: 'Naujų žinučių nėra',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Prisijungti per „Twitch“';

  @override
  String get signInError => 'Prisijungiant įvyko klaida. Bandykite dar kartą.';

  @override
  String get continueAsGuest => 'Tęsti kaip svečiui';

  @override
  String get signInToSendMessages =>
      'Prisijunkite, kad galėtumėte siųsti žinutes';

  @override
  String get currentViewers => 'Dabartiniai žiūrovai';

  @override
  String get textToSpeech => 'Tekstas į kalbą';

  @override
  String get streamPreview => 'Transliacijos peržiūra';

  @override
  String get activityFeed => 'Veiklos srautas';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Transliacija pradėta $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Transliacija baigta $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Pokalbis išvalytas $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Konfigūruoti greitąsias nuorodas';

  @override
  String get disableRainMode => 'Išjungti lietaus režimą';

  @override
  String get enableRainMode => 'Įjungti lietaus režimą';

  @override
  String get disableRainModeSubtitle => 'Sąveika bus įjungta';

  @override
  String get enableRainModeSubtitle => 'Sąveika bus išjungta';

  @override
  String get refreshAudioSources => 'Atnaujinti garso šaltinius';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Atnaujinta $count garso šaltinių',
      many: 'Atnaujinta $count garso šaltinio',
      few: 'Atnaujinti $count garso šaltiniai',
      one: 'Atnaujintas $count garso šaltinis',
      zero: 'Neatnaujintas joks garso šaltinis',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Nustatymai';

  @override
  String get signOut => 'Atsijungti';

  @override
  String get cancel => 'Atšaukti';

  @override
  String get signOutConfirmation => 'Ar tikrai norite atsijungti?';

  @override
  String get broadcaster => 'Transliuotojas';

  @override
  String get moderators => 'Moderatoriai';

  @override
  String get viewers => 'Žiūrovai';

  @override
  String get communityVips => 'Bendruomenės VIP nariai';

  @override
  String get searchViewers => 'Ieškoti žiūrovų';

  @override
  String get reconnecting => 'Jungiamasi iš naujo...';

  @override
  String get twitchBadges => '„Twitch“ ženkleliai';

  @override
  String get selectAll => 'Pažymėti viską';

  @override
  String get quickLinks => 'Greitosios nuorodos';

  @override
  String get swipeToDeleteQuickLinks =>
      'Perbraukite kairėn arba dešinėn, kad ištrintumėte greitąją nuorodą';

  @override
  String get quickLinksLabelHint => 'Etiketė';

  @override
  String get invalidUrlErrorText => 'Tai nepanašu į tinkamą URL';

  @override
  String get duplicateUrlErrorText => 'Ši nuoroda jau yra';

  @override
  String get or => 'arba';

  @override
  String get clearCookies => 'Išvalyti slapukus';

  @override
  String get disabled => 'Išjungta';

  @override
  String get twitchActivityFeed => '„Twitch“ veiklos srautas';

  @override
  String get signInToEnable => 'Norėdami tai įjungti, turite būti prisijungę';

  @override
  String get customUrl => 'Pasirinktinis URL';

  @override
  String get preview => 'Peržiūra';

  @override
  String get audioSources => 'Garso šaltiniai';

  @override
  String get enableOffStreamSwitchTitle =>
      'Įjungti ne transliacijos metu (naudoja daugiau akumuliatoriaus energijos)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Garsas bus leidžiamas ir tada, kai netransliuojate';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Garsas bus leidžiamas tik tada, kai transliuojate tiesiogiai';

  @override
  String get iosOggWarningTitle => 'Ei! Klausykite!';

  @override
  String get iosOggWarningSubtitle =>
      '„iOS“ nepalaiko *.ogg medijos failų, kurie yra numatytieji „Streamlabs“ failai. Įsitikinkite, kad jūsų garso šaltiniai naudoja kitą formatą, kitaip jie nebus atkuriami.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Tinkinkite savo veiklos srautą';

  @override
  String get audioSourcesSubtitle =>
      'Pridėkite žiniatinklio šaltinius įspėjimų garsams';

  @override
  String get quickLinksSubtitle =>
      'Pridėkite dažnai naudojamų įrankių sparčiąsias nuorodas';

  @override
  String get chatHistory => 'Pokalbių istorija';

  @override
  String get chatHistorySubtitle => 'Keiskite pokalbio išvaizdą';

  @override
  String get textToSpeechSubtitle => 'Keiskite teksto į kalbą nustatymus';

  @override
  String get events => 'Įvykiai';

  @override
  String get eventsSubtitle => 'Konfigūruokite „Twitch“ įvykius';

  @override
  String get thirdPartyServices => 'Trečiųjų šalių paslaugos';

  @override
  String get thirdPartyServicesSubtitle =>
      'Prisijunkite prie trečiosios šalies paslaugos';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> jus seka';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> ir <b>$displayNameTwo</b> jus seka';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> ir dar $numOthersString jus seka';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Įjungti garsą $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Nutildyti $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Laikinai apriboti $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Užblokuoti $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Atblokuoti $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Peržiūrėti $displayName profilį';
  }

  @override
  String get copyMessage => 'Kopijuoti žinutę';

  @override
  String get deleteMessage => 'Ištrinti žinutę';

  @override
  String get longScrollNotification => 'Slenkate gana toli, ar nemanote?';

  @override
  String get stfu => 'užsičiaupk';

  @override
  String get globalEmotes => 'Visuotiniai jaustukai';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString sekėjų',
      many: '$countString sekėjo',
      few: '$countString sekėjai',
      one: '$countString sekėjas',
      zero: '0 sekėjų',
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
      other: '$countString žiūrovų',
      many: '$countString žiūrovo',
      few: '$countString žiūrovai',
      one: '$countString žiūrovas',
      zero: '0 žiūrovų',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Sveiki! Džiaugiamės, kad mėgstate naudoti transliacijos peržiūrą, tačiau atminkite, kad ji eikvoja daug akumuliatoriaus energijos. Skaitant pokalbį be jos, akumuliatorius veiks ilgiau.';

  @override
  String get okay => 'Gerai';

  @override
  String get streamPreviewLoading => 'Įkeliama (arba transliacija nevyksta)...';

  @override
  String get copiedToClipboard => 'Nukopijuota į iškarpinę';

  @override
  String get audioSourcesRequirePermissions =>
      'Garso šaltiniams reikia leidimų';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Suteikite „RealtimeChat“ leidimą rodyti ant kitų programų, kad galėtumėte naudoti garso šaltinius.';

  @override
  String get audioSourcesRemoveButton => 'Pašalinti garso šaltinius';

  @override
  String get audioSourcesOpenSettingsButton => 'Atidaryti nustatymus';

  @override
  String get flashOn => 'Blykstė įjungta';

  @override
  String get flashOff => 'Blykstė išjungta';

  @override
  String get durationOneSecond => '1 sekundė';

  @override
  String get durationOneMinute => '1 minutė';

  @override
  String get durationTenMinutes => '10 minučių';

  @override
  String get durationOneHour => '1 valanda';

  @override
  String get durationSixHours => '6 valandos';

  @override
  String get durationOneDay => '1 diena';

  @override
  String get durationTwoDays => '2 dienos';

  @override
  String get durationOneWeek => '1 savaitė';

  @override
  String get durationTwoWeeks => '2 savaitės';

  @override
  String get durationOneSecondTimeoutPrompt => 'Laikinai apriboti 1 sekundei';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Laikinai apriboti 1 minutei';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Laikinai apriboti 10 minučių';

  @override
  String get durationOneHourTimeoutPrompt => 'Laikinai apriboti 1 valandai';

  @override
  String get durationSixHoursTimeoutPrompt => 'Laikinai apriboti 6 valandoms';

  @override
  String get durationOneDayTimeoutPrompt => 'Laikinai apriboti 1 dienai';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Laikinai apriboti 2 dienoms';

  @override
  String get durationOneWeekTimeoutPrompt => 'Laikinai apriboti 1 savaitei';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Laikinai apriboti 2 savaitėms';

  @override
  String get errorFetchingViewerList =>
      'Nepavyko gauti šio kanalo žiūrovų sąrašo';

  @override
  String get eventsTitle => 'Įvykiai';

  @override
  String get followEventConfigTitle => 'Sekimo įvykis';

  @override
  String get customizeYourFollowEvent => 'Tinkinkite sekimo įvykį';

  @override
  String get subscribeEventConfigTitle => 'Prenumeratos įvykis';

  @override
  String get customizeYourSubscriptionEvent => 'Tinkinkite prenumeratos įvykį';

  @override
  String get cheerEventConfigTitle => '„Cheer“ įvykis';

  @override
  String get customizeYourCheerEvent => 'Tinkinkite „Cheer“ įvykį';

  @override
  String get raidEventConfigTitle => 'Reido įvykis';

  @override
  String get customizeYourRaidEvent => 'Tinkinkite reido įvykį';

  @override
  String get hostEventConfigTitle => 'Vedimo („Host“) įvykis';

  @override
  String get customizeYourHostEvent => 'Tinkinkite vedimo („Host“) įvykį';

  @override
  String get hypetrainEventConfigTitle => '„Hype Train“ įvykis';

  @override
  String get customizeYourHypetrainEvent => 'Tinkinkite „Hype Train“ įvykį';

  @override
  String get pollEventConfigTitle => 'Apklausos įvykis';

  @override
  String get customizeYourPollEvent => 'Tinkinkite apklausos įvykį';

  @override
  String get predictionEventConfigTitle => 'Spėjimo įvykis';

  @override
  String get customizeYourPredictionEvent => 'Tinkinkite spėjimo įvykį';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Kanalo taškų išpirkimo įvykis';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Tinkinkite kanalo taškų išpirkimo įvykį';

  @override
  String get outgoingRaidEventConfigTitle => 'Siunčiamo reido įvykis';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Tinkinkite siunčiamo reido įvykį';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> vykdo reidą su <b>$viewerCountString</b> žiūrovų!';
  }

  @override
  String get shoutout => 'Paminėjimas';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Reidama pas <b>$displayName</b>...';
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
    return '<b>$displayName</b> įvykdė reidą!';
  }

  @override
  String get raidingEventJoin => 'Prisijungti';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> reidas atšauktas.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> užsiprenumeravo $tier pakopą!';
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

    return '<b>$gifterUserName</b> padovanojo $totalString $tier pakopos prenumeratų (iš viso $cumulativeTotalString)!';
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

    return '<b>$subscriberUserName</b> prenumeruoja $tier pakopą jau $cumulativeMonthsString mėn.!';
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

    return '<b>$subscriberUserName</b> užsiprenumeravo $tier pakopą $durationMonthsString mėn. į priekį (iš viso $cumulativeMonthsString mėn.)!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> paaukojo <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonimas paaukojo <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> paaukojo <b>$formattedAmount</b> per „StreamElements“.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> paaukojo <b>$formattedAmount</b> per „Streamlabs“.';
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

    return '<b>$redeemerUsername</b> išpirko <b>$rewardName</b> už <b>$rewardCostString</b> tšk. $userInput';
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

    return '<b>$redeemerUsername</b> išpirko <b>$rewardName</b> už <b>$rewardCostString</b> tšk.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> palaikė <b>$bitsString</b> bitais. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonimas';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> rodo kanalą su <b>$viewersString</b> žiūrovų grupe.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Vyksta <b>$level</b> lygio „Hype Train“! Įvykdyta <b>$progressPercent%</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return '<b>$levelString</b> lygio „Hype Train“ pavyko.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return '<b>$levelString</b> lygio „Hype Train“ nepavyko.';
  }

  @override
  String get sampleMessage =>
      'Tai pavyzdinis teksto vertimo į kalbą pranešimas.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author pasakė: $text';
  }

  @override
  String get textToSpeechEnabled => 'Tekstas į kalbą įjungtas';

  @override
  String get textToSpeechDisabled => 'Tekstas į kalbą išjungtas';

  @override
  String get alertsEnabled => 'Tik įspėjimai';

  @override
  String get pinDuration => 'Prisegimo trukmė';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekundžių',
      many: '$seconds sekundės',
      few: '$seconds sekundės',
      one: '$seconds sekundė',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minučių',
      many: '$minutes minutės',
      few: '$minutes minutės',
      one: '$minutes minutė',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Įjungti įvykį';

  @override
  String get showEventInChatHistory => 'Rodyti įvykį pokalbių istorijoje';

  @override
  String get enableShoutouts => 'Įjungti paminėjimus';

  @override
  String get enableShoutoutsSubtitle =>
      'Siųsti reidą vykdančio kanalo nuorodą į pokalbį';

  @override
  String get raidConfigurationTitle => 'Reido konfigūracija';

  @override
  String get cheerConfigurationTitle => '„Cheer“ konfigūracija';

  @override
  String get followConfigurationTitle => 'Sekimo konfigūracija';

  @override
  String get outgoingRaidConfigurationTitle => 'Siunčiamo reido konfigūracija';

  @override
  String get hostConfigurationTitle => 'Vedimo („Host“) konfigūracija';

  @override
  String get channelPointConfigurationTitle => 'Kanalo taškų konfigūracija';

  @override
  String get pollConfigurationTitle => 'Apklausos konfigūracija';

  @override
  String get hypetrainConfigurationTitle => '„Hype Train“ konfigūracija';

  @override
  String get subscriptionConfigurationTitle => 'Prenumeratos konfigūracija';

  @override
  String get predictionConfigurationTitle => 'Spėjimo konfigūracija';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Papildoma neįvykdytų apdovanojimų prisegimo trukmė';

  @override
  String get pollPinDuration => 'Prisegimo trukmė patvirtinus rezultatą';

  @override
  String get hypetrainPinDuration => 'Prisegimo trukmė pasibaigus „Hype Train“';

  @override
  String get enableGiftedSubscriptions =>
      'Įjungti pavienes dovanotas prenumeratas';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Rodyti kiekvieną padovanotą prenumeratą';

  @override
  String get settingsBackupTitle => 'Nustatymų atsarginė kopija ir atkūrimas';

  @override
  String get cloudBackup => 'Atsarginė kopija debesyje';

  @override
  String get lastBackupNever => 'Paskutinė atsarginė kopija: niekada';

  @override
  String get backUp => 'Kurti atsarginę kopiją';

  @override
  String get restore => 'Atkurti';

  @override
  String get localBackup => 'Vietinė atsarginė kopija';

  @override
  String get exportSettings => 'Eksportuoti';

  @override
  String get importSettings => 'Importuoti';

  @override
  String get showViewerAndFollowerCount => 'Rodyti žiūrovų ir sekėjų skaičių';

  @override
  String get screenOrientation => 'Ekrano orientacija';

  @override
  String get appTheme => 'Programos tema';

  @override
  String get systemDefault => 'Sistemos';

  @override
  String get portrait => 'Stačias';

  @override
  String get landscape => 'Gulsčias';

  @override
  String get lightTheme => 'Šviesi';

  @override
  String get darkTheme => 'Tamsi';

  @override
  String get openSourceTitle => '„RealtimeChat“ yra atvirojo kodo';

  @override
  String get openSourceSubtitle => 'Raskite mus „GitHub“!';

  @override
  String get discordSubtitle => 'Prisijunkite prie „Muxable“ „Discord“!';

  @override
  String get earlyTestersThanks =>
      'Ačiū visiems ankstyviesiems testuotojams, atsiuntusiems pranešimus apie klaidas!';

  @override
  String get discoModeEnabled => '🕺 Disko režimas įjungtas! :D';

  @override
  String get discoModeDisabled => '🕺 Disko režimas išjungtas D:';

  @override
  String get playSampleMessage => 'Leisti pavyzdinį pranešimą';

  @override
  String get textToSpeechRate => 'Teksto į kalbą greitis';

  @override
  String get textToSpeechPitch => 'Teksto į kalbą aukštis';

  @override
  String get muteBots => 'Nutildyti tekstą į kalbą robotams';

  @override
  String get muteEmotes => 'Nutildyti visus jaustukus skaitant tekstą balsu';

  @override
  String get muteViewerNames =>
      'Nutildyti žiūrovų vardus skaitant tekstą balsu';

  @override
  String get subscribersOnly => 'Tik prenumeratoriams';

  @override
  String get fontSize => 'Šrifto dydis';

  @override
  String get usernameContrastBoost => 'Naudotojo vardo kontrasto padidinimas';

  @override
  String get twitchBadgeSettings => '„Twitch“ ženklelių nustatymai';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Valdykite, kurie ženkleliai yra matomi';

  @override
  String get showDeletedMessages => 'Rodyti ištrintas žinutes';

  @override
  String get deletedMessagesGreyedOut => 'Ištrintos žinutės bus rodomos pilkai';

  @override
  String get deletedMessagesRemoved => 'Ištrintos žinutės bus pašalintos';

  @override
  String get showLoginNames => 'Rodyti prisijungimo vardus';

  @override
  String get loginNamesShown =>
      'Prisijungimo vardai bus rodomi, jei jie skiriasi nuo rodomo vardo';

  @override
  String get loginNamesHidden => 'Prisijungimo vardai bus paslėpti';

  @override
  String get compactMessages => 'Glaudinti žinutes';

  @override
  String get dontCompactMessages => 'Neglaudinti žinučių';

  @override
  String get dontCompactMessagesSubtitle => 'Žinutės rodomos nepakeistos';

  @override
  String get compactIndividualMessages => 'Glaudinti atskiras žinutes';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Pasikartojantis tekstas žinutėse sutrumpinamas';

  @override
  String get announcementPinDuration => 'Skelbimo prisegimo trukmė';

  @override
  String get idleMessageAlertDuration => 'Neaktyvaus pokalbio įspėjimo trukmė';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Jei šį laiką nebus jokių žinučių ir bus gauta nauja, pasigirs įspėjimo garsas.';

  @override
  String get realtimeCashSubtitle => 'Prijunkite ETH arba MATIC piniginę';

  @override
  String get walletAddress => 'Piniginės adresas';

  @override
  String get streamlabsSubtitle => 'Matykite savo „Streamlabs“ aukas';

  @override
  String get streamElementsSubtitle => 'Matykite savo „StreamElements“ aukas';

  @override
  String get thirdPartyAuthError =>
      'Hmm, nepavyko. Bandykite dar kartą arba paklauskite „Discord“?';

  @override
  String get companionAuthBrowserTooOld =>
      'Jūsų naršyklė per sena, kad palaikytų tiesioginį prisijungimą. Nuskaitykite šį QR kodą telefonu, kad prisijungtumėte kitame įrenginyje.';

  @override
  String get companionAuthScanQrCode =>
      'Nuskaitykite šį QR kodą telefonu, kad prisijungtumėte kitame įrenginyje.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> užsiprenumeravo!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> pratęsė prenumeratą ($monthsString mėn.)!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> padovanojo $countString prenumeratų!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> atsiuntė $amountString „Kicks“!';
  }

  @override
  String get signInWithKick => 'Prisijungti per „Kick“';

  @override
  String get textToSpeechTooManyMessages =>
      'Per daug žinučių. Tekstas į kalbą išjungtas';

  @override
  String get turnOffTextToSpeech => 'Išjungti';

  @override
  String get addToChat => 'Pridėti į pokalbį';

  @override
  String get inChat => 'Pokalbyje';

  @override
  String get removeFromChat => 'Pašalinti iš pokalbio';

  @override
  String cantChatWithAccount(String provider) {
    return 'Jūsų „$provider“ paskyra negali čia rašyti';
  }

  @override
  String get cantChatWithAccounts => 'Jūsų paskyros negali čia rašyti';

  @override
  String sendAMessageTo(String channel) {
    return 'Siųsti žinutę į $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Pakeisti $channel';
  }

  @override
  String get voicePacks => 'Balso paketai';

  @override
  String get voicePacksDescription =>
      'Balso paketai skaito pokalbį natūraliai skambančiais balsais, kurie veikia jūsų įrenginyje, o atsisiuntus – ir be interneto ryšio. Balsai yra sugeneruoti dirbtinio intelekto, o ne įrašyti žmogaus.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices balsų',
      many: '$voices balso',
      few: '$voices balsai',
      one: '$voices balsas',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kalbų',
      many: '$count kalbos',
      few: '$count kalbos',
      one: '$count kalba',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Šio modelio licencija (OpenRAIL-M) draudžia žalingą naudojimą, pavyzdžiui, apsimetinėjimą kitais žmonėmis ar dezinformacijos skleidimą, ir šie apribojimai taikomi ir jums.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Ištrinti „$pack“? Bus atlaisvinta $size.';
  }

  @override
  String get voicePackDownload => 'Atsisiųsti';

  @override
  String get voicePackUpdate => 'Atnaujinti';

  @override
  String get voicePackWaitingForWifi => 'Laukiama „Wi-Fi“ ryšio';

  @override
  String get voicePackUseMobileData => 'Naudoti mobiliuosius duomenis';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Atsisiunčiama: $downloaded iš $total';
  }

  @override
  String get voicePackInstalling => 'Diegiama';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Nepavyko įdiegti „$pack“. Patikrinkite ryšį ir bandykite dar kartą.';
  }

  @override
  String get voices => 'Balsai';

  @override
  String get perViewerVoice => 'Atskiras balsas kiekvienam žiūrovui';

  @override
  String get perViewerVoiceSubtitle =>
      'Kiekvienas žiūrovas gauna savo balsą. Jūsų pasirinktas balsas skaito įspėjimus arba viską, kai ši parinktis išjungta.';

  @override
  String get streamLanguage => 'Transliacijos kalba';

  @override
  String get ttsEngineNeural => 'Neuroninis balsas (įrenginyje)';

  @override
  String get ttsEngineSystem => 'Sistemos balsas';

  @override
  String languageUnsupported(String language) {
    return 'Jūsų balso paketai nepalaiko kalbos ($language); bus naudojamas sistemos balsas';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Šiame įrenginyje nepakanka atminties neuroniniams balsams, todėl pokalbis skaitomas sistemos balsu.';

  @override
  String get neuralFallbackLoadFailed =>
      'Nepavyko įkelti neuroninio balso, todėl pokalbis skaitomas sistemos balsu.';

  @override
  String get accounts => 'Paskyros';

  @override
  String get accountsSubtitle =>
      'Prisijunkite prie kiekvienos platformos, kurioje transliuojate';

  @override
  String addProviderAccount(String provider) {
    return 'Pridėti „$provider“ paskyrą';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Prisijungti per „$provider“';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Atsijungti nuo $channel platformoje „$provider“?';
  }

  @override
  String get signOutOfAll => 'Atsijungti nuo visų paskyrų';
}
