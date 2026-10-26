// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get sendAMessage => 'Odoslať správu...';

  @override
  String get writeSomething => 'Napíšte niečo...';

  @override
  String get speakToTheCrowds => 'Prihovorte sa davom...';

  @override
  String get shareYourThoughts => 'Podeľte sa o svoje myšlienky...';

  @override
  String get saySomethingYouLittleBitch => 'Povedz niečo, ty malá suka...';

  @override
  String get search => 'Hľadať';

  @override
  String get notSignedIn => 'Neprihlásený';

  @override
  String get searchChannels => 'Hľadať kanály';

  @override
  String get raidAChannel => 'Spustiť raid';

  @override
  String get noMessagesEmptyState => 'Je tu ticho.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nových správ',
      many: '$count novej správy',
      few: '$count nové správy',
      one: '1 nová správa',
      zero: 'Žiadne nové správy',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Prihlásiť sa cez Twitch';

  @override
  String get signInError =>
      'Pri prihlasovaní sa vyskytla chyba. Skúste to prosím znova.';

  @override
  String get continueAsGuest => 'Pokračovať ako hosť';

  @override
  String get signInToSendMessages => 'Ak chcete odosielať správy, prihláste sa';

  @override
  String get currentViewers => 'Aktuálni diváci';

  @override
  String get textToSpeech => 'Prevod textu na reč';

  @override
  String get streamPreview => 'Náhľad streamu';

  @override
  String get activityFeed => 'Prehľad aktivít';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream je online od $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream je offline od $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Čet bol vymazaný $dateString o $timeString';
  }

  @override
  String get configureQuickLinks => 'Nastaviť rýchle odkazy';

  @override
  String get disableRainMode => 'Vypnúť režim dažďa';

  @override
  String get enableRainMode => 'Zapnúť režim dažďa';

  @override
  String get disableRainModeSubtitle => 'Interakcia bude povolená';

  @override
  String get enableRainModeSubtitle => 'Interakcia bude zakázaná';

  @override
  String get refreshAudioSources => 'Obnoviť zdroje zvuku';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Obnovených $count zdrojov zvuku',
      many: 'Obnoveného $count zdroja zvuku',
      few: 'Obnovené $count zdroje zvuku',
      one: 'Obnovený 1 zdroj zvuku',
      zero: 'Žiadne zdroje zvuku neboli obnovené',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Nastavenia';

  @override
  String get signOut => 'Odhlásiť sa';

  @override
  String get cancel => 'Zrušiť';

  @override
  String get signOutConfirmation => 'Naozaj sa chcete odhlásiť?';

  @override
  String get broadcaster => 'Vysielajúci';

  @override
  String get moderators => 'Moderátori';

  @override
  String get viewers => 'Diváci';

  @override
  String get communityVips => 'VIP komunity';

  @override
  String get searchViewers => 'Hľadať divákov';

  @override
  String get reconnecting => 'Opätovné pripájanie...';

  @override
  String get twitchBadges => 'Odznaky Twitch';

  @override
  String get selectAll => 'Vybrať všetko';

  @override
  String get quickLinks => 'Rýchle odkazy';

  @override
  String get swipeToDeleteQuickLinks =>
      'Potiahnutím doľava alebo doprava rýchly odkaz odstránite';

  @override
  String get quickLinksLabelHint => 'Menovka';

  @override
  String get invalidUrlErrorText => 'Toto nevyzerá ako platná adresa URL';

  @override
  String get duplicateUrlErrorText => 'Tento odkaz už existuje';

  @override
  String get or => 'alebo';

  @override
  String get clearCookies => 'Vymazať súbory cookie';

  @override
  String get disabled => 'Vypnuté';

  @override
  String get twitchActivityFeed => 'Prehľad aktivít Twitch';

  @override
  String get signInToEnable =>
      'Ak chcete túto funkciu zapnúť, musíte sa prihlásiť';

  @override
  String get customUrl => 'Vlastná adresa URL';

  @override
  String get preview => 'Náhľad';

  @override
  String get audioSources => 'Zdroje zvuku';

  @override
  String get enableOffStreamSwitchTitle =>
      'Povoliť mimo streamu (vyššia spotreba batérie)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Zvuk sa bude prehrávať, aj keď ste offline';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Zvuk sa bude prehrávať iba počas živého vysielania';

  @override
  String get iosOggWarningTitle => 'Hej! Počúvajte!';

  @override
  String get iosOggWarningSubtitle =>
      'Systém iOS nepodporuje mediálne súbory *.ogg, ktoré sú v službe Streamlabs predvolené. Uistite sa, že vaše zdroje zvuku používajú iný formát, inak sa neprehrajú.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Prispôsobte si prehľad aktivít';

  @override
  String get audioSourcesSubtitle =>
      'Pridajte webové zdroje pre zvuky upozornení';

  @override
  String get quickLinksSubtitle =>
      'Pridajte skratky k často používaným nástrojom';

  @override
  String get chatHistory => 'História četu';

  @override
  String get chatHistorySubtitle => 'Zmeňte vzhľad četu';

  @override
  String get textToSpeechSubtitle => 'Zmeňte nastavenia prevodu textu na reč';

  @override
  String get events => 'Udalosti';

  @override
  String get eventsSubtitle => 'Nastavte udalosti Twitch';

  @override
  String get thirdPartyServices => 'Služby tretích strán';

  @override
  String get thirdPartyServicesSubtitle => 'Pripojte sa k službe tretej strany';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> vás začína sledovať';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> a <b>$displayNameTwo</b> vás začínajú sledovať';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> a $numOthersString ďalších vás začínajú sledovať';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Zrušiť stíšenie $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Stíšiť $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Dočasne umlčať $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Zabanovať $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Zrušiť ban $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Zobraziť profil používateľa $displayName';
  }

  @override
  String get copyMessage => 'Kopírovať správu';

  @override
  String get deleteMessage => 'Odstrániť správu';

  @override
  String get longScrollNotification => 'Posúvate sa celkom ďaleko, nemyslíte?';

  @override
  String get stfu => 'sklapni';

  @override
  String get globalEmotes => 'Globálne emotikony';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString sledujúcich',
      many: '$countString sledujúceho',
      few: '$countString sledujúci',
      one: '1 sledujúci',
      zero: '0 sledujúcich',
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
      other: '$countString divákov',
      many: '$countString diváka',
      few: '$countString diváci',
      one: '1 divák',
      zero: '0 divákov',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Ahoj! Sme radi, že používate náhľad streamu, ale pozor, spotrebúva veľa batérie. Čítanie četu bez neho predĺži výdrž batérie.';

  @override
  String get okay => 'Dobre';

  @override
  String get streamPreviewLoading => 'Načítava sa (alebo je stream offline)...';

  @override
  String get copiedToClipboard => 'Skopírované do schránky';

  @override
  String get audioSourcesRequirePermissions =>
      'Zdroje zvuku vyžadujú povolenia';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Ak chcete používať zdroje zvuku, povoľte aplikácii RealtimeChat vykresľovanie nad ostatnými aplikáciami.';

  @override
  String get audioSourcesRemoveButton => 'Odstrániť zdroje zvuku';

  @override
  String get audioSourcesOpenSettingsButton => 'Otvoriť nastavenia';

  @override
  String get flashOn => 'Zapnúť blesk';

  @override
  String get flashOff => 'Vypnúť blesk';

  @override
  String get durationOneSecond => '1 sekunda';

  @override
  String get durationOneMinute => '1 minúta';

  @override
  String get durationTenMinutes => '10 minút';

  @override
  String get durationOneHour => '1 hodina';

  @override
  String get durationSixHours => '6 hodín';

  @override
  String get durationOneDay => '1 deň';

  @override
  String get durationTwoDays => '2 dni';

  @override
  String get durationOneWeek => '1 týždeň';

  @override
  String get durationTwoWeeks => '2 týždne';

  @override
  String get durationOneSecondTimeoutPrompt => 'Dočasne umlčať na 1 sekundu';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Dočasne umlčať na 1 minútu';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Dočasne umlčať na 10 minút';

  @override
  String get durationOneHourTimeoutPrompt => 'Dočasne umlčať na 1 hodinu';

  @override
  String get durationSixHoursTimeoutPrompt => 'Dočasne umlčať na 6 hodín';

  @override
  String get durationOneDayTimeoutPrompt => 'Dočasne umlčať na 1 deň';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Dočasne umlčať na 2 dni';

  @override
  String get durationOneWeekTimeoutPrompt => 'Dočasne umlčať na 1 týždeň';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Dočasne umlčať na 2 týždne';

  @override
  String get errorFetchingViewerList =>
      'Nepodarilo sa načítať zoznam divákov pre tento kanál';

  @override
  String get eventsTitle => 'Udalosti';

  @override
  String get followEventConfigTitle => 'Udalosť sledovania';

  @override
  String get customizeYourFollowEvent => 'Prispôsobte si udalosť sledovania';

  @override
  String get subscribeEventConfigTitle => 'Udalosť predplatného';

  @override
  String get customizeYourSubscriptionEvent =>
      'Prispôsobte si udalosť predplatného';

  @override
  String get cheerEventConfigTitle => 'Udalosť Cheer';

  @override
  String get customizeYourCheerEvent => 'Prispôsobte si udalosť Cheer';

  @override
  String get raidEventConfigTitle => 'Udalosť raidu';

  @override
  String get customizeYourRaidEvent => 'Prispôsobte si udalosť raidu';

  @override
  String get hostEventConfigTitle => 'Udalosť hosťovania';

  @override
  String get customizeYourHostEvent => 'Prispôsobte si udalosť hosťovania';

  @override
  String get hypetrainEventConfigTitle => 'Udalosť Hype Train';

  @override
  String get customizeYourHypetrainEvent => 'Prispôsobte si udalosť Hype Train';

  @override
  String get pollEventConfigTitle => 'Udalosť ankety';

  @override
  String get customizeYourPollEvent => 'Prispôsobte si udalosť ankety';

  @override
  String get predictionEventConfigTitle => 'Udalosť tipovania';

  @override
  String get customizeYourPredictionEvent => 'Prispôsobte si udalosť tipovania';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Udalosť uplatnenia vernostných bodov';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Prispôsobte si udalosť uplatnenia vernostných bodov';

  @override
  String get outgoingRaidEventConfigTitle => 'Udalosť odchádzajúceho raidu';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Prispôsobte si udalosť odchádzajúceho raidu';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> posiela raid s <b>$viewerCountString</b> divákmi!';
  }

  @override
  String get shoutout => 'Odporučiť';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Prebieha raid na <b>$displayName</b>...';
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
    return 'Raid na <b>$displayName</b> bol dokončený!';
  }

  @override
  String get raidingEventJoin => 'Pripojiť sa';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Raid na <b>$displayName</b> bol zrušený.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> si predplatil(a) na úrovni $tier!';
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

    return '<b>$gifterUserName</b> daroval(a) $totalString predplatných úrovne $tier, celkovo už $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> odoberá už $cumulativeMonthsString mesiacov na úrovni $tier!';
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

    return '<b>$subscriberUserName</b> si predplatil(a) úroveň $tier na $durationMonthsString mesiacov vopred, celkovo $cumulativeMonthsString mesiacov!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> poslal(a) príspevok <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonym poslal príspevok <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> poslal(a) príspevok <b>$formattedAmount</b> cez StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> poslal(a) príspevok <b>$formattedAmount</b> cez Streamlabs.';
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

    return '<b>$redeemerUsername</b> uplatnil(a) odmenu <b>$rewardName</b> za <b>$rewardCostString</b> bodov. $userInput';
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

    return '<b>$redeemerUsername</b> uplatnil(a) odmenu <b>$rewardName</b> za <b>$rewardCostString</b> bodov.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> poslal(a) <b>$bitsString</b> bitov. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonym';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> hosťuje so skupinou <b>$viewersString</b> divákov.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Prebieha Hype Train úrovne <b>$level</b>! Dokončené na <b>$progressPercent %</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train úrovne <b>$levelString</b> bol úspešný.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train úrovne <b>$levelString</b> skončil neúspešne.';
  }

  @override
  String get sampleMessage =>
      'Toto je ukážková správa pre prevod textu na reč.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author povedal: $text';
  }

  @override
  String get textToSpeechEnabled => 'Prevod textu na reč zapnutý';

  @override
  String get textToSpeechDisabled => 'Prevod textu na reč vypnutý';

  @override
  String get alertsEnabled => 'Iba upozornenia';

  @override
  String get pinDuration => 'Trvanie pripnutia';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekúnd',
      many: '$seconds sekundy',
      few: '$seconds sekundy',
      one: '1 sekunda',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minút',
      many: '$minutes minúty',
      few: '$minutes minúty',
      one: '1 minúta',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Povoliť udalosť';

  @override
  String get showEventInChatHistory => 'Zobrazovať udalosť v histórii četu';

  @override
  String get enableShoutouts => 'Povoliť odporúčania (shoutout)';

  @override
  String get enableShoutoutsSubtitle =>
      'Odoslať do četu odkaz na kanál, ktorý poslal raid';

  @override
  String get raidConfigurationTitle => 'Nastavenie raidu';

  @override
  String get cheerConfigurationTitle => 'Nastavenie Cheer';

  @override
  String get followConfigurationTitle => 'Nastavenie sledovania';

  @override
  String get outgoingRaidConfigurationTitle =>
      'Nastavenie odchádzajúceho raidu';

  @override
  String get hostConfigurationTitle => 'Nastavenie hosťovania';

  @override
  String get channelPointConfigurationTitle => 'Nastavenie vernostných bodov';

  @override
  String get pollConfigurationTitle => 'Nastavenie ankety';

  @override
  String get hypetrainConfigurationTitle => 'Nastavenie Hype Train';

  @override
  String get subscriptionConfigurationTitle => 'Nastavenie predplatného';

  @override
  String get predictionConfigurationTitle => 'Nastavenie tipovania';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Dodatočné trvanie pripnutia nevybavených odmien';

  @override
  String get pollPinDuration => 'Trvanie pripnutia po uzavretí výsledkov';

  @override
  String get hypetrainPinDuration => 'Trvanie pripnutia po skončení Hype Train';

  @override
  String get enableGiftedSubscriptions =>
      'Povoliť jednotlivé darované predplatné';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Zobrazovať každé jednotlivé darované predplatné';

  @override
  String get settingsBackupTitle => 'Zálohovanie a obnovenie nastavení';

  @override
  String get cloudBackup => 'Záloha v cloude';

  @override
  String get lastBackupNever => 'Posledná záloha: nikdy';

  @override
  String get backUp => 'Zálohovať';

  @override
  String get restore => 'Obnoviť';

  @override
  String get localBackup => 'Miestna záloha';

  @override
  String get exportSettings => 'Exportovať';

  @override
  String get importSettings => 'Importovať';

  @override
  String get showViewerAndFollowerCount =>
      'Zobrazovať počet divákov a sledujúcich';

  @override
  String get screenOrientation => 'Orientácia obrazovky';

  @override
  String get appTheme => 'Motív aplikácie';

  @override
  String get systemDefault => 'Systémový';

  @override
  String get portrait => 'Na výšku';

  @override
  String get landscape => 'Na šírku';

  @override
  String get lightTheme => 'Svetlý';

  @override
  String get darkTheme => 'Tmavý';

  @override
  String get openSourceTitle => 'RealtimeChat je open source';

  @override
  String get openSourceSubtitle => 'Nájdete nás na GitHube!';

  @override
  String get discordSubtitle => 'Pripojte sa na Discord Muxable!';

  @override
  String get earlyTestersThanks =>
      'Ďakujeme všetkým prvým testerom, ktorí nahlásili chyby!';

  @override
  String get discoModeEnabled => '🕺 Disco režim zapnutý! :D';

  @override
  String get discoModeDisabled => '🕺 Disco režim vypnutý D:';

  @override
  String get playSampleMessage => 'Prehrať ukážkovú správu';

  @override
  String get textToSpeechRate => 'Rýchlosť reči';

  @override
  String get textToSpeechPitch => 'Výška hlasu';

  @override
  String get muteBots => 'Stíšiť prevod textu na reč pre botov';

  @override
  String get muteEmotes => 'Stíšiť všetky emotikony pri čítaní';

  @override
  String get muteViewerNames => 'Stíšiť mená divákov pri čítaní';

  @override
  String get subscribersOnly => 'Iba predplatitelia';

  @override
  String get fontSize => 'Veľkosť písma';

  @override
  String get usernameContrastBoost => 'Zvýšenie kontrastu používateľských mien';

  @override
  String get twitchBadgeSettings => 'Nastavenia odznakov Twitch';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Určite, ktoré odznaky budú viditeľné';

  @override
  String get showDeletedMessages => 'Zobrazovať odstránené správy';

  @override
  String get deletedMessagesGreyedOut => 'Odstránené správy budú sivé';

  @override
  String get deletedMessagesRemoved => 'Odstránené správy budú skryté';

  @override
  String get showLoginNames => 'Zobrazovať prihlasovacie mená';

  @override
  String get loginNamesShown =>
      'Prihlasovacie mená sa zobrazia, ak sa líšia od zobrazovaného mena';

  @override
  String get loginNamesHidden => 'Prihlasovacie mená budú skryté';

  @override
  String get compactMessages => 'Skracovanie správ';

  @override
  String get dontCompactMessages => 'Neskracovať správy';

  @override
  String get dontCompactMessagesSubtitle => 'Správy sa zobrazujú bez zmeny';

  @override
  String get compactIndividualMessages => 'Skracovať jednotlivé správy';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Opakujúci sa text v správach sa skráti';

  @override
  String get announcementPinDuration => 'Trvanie pripnutia oznámenia';

  @override
  String get idleMessageAlertDuration => 'Upozornenie pri neaktívnom čete';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Ak počas tejto doby nepríde žiadna správa a potom dorazí nová, prehrá sa zvukové upozornenie.';

  @override
  String get realtimeCashSubtitle => 'Pripojte peňaženku ETH alebo MATIC';

  @override
  String get walletAddress => 'Adresa peňaženky';

  @override
  String get streamlabsSubtitle => 'Zobrazte svoje príspevky zo Streamlabs';

  @override
  String get streamElementsSubtitle =>
      'Zobrazte svoje príspevky zo StreamElements';

  @override
  String get thirdPartyAuthError =>
      'Hmm, to sa nepodarilo. Skúste to znova, alebo sa opýtajte na Discorde?';

  @override
  String get companionAuthBrowserTooOld =>
      'Váš prehliadač je príliš starý na priame prihlásenie. Naskenujte tento QR kód telefónom a prihláste sa na inom zariadení.';

  @override
  String get companionAuthScanQrCode =>
      'Naskenujte tento QR kód telefónom a prihláste sa na inom zariadení.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> si aktivoval(a) predplatné!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> obnovil(a) predplatné na $monthsString mesiacov!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> daroval(a) $countString predplatných!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> poslal(a) $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Prihlásiť sa cez Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Je tu príliš veľa správ. Prevod textu na reč bol vypnutý';

  @override
  String get turnOffTextToSpeech => 'Vypnúť';

  @override
  String get addToChat => 'Pridať do četu';

  @override
  String get inChat => 'V čete';

  @override
  String get removeFromChat => 'Odstrániť z četu';

  @override
  String cantChatWithAccount(String provider) {
    return 'Váš účet $provider tu nemôže četovať';
  }

  @override
  String get cantChatWithAccounts => 'Vaše účty tu nemôžu četovať';

  @override
  String sendAMessageTo(String channel) {
    return 'Odoslať správu na $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Nahradiť $channel';
  }

  @override
  String get voicePacks => 'Hlasové balíky';

  @override
  String get voicePacksDescription =>
      'Hlasové balíky čítajú čet prirodzene znejúcimi hlasmi priamo vo vašom zariadení a po stiahnutí fungujú offline. Hlasy sú strojovo generované umelou inteligenciou, nie nahrané človekom.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices hlasov',
      many: '$voices hlasu',
      few: '$voices hlasy',
      one: '1 hlas',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jazykov',
      many: '$count jazyka',
      few: '$count jazyky',
      one: '1 jazyk',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Licencia tohto modelu (OpenRAIL-M) zakazuje škodlivé použitie, ako je vydávanie sa za iné osoby alebo šírenie dezinformácií, a tieto obmedzenia platia aj pre vás.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Odstrániť balík $pack? Uvoľní sa tým $size.';
  }

  @override
  String get voicePackDownload => 'Stiahnuť';

  @override
  String get voicePackUpdate => 'Aktualizovať';

  @override
  String get voicePackWaitingForWifi => 'Čaká sa na Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Použiť mobilné dáta';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Sťahuje sa: $downloaded z $total';
  }

  @override
  String get voicePackInstalling => 'Inštaluje sa';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Nepodarilo sa nainštalovať balík $pack. Skontrolujte pripojenie a skúste to znova.';
  }

  @override
  String get voices => 'Hlasy';

  @override
  String get perViewerVoice => 'Vlastný hlas pre každého diváka';

  @override
  String get perViewerVoiceSubtitle =>
      'Každý divák dostane svoj vlastný hlas. Vybraný hlas číta upozornenia, alebo všetko, keď je táto možnosť vypnutá.';

  @override
  String get streamLanguage => 'Jazyk streamu';

  @override
  String get ttsEngineNeural => 'Neurónový hlas (v zariadení)';

  @override
  String get ttsEngineSystem => 'Systémový hlas';

  @override
  String languageUnsupported(String language) {
    return 'Vaše hlasové balíky nepodporujú jazyk $language; použije sa systémový hlas';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Toto zariadenie nemá dostatok pamäte pre neurónové hlasy, preto sa čet číta systémovým hlasom.';

  @override
  String get neuralFallbackLoadFailed =>
      'Neurónový hlas sa nepodarilo načítať, preto sa čet číta systémovým hlasom.';

  @override
  String get accounts => 'Účty';

  @override
  String get accountsSubtitle =>
      'Prihláste sa na každú platformu, na ktorej vysielate';

  @override
  String addProviderAccount(String provider) {
    return 'Pridať účet $provider';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Prihlásiť sa cez $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Odhlásiť sa z kanála $channel na platforme $provider?';
  }

  @override
  String get signOutOfAll => 'Odhlásiť sa zo všetkých účtov';
}
