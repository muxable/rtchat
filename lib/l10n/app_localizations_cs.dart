// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get sendAMessage => 'Poslat zprávu...';

  @override
  String get writeSomething => 'Napište něco...';

  @override
  String get speakToTheCrowds => 'Promluvte k davům...';

  @override
  String get shareYourThoughts => 'Podělte se o své myšlenky...';

  @override
  String get saySomethingYouLittleBitch => 'Řekni něco, ty malá děvko...';

  @override
  String get search => 'Hledat';

  @override
  String get notSignedIn => 'Nepřihlášen';

  @override
  String get searchChannels => 'Hledat kanály';

  @override
  String get raidAChannel => 'Spustit raid';

  @override
  String get noMessagesEmptyState => 'Je tu ticho.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nových zpráv',
      many: '$count nové zprávy',
      few: '$count nové zprávy',
      one: '1 nová zpráva',
      zero: 'Žádné nové zprávy',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Přihlásit se přes Twitch';

  @override
  String get signInError =>
      'Při přihlašování došlo k chybě. Zkuste to prosím znovu.';

  @override
  String get continueAsGuest => 'Pokračovat jako host';

  @override
  String get signInToSendMessages => 'Pro odesílání zpráv se přihlaste';

  @override
  String get currentViewers => 'Aktuální diváci';

  @override
  String get textToSpeech => 'Převod textu na řeč';

  @override
  String get streamPreview => 'Náhled streamu';

  @override
  String get activityFeed => 'Přehled aktivit';

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

    return 'Chat vymazán $dateString v $timeString';
  }

  @override
  String get configureQuickLinks => 'Nastavit rychlé odkazy';

  @override
  String get disableRainMode => 'Vypnout režim deště';

  @override
  String get enableRainMode => 'Zapnout režim deště';

  @override
  String get disableRainModeSubtitle => 'Interakce bude povolena';

  @override
  String get enableRainModeSubtitle => 'Interakce bude zakázána';

  @override
  String get refreshAudioSources => 'Obnovit zdroje zvuku';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Obnoveno $count zdrojů zvuku',
      many: 'Obnoveno $count zdroje zvuku',
      few: 'Obnoveny $count zdroje zvuku',
      one: 'Obnoven 1 zdroj zvuku',
      zero: 'Žádné zdroje zvuku nebyly obnoveny',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Nastavení';

  @override
  String get signOut => 'Odhlásit se';

  @override
  String get cancel => 'Zrušit';

  @override
  String get signOutConfirmation => 'Opravdu se chcete odhlásit?';

  @override
  String get broadcaster => 'Vysílající';

  @override
  String get moderators => 'Moderátoři';

  @override
  String get viewers => 'Diváci';

  @override
  String get communityVips => 'VIP komunity';

  @override
  String get searchViewers => 'Hledat diváky';

  @override
  String get reconnecting => 'Opětovné připojování...';

  @override
  String get twitchBadges => 'Odznaky Twitch';

  @override
  String get selectAll => 'Vybrat vše';

  @override
  String get quickLinks => 'Rychlé odkazy';

  @override
  String get swipeToDeleteQuickLinks =>
      'Přejetím doleva nebo doprava rychlý odkaz smažete';

  @override
  String get quickLinksLabelHint => 'Popisek';

  @override
  String get invalidUrlErrorText => 'Toto nevypadá jako platná adresa URL';

  @override
  String get duplicateUrlErrorText => 'Tento odkaz již existuje';

  @override
  String get or => 'nebo';

  @override
  String get clearCookies => 'Vymazat soubory cookie';

  @override
  String get disabled => 'Vypnuto';

  @override
  String get twitchActivityFeed => 'Přehled aktivit Twitch';

  @override
  String get signInToEnable => 'Pro zapnutí této funkce musíte být přihlášeni';

  @override
  String get customUrl => 'Vlastní URL';

  @override
  String get preview => 'Náhled';

  @override
  String get audioSources => 'Zdroje zvuku';

  @override
  String get enableOffStreamSwitchTitle =>
      'Povolit mimo stream (vyšší spotřeba baterie)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Zvuk se bude přehrávat, i když jste offline';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Zvuk se bude přehrávat pouze při živém vysílání';

  @override
  String get iosOggWarningTitle => 'Hej! Poslouchejte!';

  @override
  String get iosOggWarningSubtitle =>
      'Systém iOS nepodporuje mediální soubory *.ogg, které jsou ve službě Streamlabs výchozí. Ujistěte se, že vaše zdroje zvuku používají jiný formát, jinak se nepřehrají.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Přizpůsobte si přehled aktivit';

  @override
  String get audioSourcesSubtitle =>
      'Přidejte webové zdroje pro zvuky upozornění';

  @override
  String get quickLinksSubtitle =>
      'Přidejte zástupce často používaných nástrojů';

  @override
  String get chatHistory => 'Historie chatu';

  @override
  String get chatHistorySubtitle => 'Změňte vzhled chatu';

  @override
  String get textToSpeechSubtitle => 'Změňte nastavení převodu textu na řeč';

  @override
  String get events => 'Události';

  @override
  String get eventsSubtitle => 'Nastavte události Twitch';

  @override
  String get thirdPartyServices => 'Služby třetích stran';

  @override
  String get thirdPartyServicesSubtitle => 'Připojte se ke službě třetí strany';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> vás začíná sledovat';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> a <b>$displayNameTwo</b> vás začínají sledovat';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> a $numOthersString dalších vás začínají sledovat';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Zrušit ztlumení $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Ztlumit $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Dočasně umlčet $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Zabanovat $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Zrušit ban $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Zobrazit profil uživatele $displayName';
  }

  @override
  String get copyMessage => 'Kopírovat zprávu';

  @override
  String get deleteMessage => 'Smazat zprávu';

  @override
  String get longScrollNotification => 'Posouváte docela daleko, nemyslíte?';

  @override
  String get stfu => 'sklapni';

  @override
  String get globalEmotes => 'Globální emotikony';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString sledujících',
      many: '$countString sledujícího',
      few: '$countString sledující',
      one: '1 sledující',
      zero: '0 sledujících',
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
      other: '$countString diváků',
      many: '$countString diváka',
      few: '$countString diváci',
      one: '1 divák',
      zero: '0 diváků',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Ahoj! Jsme rádi, že používáte náhled streamu, ale pozor, spotřebovává spoustu baterie. Čtení chatu bez něj prodlouží výdrž baterie.';

  @override
  String get okay => 'Dobře';

  @override
  String get streamPreviewLoading => 'Načítání (nebo je stream offline)...';

  @override
  String get copiedToClipboard => 'Zkopírováno do schránky';

  @override
  String get audioSourcesRequirePermissions =>
      'Zdroje zvuku vyžadují oprávnění';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Pro použití zdrojů zvuku povolte aplikaci RealtimeChat vykreslování přes ostatní aplikace.';

  @override
  String get audioSourcesRemoveButton => 'Odebrat zdroje zvuku';

  @override
  String get audioSourcesOpenSettingsButton => 'Otevřít nastavení';

  @override
  String get flashOn => 'Zapnout blesk';

  @override
  String get flashOff => 'Vypnout blesk';

  @override
  String get durationOneSecond => '1 sekunda';

  @override
  String get durationOneMinute => '1 minuta';

  @override
  String get durationTenMinutes => '10 minut';

  @override
  String get durationOneHour => '1 hodina';

  @override
  String get durationSixHours => '6 hodin';

  @override
  String get durationOneDay => '1 den';

  @override
  String get durationTwoDays => '2 dny';

  @override
  String get durationOneWeek => '1 týden';

  @override
  String get durationTwoWeeks => '2 týdny';

  @override
  String get durationOneSecondTimeoutPrompt => 'Dočasně umlčet na 1 sekundu';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Dočasně umlčet na 1 minutu';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Dočasně umlčet na 10 minut';

  @override
  String get durationOneHourTimeoutPrompt => 'Dočasně umlčet na 1 hodinu';

  @override
  String get durationSixHoursTimeoutPrompt => 'Dočasně umlčet na 6 hodin';

  @override
  String get durationOneDayTimeoutPrompt => 'Dočasně umlčet na 1 den';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Dočasně umlčet na 2 dny';

  @override
  String get durationOneWeekTimeoutPrompt => 'Dočasně umlčet na 1 týden';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Dočasně umlčet na 2 týdny';

  @override
  String get errorFetchingViewerList =>
      'Nepodařilo se načíst seznam diváků tohoto kanálu';

  @override
  String get eventsTitle => 'Události';

  @override
  String get followEventConfigTitle => 'Událost sledování';

  @override
  String get customizeYourFollowEvent => 'Přizpůsobte si událost sledování';

  @override
  String get subscribeEventConfigTitle => 'Událost předplatného';

  @override
  String get customizeYourSubscriptionEvent =>
      'Přizpůsobte si událost předplatného';

  @override
  String get cheerEventConfigTitle => 'Událost Cheer';

  @override
  String get customizeYourCheerEvent => 'Přizpůsobte si událost Cheer';

  @override
  String get raidEventConfigTitle => 'Událost raidu';

  @override
  String get customizeYourRaidEvent => 'Přizpůsobte si událost raidu';

  @override
  String get hostEventConfigTitle => 'Událost hostování';

  @override
  String get customizeYourHostEvent => 'Přizpůsobte si událost hostování';

  @override
  String get hypetrainEventConfigTitle => 'Událost Hype Train';

  @override
  String get customizeYourHypetrainEvent => 'Přizpůsobte si událost Hype Train';

  @override
  String get pollEventConfigTitle => 'Událost ankety';

  @override
  String get customizeYourPollEvent => 'Přizpůsobte si událost ankety';

  @override
  String get predictionEventConfigTitle => 'Událost tipování';

  @override
  String get customizeYourPredictionEvent => 'Přizpůsobte si událost tipování';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Událost uplatnění věrnostních bodů';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Přizpůsobte si událost uplatnění věrnostních bodů';

  @override
  String get outgoingRaidEventConfigTitle => 'Událost odchozího raidu';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Přizpůsobte si událost odchozího raidu';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> posílá raid s <b>$viewerCountString</b> diváky!';
  }

  @override
  String get shoutout => 'Doporučit';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Probíhá raid na <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString s';
  }

  @override
  String raidingEventRaided(String displayName) {
    return 'Raid na <b>$displayName</b> dokončen!';
  }

  @override
  String get raidingEventJoin => 'Připojit se';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Raid na <b>$displayName</b> byl zrušen.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> si předplatil(a) na úrovni $tier!';
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

    return '<b>$gifterUserName</b> daroval(a) $totalString předplatných úrovně $tier, celkem již $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> odebírá již $cumulativeMonthsString měsíců na úrovni $tier!';
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

    return '<b>$subscriberUserName</b> si předplatil(a) úroveň $tier na $durationMonthsString měsíců dopředu, celkem $cumulativeMonthsString měsíců!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> poslal(a) příspěvek <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonym poslal příspěvek <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> poslal(a) příspěvek <b>$formattedAmount</b> přes StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> poslal(a) příspěvek <b>$formattedAmount</b> přes Streamlabs.';
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

    return '<b>$redeemerUsername</b> uplatnil(a) odměnu <b>$rewardName</b> za <b>$rewardCostString</b> bodů. $userInput';
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

    return '<b>$redeemerUsername</b> uplatnil(a) odměnu <b>$rewardName</b> za <b>$rewardCostString</b> bodů.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> poslal(a) <b>$bitsString</b> bitů. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonym';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> hostuje se skupinou <b>$viewersString</b> diváků.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Probíhá Hype Train úrovně <b>$level</b>! Dokončeno <b>$progressPercent %</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train úrovně <b>$levelString</b> byl úspěšný.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train úrovně <b>$levelString</b> skončil neúspěšně.';
  }

  @override
  String get sampleMessage =>
      'Toto je ukázková zpráva pro převod textu na řeč.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author řekl: $text';
  }

  @override
  String get textToSpeechEnabled => 'Převod textu na řeč zapnut';

  @override
  String get textToSpeechDisabled => 'Převod textu na řeč vypnut';

  @override
  String get alertsEnabled => 'Pouze upozornění';

  @override
  String get pinDuration => 'Doba připnutí';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekund',
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
      other: '$minutes minut',
      many: '$minutes minuty',
      few: '$minutes minuty',
      one: '1 minuta',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Povolit událost';

  @override
  String get showEventInChatHistory => 'Zobrazovat událost v historii chatu';

  @override
  String get enableShoutouts => 'Povolit doporučení (shoutout)';

  @override
  String get enableShoutoutsSubtitle =>
      'Odeslat do chatu odkaz na kanál, který poslal raid';

  @override
  String get raidConfigurationTitle => 'Nastavení raidu';

  @override
  String get cheerConfigurationTitle => 'Nastavení Cheer';

  @override
  String get followConfigurationTitle => 'Nastavení sledování';

  @override
  String get outgoingRaidConfigurationTitle => 'Nastavení odchozího raidu';

  @override
  String get hostConfigurationTitle => 'Nastavení hostování';

  @override
  String get channelPointConfigurationTitle => 'Nastavení věrnostních bodů';

  @override
  String get pollConfigurationTitle => 'Nastavení ankety';

  @override
  String get hypetrainConfigurationTitle => 'Nastavení Hype Train';

  @override
  String get subscriptionConfigurationTitle => 'Nastavení předplatného';

  @override
  String get predictionConfigurationTitle => 'Nastavení tipování';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Dodatečná doba připnutí nevyřízených odměn';

  @override
  String get pollPinDuration => 'Doba připnutí po uzavření výsledků';

  @override
  String get hypetrainPinDuration => 'Doba připnutí po skončení Hype Train';

  @override
  String get enableGiftedSubscriptions =>
      'Povolit jednotlivá darovaná předplatná';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Zobrazovat každé jednotlivé darované předplatné';

  @override
  String get settingsBackupTitle => 'Zálohování a obnovení nastavení';

  @override
  String get cloudBackup => 'Záloha v cloudu';

  @override
  String get lastBackupNever => 'Poslední záloha: nikdy';

  @override
  String get backUp => 'Zálohovat';

  @override
  String get restore => 'Obnovit';

  @override
  String get localBackup => 'Místní záloha';

  @override
  String get exportSettings => 'Exportovat';

  @override
  String get importSettings => 'Importovat';

  @override
  String get showViewerAndFollowerCount =>
      'Zobrazovat počet diváků a sledujících';

  @override
  String get screenOrientation => 'Orientace obrazovky';

  @override
  String get appTheme => 'Motiv aplikace';

  @override
  String get systemDefault => 'Systémový';

  @override
  String get portrait => 'Na výšku';

  @override
  String get landscape => 'Na šířku';

  @override
  String get lightTheme => 'Světlý';

  @override
  String get darkTheme => 'Tmavý';

  @override
  String get openSourceTitle => 'RealtimeChat je open source';

  @override
  String get openSourceSubtitle => 'Najdete nás na GitHubu!';

  @override
  String get discordSubtitle => 'Připojte se na Discord Muxable!';

  @override
  String get earlyTestersThanks =>
      'Děkujeme všem prvním testerům, kteří nahlásili chyby!';

  @override
  String get discoModeEnabled => '🕺 Disco režim zapnut! :D';

  @override
  String get discoModeDisabled => '🕺 Disco režim vypnut D:';

  @override
  String get playSampleMessage => 'Přehrát ukázkovou zprávu';

  @override
  String get textToSpeechRate => 'Rychlost řeči';

  @override
  String get textToSpeechPitch => 'Výška hlasu';

  @override
  String get muteBots => 'Ztlumit převod textu na řeč pro boty';

  @override
  String get muteEmotes => 'Ztlumit všechny emotikony při čtení';

  @override
  String get muteViewerNames => 'Ztlumit jména diváků při čtení';

  @override
  String get subscribersOnly => 'Pouze předplatitelé';

  @override
  String get fontSize => 'Velikost písma';

  @override
  String get usernameContrastBoost => 'Zvýšení kontrastu uživatelských jmen';

  @override
  String get twitchBadgeSettings => 'Nastavení odznaků Twitch';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Určete, které odznaky budou viditelné';

  @override
  String get showDeletedMessages => 'Zobrazovat smazané zprávy';

  @override
  String get deletedMessagesGreyedOut => 'Smazané zprávy budou zašedlé';

  @override
  String get deletedMessagesRemoved => 'Smazané zprávy budou odstraněny';

  @override
  String get showLoginNames => 'Zobrazovat přihlašovací jména';

  @override
  String get loginNamesShown =>
      'Přihlašovací jména se zobrazí, pokud se liší od zobrazovaného jména';

  @override
  String get loginNamesHidden => 'Přihlašovací jména budou skryta';

  @override
  String get compactMessages => 'Zkracování zpráv';

  @override
  String get dontCompactMessages => 'Nezkracovat zprávy';

  @override
  String get dontCompactMessagesSubtitle => 'Zprávy se zobrazují beze změny';

  @override
  String get compactIndividualMessages => 'Zkracovat jednotlivé zprávy';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Opakující se text ve zprávách se zkrátí';

  @override
  String get announcementPinDuration => 'Doba připnutí oznámení';

  @override
  String get idleMessageAlertDuration => 'Upozornění při neaktivním chatu';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Pokud po tuto dobu nepřijde žádná zpráva a pak dorazí nová, přehraje se zvukové upozornění.';

  @override
  String get realtimeCashSubtitle => 'Připojte peněženku ETH nebo MATIC';

  @override
  String get walletAddress => 'Adresa peněženky';

  @override
  String get streamlabsSubtitle => 'Zobrazte své příspěvky ze Streamlabs';

  @override
  String get streamElementsSubtitle =>
      'Zobrazte své příspěvky ze StreamElements';

  @override
  String get thirdPartyAuthError =>
      'Hmm, to se nepovedlo. Zkuste to znovu, nebo se zeptejte na Discordu?';

  @override
  String get companionAuthBrowserTooOld =>
      'Váš prohlížeč je příliš starý na přímé přihlášení. Naskenujte tento QR kód telefonem a přihlaste se na jiném zařízení.';

  @override
  String get companionAuthScanQrCode =>
      'Naskenujte tento QR kód telefonem a přihlaste se na jiném zařízení.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> si aktivoval(a) předplatné!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> obnovil(a) předplatné na $monthsString měsíců!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> daroval(a) $countString předplatných!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> poslal(a) $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Přihlásit se přes Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Je tu příliš mnoho zpráv. Převod textu na řeč byl vypnut';

  @override
  String get turnOffTextToSpeech => 'Vypnout';

  @override
  String get addToChat => 'Přidat do chatu';

  @override
  String get inChat => 'V chatu';

  @override
  String get removeFromChat => 'Odebrat z chatu';

  @override
  String cantChatWithAccount(String provider) {
    return 'Váš účet $provider zde nemůže psát do chatu';
  }

  @override
  String get cantChatWithAccounts => 'Vaše účty zde nemohou psát do chatu';

  @override
  String sendAMessageTo(String channel) {
    return 'Poslat zprávu na $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Nahradit $channel';
  }

  @override
  String get voicePacks => 'Hlasové balíčky';

  @override
  String get voicePacksDescription =>
      'Hlasové balíčky předčítají chat přirozeně znějícími hlasy přímo ve vašem zařízení a po stažení fungují offline. Hlasy jsou strojově generované umělou inteligencí, nikoliv nahrané člověkem.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices hlasů',
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
      other: '$count jazyků',
      many: '$count jazyka',
      few: '$count jazyky',
      one: '1 jazyk',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Licence tohoto modelu (OpenRAIL-M) zakazuje škodlivé využití, jako je vydávání se za jiné osoby nebo šíření dezinformací, a tato omezení platí i pro vás.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Smazat balíček $pack? Uvolní se tím $size.';
  }

  @override
  String get voicePackDownload => 'Stáhnout';

  @override
  String get voicePackUpdate => 'Aktualizovat';

  @override
  String get voicePackWaitingForWifi => 'Čekání na Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Použít mobilní data';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Stahování: $downloaded z $total';
  }

  @override
  String get voicePackInstalling => 'Instalace';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Nepodařilo se nainstalovat balíček $pack. Zkontrolujte připojení a zkuste to znovu.';
  }

  @override
  String get voices => 'Hlasy';

  @override
  String get perViewerVoice => 'Vlastní hlas pro každého diváka';

  @override
  String get perViewerVoiceSubtitle =>
      'Každý divák dostane svůj vlastní hlas. Vybraný hlas čte upozornění, nebo vše, když je tato možnost vypnutá.';

  @override
  String get streamLanguage => 'Jazyk streamu';

  @override
  String get ttsEngineNeural => 'Neuronový hlas (v zařízení)';

  @override
  String get ttsEngineSystem => 'Systémový hlas';

  @override
  String languageUnsupported(String language) {
    return 'Vaše hlasové balíčky nepodporují jazyk $language; použije se systémový hlas';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Toto zařízení nemá dostatek paměti pro neuronové hlasy, proto je chat předčítán systémovým hlasem.';

  @override
  String get neuralFallbackLoadFailed =>
      'Neuronový hlas se nepodařilo načíst, proto je chat předčítán systémovým hlasem.';

  @override
  String get accounts => 'Účty';

  @override
  String get accountsSubtitle =>
      'Přihlaste se na každou platformu, na které streamujete';

  @override
  String addProviderAccount(String provider) {
    return 'Přidat účet $provider';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Přihlásit se přes $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Odhlásit se z kanálu $channel na platformě $provider?';
  }

  @override
  String get signOutOfAll => 'Odhlásit se ze všech účtů';
}
