// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class AppLocalizationsEt extends AppLocalizations {
  AppLocalizationsEt([String locale = 'et']) : super(locale);

  @override
  String get sendAMessage => 'Saada sõnum...';

  @override
  String get writeSomething => 'Kirjuta midagi...';

  @override
  String get speakToTheCrowds => 'Kõnele rahvahulkadele...';

  @override
  String get shareYourThoughts => 'Jaga oma mõtteid...';

  @override
  String get saySomethingYouLittleBitch => 'Ütle midagi, sa väike lits...';

  @override
  String get search => 'Otsi';

  @override
  String get notSignedIn => 'Pole sisse logitud';

  @override
  String get searchChannels => 'Otsi';

  @override
  String get raidAChannel => 'Reidi';

  @override
  String get noMessagesEmptyState => 'Siin on vaikne.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uut sõnumit',
      one: '$count uus sõnum',
      zero: 'Uusi sõnumeid pole',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Logi sisse Twitchiga';

  @override
  String get signInError => 'Sisselogimisel ilmnes viga. Palun proovi uuesti.';

  @override
  String get continueAsGuest => 'Jätka külalisena';

  @override
  String get signInToSendMessages => 'Sõnumite saatmiseks logi sisse';

  @override
  String get currentViewers => 'Praegused vaatajad';

  @override
  String get textToSpeech => 'Kõnesüntees';

  @override
  String get streamPreview => 'Ülekande eelvaade';

  @override
  String get activityFeed => 'Tegevuste voog';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Ülekanne algas $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Ülekanne lõppes $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Vestlus tühjendati $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Seadista kiirlingid';

  @override
  String get disableRainMode => 'Keela vihmarežiim';

  @override
  String get enableRainMode => 'Luba vihmarežiim';

  @override
  String get disableRainModeSubtitle => 'Puutetoimingud lubatakse';

  @override
  String get enableRainModeSubtitle => 'Puutetoimingud keelatakse';

  @override
  String get refreshAudioSources => 'Värskenda heliallikaid';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heliallikat värskendati',
      one: '$count heliallikas värskendati',
      zero: 'Ühtegi heliallikat ei värskendatud',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Seaded';

  @override
  String get signOut => 'Logi välja';

  @override
  String get cancel => 'Tühista';

  @override
  String get signOutConfirmation => 'Kas oled kindel, et soovid välja logida?';

  @override
  String get broadcaster => 'Striimer';

  @override
  String get moderators => 'Moderaatorid';

  @override
  String get viewers => 'Vaatajad';

  @override
  String get communityVips => 'Kogukonna VIP-id';

  @override
  String get searchViewers => 'Otsi vaatajaid';

  @override
  String get reconnecting => 'Taasühendamine...';

  @override
  String get twitchBadges => 'Twitchi märgid';

  @override
  String get selectAll => 'Vali kõik';

  @override
  String get quickLinks => 'Kiirlingid';

  @override
  String get swipeToDeleteQuickLinks =>
      'Kiirlingi kustutamiseks libista vasakule või paremale';

  @override
  String get quickLinksLabelHint => 'Silt';

  @override
  String get invalidUrlErrorText => 'See ei tundu olevat kehtiv URL';

  @override
  String get duplicateUrlErrorText => 'See link on juba olemas';

  @override
  String get or => 'või';

  @override
  String get clearCookies => 'Kustuta küpsised';

  @override
  String get disabled => 'Keelatud';

  @override
  String get twitchActivityFeed => 'Twitchi tegevuste voog';

  @override
  String get signInToEnable => 'Selle lubamiseks pead olema sisse logitud';

  @override
  String get customUrl => 'Kohandatud URL';

  @override
  String get preview => 'Eelvaade';

  @override
  String get audioSources => 'Heliallikad';

  @override
  String get enableOffStreamSwitchTitle =>
      'Luba väljaspool ülekannet (kulutab rohkem akut)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Heli esitatakse ka siis, kui sa pole otse-eetris';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Heli esitatakse ainult siis, kui oled otse-eetris';

  @override
  String get iosOggWarningTitle => 'Hei! Kuula!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS ei toeta *.ogg meediafaile, mis on Streamlabsis vaikimisi kasutusel. Veendu, et sinu heliallikad kasutaksid mõnda muud vormingut, muidu neid ei esitata.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Kohanda oma tegevuste voogu';

  @override
  String get audioSourcesSubtitle => 'Lisa veebiallikaid märguandehelide jaoks';

  @override
  String get quickLinksSubtitle =>
      'Lisa otseteid sageli kasutatavatele tööriistadele';

  @override
  String get chatHistory => 'Vestluse ajalugu';

  @override
  String get chatHistorySubtitle => 'Muuda vestluse välimust';

  @override
  String get textToSpeechSubtitle => 'Muuda kõnesünteesi seadeid';

  @override
  String get events => 'Sündmused';

  @override
  String get eventsSubtitle => 'Seadista Twitchi sündmusi';

  @override
  String get thirdPartyServices => 'Kolmanda osapoole teenused';

  @override
  String get thirdPartyServicesSubtitle => 'Ühenda kolmanda osapoole teenusega';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> jälgib sind';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> ja <b>$displayNameTwo</b> jälgivad sind';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> ja veel $numOthersString jälgivad sind';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Tühista kasutaja $displayName vaigistus';
  }

  @override
  String muteUser(String displayName) {
    return 'Vaigista $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Keela ajutiselt $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Blokeeri $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Eemalda kasutaja $displayName blokeering';
  }

  @override
  String viewProfile(String displayName) {
    return 'Vaata kasutaja $displayName profiili';
  }

  @override
  String get copyMessage => 'Kopeeri sõnum';

  @override
  String get deleteMessage => 'Kustuta sõnum';

  @override
  String get longScrollNotification => 'Sa kerid juba päris kaugele, kas pole?';

  @override
  String get stfu => 'ole vait';

  @override
  String get globalEmotes => 'Üldised emotikonid';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString jälgijat',
      one: '$countString jälgija',
      zero: '0 jälgijat',
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
      other: '$countString vaatajat',
      one: '$countString vaataja',
      zero: '0 vaatajat',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Hei! Tore, et sulle meeldib ülekande eelvaadet kasutada, kuid pea meeles, et see kulutab palju akut. Vestluse lugemine ilma selleta pikendab aku kestvust.';

  @override
  String get okay => 'Olgu';

  @override
  String get streamPreviewLoading => 'Laadimine (või ülekanne pole eetris)...';

  @override
  String get copiedToClipboard => 'Lõikelauale kopeeritud';

  @override
  String get audioSourcesRequirePermissions => 'Heliallikad vajavad luba';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Luba rakendusel RealtimeChat kuvada teiste rakenduste peal, et kasutada heliallikaid.';

  @override
  String get audioSourcesRemoveButton => 'Eemalda heliallikad';

  @override
  String get audioSourcesOpenSettingsButton => 'Ava seaded';

  @override
  String get flashOn => 'Välk sees';

  @override
  String get flashOff => 'Välk väljas';

  @override
  String get durationOneSecond => '1 sekund';

  @override
  String get durationOneMinute => '1 minut';

  @override
  String get durationTenMinutes => '10 minutit';

  @override
  String get durationOneHour => '1 tund';

  @override
  String get durationSixHours => '6 tundi';

  @override
  String get durationOneDay => '1 päev';

  @override
  String get durationTwoDays => '2 päeva';

  @override
  String get durationOneWeek => '1 nädal';

  @override
  String get durationTwoWeeks => '2 nädalat';

  @override
  String get durationOneSecondTimeoutPrompt => 'Keela 1 sekundiks';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Keela 1 minutiks';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Keela 10 minutiks';

  @override
  String get durationOneHourTimeoutPrompt => 'Keela 1 tunniks';

  @override
  String get durationSixHoursTimeoutPrompt => 'Keela 6 tunniks';

  @override
  String get durationOneDayTimeoutPrompt => 'Keela 1 päevaks';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Keela 2 päevaks';

  @override
  String get durationOneWeekTimeoutPrompt => 'Keela 1 nädalaks';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Keela 2 nädalaks';

  @override
  String get errorFetchingViewerList =>
      'Selle kanali vaatajate nimekirja ei õnnestunud laadida';

  @override
  String get eventsTitle => 'Sündmused';

  @override
  String get followEventConfigTitle => 'Jälgimissündmus';

  @override
  String get customizeYourFollowEvent => 'Kohanda oma jälgimissündmust';

  @override
  String get subscribeEventConfigTitle => 'Tellimissündmus';

  @override
  String get customizeYourSubscriptionEvent => 'Kohanda oma tellimissündmust';

  @override
  String get cheerEventConfigTitle => 'Cheer-sündmus';

  @override
  String get customizeYourCheerEvent => 'Kohanda oma Cheer-sündmust';

  @override
  String get raidEventConfigTitle => 'Reidisündmus';

  @override
  String get customizeYourRaidEvent => 'Kohanda oma reidisündmust';

  @override
  String get hostEventConfigTitle => 'Hostimissündmus';

  @override
  String get customizeYourHostEvent => 'Kohanda oma hostimissündmust';

  @override
  String get hypetrainEventConfigTitle => 'Hype Traini sündmus';

  @override
  String get customizeYourHypetrainEvent => 'Kohanda oma Hype Traini sündmust';

  @override
  String get pollEventConfigTitle => 'Küsitlussündmus';

  @override
  String get customizeYourPollEvent => 'Kohanda oma küsitlussündmust';

  @override
  String get predictionEventConfigTitle => 'Ennustussündmus';

  @override
  String get customizeYourPredictionEvent => 'Kohanda oma ennustussündmust';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Kanalipunktide lunastamise sündmus';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Kohanda oma kanalipunktide lunastamise sündmust';

  @override
  String get outgoingRaidEventConfigTitle => 'Väljamineva reidi sündmus';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Kohanda oma väljamineva reidi sündmust';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> reidib <b>$viewerCountString</b> vaatajaga!';
  }

  @override
  String get shoutout => 'Tervitus';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Kasutaja <b>$displayName</b> reidimine...';
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
    return '<b>$displayName</b> reiditi!';
  }

  @override
  String get raidingEventJoin => 'Liitu';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Kasutaja <b>$displayName</b> reid tühistati.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> tellis $tier. tasemel!';
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

    return '<b>$gifterUserName</b> kinkis $totalString $tier. taseme tellimust, kokku $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> on tellinud $cumulativeMonthsString kuud $tier. tasemel!';
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

    return '<b>$subscriberUserName</b> tellis $tier. tasemel $durationMonthsString kuuks ette, kokku $cumulativeMonthsString kuud!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> andis jootraha <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonüümne kasutaja andis jootraha <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> andis StreamElementsis jootraha <b>$formattedAmount</b>.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> andis Streamlabsis jootraha <b>$formattedAmount</b>.';
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

    return '<b>$redeemerUsername</b> lunastas preemia <b>$rewardName</b> <b>$rewardCostString</b> punkti eest. $userInput';
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

    return '<b>$redeemerUsername</b> lunastas preemia <b>$rewardName</b> <b>$rewardCostString</b> punkti eest.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> saatis <b>$bitsString</b> bitti. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonüümne';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> hostib <b>$viewersString</b> vaatajaga.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Traini <b>$level</b>. tase on käimas! <b>$progressPercent%</b> täidetud!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Traini <b>$levelString</b>. tase õnnestus.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Traini <b>$levelString</b>. tase ebaõnnestus.';
  }

  @override
  String get sampleMessage => 'See on kõnesünteesi näidissõnum.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author ütles: $text';
  }

  @override
  String get textToSpeechEnabled => 'Kõnesüntees lubatud';

  @override
  String get textToSpeechDisabled => 'Kõnesüntees keelatud';

  @override
  String get alertsEnabled => 'Ainult märguanded';

  @override
  String get pinDuration => 'Kinnitamise kestus';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekundit',
      one: '$seconds sekund',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutit',
      one: '$minutes minut',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Luba sündmus';

  @override
  String get showEventInChatHistory => 'Kuva sündmust vestluse ajaloos';

  @override
  String get enableShoutouts => 'Luba tervitused';

  @override
  String get enableShoutoutsSubtitle => 'Saada reidiva kanali link vestlusesse';

  @override
  String get raidConfigurationTitle => 'Reidi seadistus';

  @override
  String get cheerConfigurationTitle => 'Cheeri seadistus';

  @override
  String get followConfigurationTitle => 'Jälgimise seadistus';

  @override
  String get outgoingRaidConfigurationTitle => 'Väljamineva reidi seadistus';

  @override
  String get hostConfigurationTitle => 'Hostimise seadistus';

  @override
  String get channelPointConfigurationTitle => 'Kanalipunktide seadistus';

  @override
  String get pollConfigurationTitle => 'Küsitluse seadistus';

  @override
  String get hypetrainConfigurationTitle => 'Hype Traini seadistus';

  @override
  String get subscriptionConfigurationTitle => 'Tellimuse seadistus';

  @override
  String get predictionConfigurationTitle => 'Ennustuse seadistus';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Täitmata preemiate lisakinnitusaeg';

  @override
  String get pollPinDuration => 'Kinnitamise kestus pärast tulemuse selgumist';

  @override
  String get hypetrainPinDuration =>
      'Kinnitamise kestus pärast Hype Traini lõppu';

  @override
  String get enableGiftedSubscriptions => 'Luba üksikud kingitud tellimused';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Kuva iga kingitud tellimus eraldi';

  @override
  String get settingsBackupTitle => 'Seadete varundamine ja taastamine';

  @override
  String get cloudBackup => 'Pilvevarundus';

  @override
  String get lastBackupNever => 'Viimane varundus: mitte kunagi';

  @override
  String get backUp => 'Varunda';

  @override
  String get restore => 'Taasta';

  @override
  String get localBackup => 'Kohalik varundus';

  @override
  String get exportSettings => 'Ekspordi';

  @override
  String get importSettings => 'Impordi';

  @override
  String get showViewerAndFollowerCount => 'Kuva vaatajate ja jälgijate arvu';

  @override
  String get screenOrientation => 'Ekraani paigutus';

  @override
  String get appTheme => 'Rakenduse teema';

  @override
  String get systemDefault => 'Süsteemne';

  @override
  String get portrait => 'Vertikaalne';

  @override
  String get landscape => 'Horisontaalne';

  @override
  String get lightTheme => 'Hele';

  @override
  String get darkTheme => 'Tume';

  @override
  String get openSourceTitle => 'RealtimeChat on avatud lähtekoodiga';

  @override
  String get openSourceSubtitle => 'Leia meid GitHubist!';

  @override
  String get discordSubtitle => 'Liitu Muxable\'i Discordiga!';

  @override
  String get earlyTestersThanks =>
      'Aitäh kõigile varajastele testijatele, kes saatsid veateateid!';

  @override
  String get discoModeEnabled => '🕺 Diskorežiim lubatud! :D';

  @override
  String get discoModeDisabled => '🕺 Diskorežiim keelatud D:';

  @override
  String get playSampleMessage => 'Esita näidissõnum';

  @override
  String get textToSpeechRate => 'Kõnesünteesi kiirus';

  @override
  String get textToSpeechPitch => 'Kõnesünteesi helikõrgus';

  @override
  String get muteBots => 'Vaigista kõnesüntees robotite puhul';

  @override
  String get muteEmotes => 'Vaigista kõnesünteesis kõik emotikonid';

  @override
  String get muteViewerNames => 'Vaigista kõnesünteesis vaatajate nimed';

  @override
  String get subscribersOnly => 'Ainult tellijad';

  @override
  String get fontSize => 'Fondi suurus';

  @override
  String get usernameContrastBoost => 'Kasutajanime kontrastsuse võimendus';

  @override
  String get twitchBadgeSettings => 'Twitchi märkide seaded';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Määra, millised märgid on nähtavad';

  @override
  String get showDeletedMessages => 'Kuva kustutatud sõnumeid';

  @override
  String get deletedMessagesGreyedOut => 'Kustutatud sõnumid kuvatakse hallina';

  @override
  String get deletedMessagesRemoved => 'Kustutatud sõnumid eemaldatakse';

  @override
  String get showLoginNames => 'Kuva kasutajatunnuseid';

  @override
  String get loginNamesShown =>
      'Kasutajatunnuseid kuvatakse, kui need erinevad kuvatavast nimest';

  @override
  String get loginNamesHidden => 'Kasutajatunnused on peidetud';

  @override
  String get compactMessages => 'Tihenda sõnumeid';

  @override
  String get dontCompactMessages => 'Ära tihenda sõnumeid';

  @override
  String get dontCompactMessagesSubtitle => 'Sõnumeid kuvatakse muutmata kujul';

  @override
  String get compactIndividualMessages => 'Tihenda üksikuid sõnumeid';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Korduv tekst sõnumites lühendatakse';

  @override
  String get announcementPinDuration => 'Teadaande kinnitamise kestus';

  @override
  String get idleMessageAlertDuration => 'Vaikuse märguande kestus';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Kui selle aja jooksul pole ühtegi sõnumit tulnud ja saabub uus sõnum, esitatakse märguandeheli.';

  @override
  String get realtimeCashSubtitle => 'Ühenda ETH- või MATIC-rahakott';

  @override
  String get walletAddress => 'Rahakoti aadress';

  @override
  String get streamlabsSubtitle => 'Vaata oma Streamlabsi annetusi';

  @override
  String get streamElementsSubtitle => 'Vaata oma StreamElementsi annetusi';

  @override
  String get thirdPartyAuthError =>
      'Hmm, see ei õnnestunud. Proovi uuesti või küsi abi Discordist?';

  @override
  String get companionAuthBrowserTooOld =>
      'Sinu brauser on otse sisselogimiseks liiga vana. Skanni see QR-kood oma telefoniga, et logida sisse teises seadmes.';

  @override
  String get companionAuthScanQrCode =>
      'Skanni see QR-kood oma telefoniga, et logida sisse teises seadmes.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> tellis kanali!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> pikendas tellimust ($monthsString kuud)!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> kinkis $countString tellimust!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> saatis $amountString Kicki!';
  }

  @override
  String get signInWithKick => 'Logi sisse Kickiga';

  @override
  String get textToSpeechTooManyMessages =>
      'Sõnumeid on liiga palju. Kõnesüntees keelati';

  @override
  String get turnOffTextToSpeech => 'Lülita välja';

  @override
  String get addToChat => 'Lisa vestlusesse';

  @override
  String get inChat => 'Vestluses';

  @override
  String get removeFromChat => 'Eemalda vestlusest';

  @override
  String cantChatWithAccount(String provider) {
    return 'Sinu $provider-konto ei saa siin vestelda';
  }

  @override
  String get cantChatWithAccounts => 'Sinu kontod ei saa siin vestelda';

  @override
  String sendAMessageTo(String channel) {
    return 'Saada sõnum kanalile $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Asenda $channel';
  }

  @override
  String get voicePacks => 'Häälepaketid';

  @override
  String get voicePacksDescription =>
      'Häälepaketid loevad vestlust loomuliku kõlaga häältega, mis töötavad sinu seadmes ja pärast allalaadimist ka võrguühenduseta. Hääled on tehisintellekti loodud, mitte inimese salvestatud.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices häält',
      one: '$voices hääl',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keelt',
      one: '$count keel',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Selle mudeli litsents (OpenRAIL-M) keelab kahjuliku kasutamise, nagu teiste inimestena esinemise või väärinfo levitamise, ning need piirangud kehtivad ka sulle.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Kas kustutada $pack? See vabastab $size.';
  }

  @override
  String get voicePackDownload => 'Laadi alla';

  @override
  String get voicePackUpdate => 'Uuenda';

  @override
  String get voicePackWaitingForWifi => 'Wi-Fi-ühenduse ootamine';

  @override
  String get voicePackUseMobileData => 'Kasuta mobiilset andmesidet';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Allalaadimine: $downloaded / $total';
  }

  @override
  String get voicePackInstalling => 'Paigaldamine';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Paketi $pack paigaldamine ebaõnnestus. Kontrolli ühendust ja proovi uuesti.';
  }

  @override
  String get voices => 'Hääled';

  @override
  String get perViewerVoice => 'Igale vaatajale oma hääl';

  @override
  String get perViewerVoiceSubtitle =>
      'Iga vaataja saab oma hääle. Sinu valitud hääl loeb märguandeid või kõike, kui see valik on välja lülitatud.';

  @override
  String get streamLanguage => 'Ülekande keel';

  @override
  String get ttsEngineNeural => 'Neurohääl (seadmesisene)';

  @override
  String get ttsEngineSystem => 'Süsteemi hääl';

  @override
  String languageUnsupported(String language) {
    return 'Sinu häälepaketid ei toeta keelt $language; kasutatakse süsteemi häält';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Sellel seadmel pole neurohäälte jaoks piisavalt mälu, seega loetakse vestlust süsteemi häälega.';

  @override
  String get neuralFallbackLoadFailed =>
      'Neurohääle laadimine ebaõnnestus, seega loetakse vestlust süsteemi häälega.';

  @override
  String get accounts => 'Kontod';

  @override
  String get accountsSubtitle =>
      'Logi sisse igale platvormile, kus teed ülekandeid';

  @override
  String addProviderAccount(String provider) {
    return 'Lisa $provider-konto';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Logi sisse teenusega $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Kas logida välja kontolt $channel platvormil $provider?';
  }

  @override
  String get signOutOfAll => 'Logi välja kõigilt kontodelt';
}
