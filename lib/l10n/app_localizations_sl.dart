// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'package:rtchat/l10n/app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get sendAMessage => 'Pošlji sporočilo...';

  @override
  String get writeSomething => 'Napiši nekaj...';

  @override
  String get speakToTheCrowds => 'Nagovori množico...';

  @override
  String get shareYourThoughts => 'Deli svoje misli...';

  @override
  String get saySomethingYouLittleBitch => 'Reci nekaj, ti mala prasica...';

  @override
  String get search => 'Iskanje';

  @override
  String get notSignedIn => 'Niste prijavljeni';

  @override
  String get searchChannels => 'Iskanje kanalov';

  @override
  String get raidAChannel => 'Izvedi raid';

  @override
  String get noMessagesEmptyState => 'Tukaj je vse tiho.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count novih sporočil',
      few: '$count nova sporočila',
      two: '$count novi sporočili',
      one: '$count novo sporočilo',
      zero: 'Ni novih sporočil',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Prijava s storitvijo Twitch';

  @override
  String get signInError => 'Pri prijavi je prišlo do napake. Poskusite znova.';

  @override
  String get continueAsGuest => 'Nadaljuj kot gost';

  @override
  String get signInToSendMessages => 'Za pošiljanje sporočil se prijavite';

  @override
  String get currentViewers => 'Trenutni gledalci';

  @override
  String get textToSpeech => 'Pretvorba besedila v govor';

  @override
  String get streamPreview => 'Predogled pretoka';

  @override
  String get activityFeed => 'Vir dejavnosti';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Pretok v živo od $dateString ob $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Pretok brez povezave od $dateString ob $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Klepet počiščen $dateString ob $timeString';
  }

  @override
  String get configureQuickLinks => 'Nastavi hitre povezave';

  @override
  String get disableRainMode => 'Onemogoči dežni način';

  @override
  String get enableRainMode => 'Omogoči dežni način';

  @override
  String get disableRainModeSubtitle => 'Interakcija bo omogočena';

  @override
  String get enableRainModeSubtitle => 'Interakcija bo onemogočena';

  @override
  String get refreshAudioSources => 'Osveži zvočne vire';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zvočnih virov osveženih',
      few: '$count zvočni viri osveženi',
      two: '$count zvočna vira osvežena',
      one: '$count zvočni vir osvežen',
      zero: 'Noben zvočni vir ni bil osvežen',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Nastavitve';

  @override
  String get signOut => 'Odjava';

  @override
  String get cancel => 'Prekliči';

  @override
  String get signOutConfirmation =>
      'Ali ste prepričani, da se želite odjaviti?';

  @override
  String get broadcaster => 'Izdajatelj';

  @override
  String get moderators => 'Moderatorji';

  @override
  String get viewers => 'Gledalci';

  @override
  String get communityVips => 'VIP-ji skupnosti';

  @override
  String get searchViewers => 'Išči gledalce';

  @override
  String get reconnecting => 'Ponovno povezovanje...';

  @override
  String get twitchBadges => 'Značke Twitch';

  @override
  String get selectAll => 'Izberi vse';

  @override
  String get quickLinks => 'Hitre povezave';

  @override
  String get swipeToDeleteQuickLinks =>
      'Podrsajte levo ali desno za izbris hitre povezave';

  @override
  String get quickLinksLabelHint => 'Oznaka';

  @override
  String get invalidUrlErrorText => 'To ne izgleda kot veljaven URL';

  @override
  String get duplicateUrlErrorText => 'Ta povezava že obstaja';

  @override
  String get or => 'ali';

  @override
  String get clearCookies => 'Počisti piškotke';

  @override
  String get disabled => 'Onemogočeno';

  @override
  String get twitchActivityFeed => 'Vir dejavnosti Twitch';

  @override
  String get signInToEnable =>
      'Za omogočanje te funkcije morate biti prijavljeni';

  @override
  String get customUrl => 'URL po meri';

  @override
  String get preview => 'Predogled';

  @override
  String get audioSources => 'Zvočni viri';

  @override
  String get enableOffStreamSwitchTitle =>
      'Omogoči zunaj pretoka (porabi več baterije)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Zvok se bo predvajal tudi, ko niste v živo';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Zvok se bo predvajal samo, ko oddajate v živo';

  @override
  String get iosOggWarningTitle => 'Hej! Poslušajte!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS ne podpira predstavnostnih datotek *.ogg, ki so privzete v storitvi Streamlabs. Prepričajte se, da vaši zvočni viri uporabljajo drug format, sicer se ne bodo predvajali.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Prilagodite svoj vir dejavnosti';

  @override
  String get audioSourcesSubtitle => 'Dodajte spletne vire za zvoke opozoril';

  @override
  String get quickLinksSubtitle =>
      'Dodajte bližnjice do pogosto uporabljenih orodij';

  @override
  String get chatHistory => 'Zgodovina klepeta';

  @override
  String get chatHistorySubtitle => 'Spremenite videz klepeta';

  @override
  String get textToSpeechSubtitle =>
      'Spremenite nastavitve pretvorbe besedila v govor';

  @override
  String get events => 'Dogodki';

  @override
  String get eventsSubtitle => 'Nastavite dogodke Twitch';

  @override
  String get thirdPartyServices => 'Storitve tretjih oseb';

  @override
  String get thirdPartyServicesSubtitle =>
      'Povežite se s storitvijo tretje osebe';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> vam zdaj sledi';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> in <b>$displayNameTwo</b> vam zdaj sledita';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> in še $numOthersString drugih vam zdaj sledi';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Vklopi zvok za $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Utišaj $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Začasno utišaj $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Blokiraj $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Odblokiraj $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Prikaži profil uporabnika $displayName';
  }

  @override
  String get copyMessage => 'Kopiraj sporočilo';

  @override
  String get deleteMessage => 'Izbriši sporočilo';

  @override
  String get longScrollNotification =>
      'Drsite že precej daleč nazaj, se vam ne zdi?';

  @override
  String get stfu => 'utihni';

  @override
  String get globalEmotes => 'Globalni emotikoni';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString sledilcev',
      few: '$countString sledilci',
      two: '$countString sledilca',
      one: '$countString sledilec',
      zero: '0 sledilcev',
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
      other: '$countString gledalcev',
      few: '$countString gledalci',
      two: '$countString gledalca',
      one: '$countString gledalec',
      zero: '0 gledalcev',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Živjo! Veseli nas, da radi uporabljate predogled pretoka, vendar opozarjamo, da porabi veliko baterije. Branje klepeta brez predogleda bo podaljšalo avtonomijo baterije.';

  @override
  String get okay => 'V redu';

  @override
  String get streamPreviewLoading => 'Nalaganje (ali pa pretok ni v živo)...';

  @override
  String get copiedToClipboard => 'Kopirano v odložišče';

  @override
  String get audioSourcesRequirePermissions =>
      'Zvočni viri zahtevajo dovoljenja';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Odobrite aplikaciji RealtimeChat risanje čez druge aplikacije za uporabo zvočnih virov.';

  @override
  String get audioSourcesRemoveButton => 'Odstrani zvočne vire';

  @override
  String get audioSourcesOpenSettingsButton => 'Odpri nastavitve';

  @override
  String get flashOn => 'Vklopi bliskavico';

  @override
  String get flashOff => 'Izklopi bliskavico';

  @override
  String get durationOneSecond => '1 sekunda';

  @override
  String get durationOneMinute => '1 minuta';

  @override
  String get durationTenMinutes => '10 minut';

  @override
  String get durationOneHour => '1 ura';

  @override
  String get durationSixHours => '6 ur';

  @override
  String get durationOneDay => '1 dan';

  @override
  String get durationTwoDays => '2 dni';

  @override
  String get durationOneWeek => '1 teden';

  @override
  String get durationTwoWeeks => '2 tedna';

  @override
  String get durationOneSecondTimeoutPrompt => 'Začasno utišaj za 1 sekundo';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Začasno utišaj za 1 minuto';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Začasno utišaj za 10 minut';

  @override
  String get durationOneHourTimeoutPrompt => 'Začasno utišaj za 1 uro';

  @override
  String get durationSixHoursTimeoutPrompt => 'Začasno utišaj za 6 ur';

  @override
  String get durationOneDayTimeoutPrompt => 'Začasno utišaj za 1 dan';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Začasno utišaj za 2 dni';

  @override
  String get durationOneWeekTimeoutPrompt => 'Začasno utišaj za 1 teden';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Začasno utišaj za 2 tedna';

  @override
  String get errorFetchingViewerList =>
      'Seznama gledalcev za ta kanal ni bilo mogoče pridobiti';

  @override
  String get eventsTitle => 'Dogodki';

  @override
  String get followEventConfigTitle => 'Dogodek sledenja';

  @override
  String get customizeYourFollowEvent => 'Prilagodite dogodek sledenja';

  @override
  String get subscribeEventConfigTitle => 'Dogodek naročnine';

  @override
  String get customizeYourSubscriptionEvent => 'Prilagodite dogodek naročnine';

  @override
  String get cheerEventConfigTitle => 'Dogodek Cheer';

  @override
  String get customizeYourCheerEvent => 'Prilagodite dogodek Cheer';

  @override
  String get raidEventConfigTitle => 'Dogodek raida';

  @override
  String get customizeYourRaidEvent => 'Prilagodite dogodek raida';

  @override
  String get hostEventConfigTitle => 'Dogodek gostovanja';

  @override
  String get customizeYourHostEvent => 'Prilagodite dogodek gostovanja';

  @override
  String get hypetrainEventConfigTitle => 'Dogodek Hype Train';

  @override
  String get customizeYourHypetrainEvent => 'Prilagodite dogodek Hype Train';

  @override
  String get pollEventConfigTitle => 'Dogodek ankete';

  @override
  String get customizeYourPollEvent => 'Prilagodite dogodek ankete';

  @override
  String get predictionEventConfigTitle => 'Dogodek napovedi';

  @override
  String get customizeYourPredictionEvent => 'Prilagodite dogodek napovedi';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Dogodek unovčenja točk kanala';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Prilagodite dogodek unovčenja točk kanala';

  @override
  String get outgoingRaidEventConfigTitle => 'Dogodek odhodnega raida';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Prilagodite dogodek odhodnega raida';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> izvaja raid s <b>$viewerCountString</b> gledalci!';
  }

  @override
  String get shoutout => 'Izpostavi';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Izvajanje raida na <b>$displayName</b>...';
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
    return '<b>$displayName</b> je izvedel raid!';
  }

  @override
  String get raidingEventJoin => 'Pridruži se';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Raid kanala <b>$displayName</b> je bil preklican.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> se je naročil na stopnji $tier!';
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

    return '<b>$gifterUserName</b> je podaril $totalString naročnin stopnje $tier, skupno že $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> je naročen že $cumulativeMonthsString mesecev na stopnji $tier!';
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

    return '<b>$subscriberUserName</b> se je naročil na stopnji $tier za $durationMonthsString mesecev vnaprej, skupno $cumulativeMonthsString mesecev!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> je prispeval <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonimnež je prispeval <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> je prispeval <b>$formattedAmount</b> prek StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> je prispeval <b>$formattedAmount</b> prek Streamlabs.';
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

    return '<b>$redeemerUsername</b> je unovčil <b>$rewardName</b> za <b>$rewardCostString</b> točk. $userInput';
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

    return '<b>$redeemerUsername</b> je unovčil <b>$rewardName</b> za <b>$rewardCostString</b> točk.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> je poslal <b>$bitsString</b> bitov. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonimnež';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> gosti s skupino <b>$viewersString</b> gledalcev.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train stopnje <b>$level</b> je v teku! Dokončano: <b>$progressPercent %</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train stopnje <b>$levelString</b> je uspel.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train stopnje <b>$levelString</b> ni uspel.';
  }

  @override
  String get sampleMessage =>
      'To je vzorčno sporočilo za pretvorbo besedila v govor.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author je rekel: $text';
  }

  @override
  String get textToSpeechEnabled => 'Pretvorba besedila v govor je omogočena';

  @override
  String get textToSpeechDisabled =>
      'Pretvorba besedila v govor je onemogočena';

  @override
  String get alertsEnabled => 'Samo opozorila';

  @override
  String get pinDuration => 'Trajanje pripetja';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekund',
      few: '$seconds sekunde',
      two: '$seconds sekundi',
      one: '$seconds sekunda',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minut',
      few: '$minutes minute',
      two: '$minutes minuti',
      one: '$minutes minuta',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Omogoči dogodek';

  @override
  String get showEventInChatHistory => 'Prikaži dogodek v zgodovini klepeta';

  @override
  String get enableShoutouts => 'Omogoči izpostavitve (shoutout)';

  @override
  String get enableShoutoutsSubtitle =>
      'Pošlji povezavo do kanala, ki izvaja raid, v klepet';

  @override
  String get raidConfigurationTitle => 'Nastavitev raida';

  @override
  String get cheerConfigurationTitle => 'Nastavitev Cheer';

  @override
  String get followConfigurationTitle => 'Nastavitev sledenja';

  @override
  String get outgoingRaidConfigurationTitle => 'Nastavitev odhodnega raida';

  @override
  String get hostConfigurationTitle => 'Nastavitev gostovanja';

  @override
  String get channelPointConfigurationTitle => 'Nastavitev točk kanala';

  @override
  String get pollConfigurationTitle => 'Nastavitev ankete';

  @override
  String get hypetrainConfigurationTitle => 'Nastavitev Hype Train';

  @override
  String get subscriptionConfigurationTitle => 'Nastavitev naročnine';

  @override
  String get predictionConfigurationTitle => 'Nastavitev napovedi';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Dodatno trajanje pripetja za neizpolnjene nagrade';

  @override
  String get pollPinDuration => 'Trajanje pripetja po končnem rezultatu';

  @override
  String get hypetrainPinDuration => 'Trajanje pripetja po koncu Hype Traina';

  @override
  String get enableGiftedSubscriptions =>
      'Omogoči posamezne podarjene naročnine';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Prikaži vsako podarjeno naročnino';

  @override
  String get settingsBackupTitle =>
      'Varnostno kopiranje in obnovitev nastavitev';

  @override
  String get cloudBackup => 'Varnostna kopija v oblaku';

  @override
  String get lastBackupNever => 'Zadnja varnostna kopija: nikoli';

  @override
  String get backUp => 'Ustvari varnostno kopijo';

  @override
  String get restore => 'Obnovi';

  @override
  String get localBackup => 'Lokalna varnostna kopija';

  @override
  String get exportSettings => 'Izvozi';

  @override
  String get importSettings => 'Uvozi';

  @override
  String get showViewerAndFollowerCount =>
      'Prikaži število gledalcev in sledilcev';

  @override
  String get screenOrientation => 'Usmerjenost zaslona';

  @override
  String get appTheme => 'Tema aplikacije';

  @override
  String get systemDefault => 'Sistemska';

  @override
  String get portrait => 'Pokončno';

  @override
  String get landscape => 'Ležeče';

  @override
  String get lightTheme => 'Svetla';

  @override
  String get darkTheme => 'Temna';

  @override
  String get openSourceTitle => 'RealtimeChat je odprtokoden';

  @override
  String get openSourceSubtitle => 'Poiščite nas na GitHubu!';

  @override
  String get discordSubtitle => 'Pridružite se strežniku Muxable na Discordu!';

  @override
  String get earlyTestersThanks =>
      'Hvala vsem zgodnjim preizkuševalcem, ki so poslali poročila o napakah!';

  @override
  String get discoModeEnabled => '🕺 Disco način omogočen! :D';

  @override
  String get discoModeDisabled => '🕺 Disco način onemogočen D:';

  @override
  String get playSampleMessage => 'Predvajaj vzorčno sporočilo';

  @override
  String get textToSpeechRate => 'Hitrost govora';

  @override
  String get textToSpeechPitch => 'Višina glasu';

  @override
  String get muteBots => 'Utišaj pretvorbo besedila v govor za bote';

  @override
  String get muteEmotes => 'Utišaj vse emotikone pri branju';

  @override
  String get muteViewerNames => 'Utišaj imena gledalcev pri branju';

  @override
  String get subscribersOnly => 'Samo naročniki';

  @override
  String get fontSize => 'Velikost pisave';

  @override
  String get usernameContrastBoost => 'Povečanje kontrasta uporabniških imen';

  @override
  String get twitchBadgeSettings => 'Nastavitve značk Twitch';

  @override
  String get twitchBadgeSettingsSubtitle => 'Izberite, katere značke so vidne';

  @override
  String get showDeletedMessages => 'Prikaži izbrisana sporočila';

  @override
  String get deletedMessagesGreyedOut => 'Izbrisana sporočila bodo zasivljena';

  @override
  String get deletedMessagesRemoved => 'Izbrisana sporočila bodo odstranjena';

  @override
  String get showLoginNames => 'Prikaži prijavna imena';

  @override
  String get loginNamesShown =>
      'Prijavna imena bodo prikazana, če se razlikujejo od prikaznega imena';

  @override
  String get loginNamesHidden => 'Prijavna imena bodo skrita';

  @override
  String get compactMessages => 'Strnjevanje sporočil';

  @override
  String get dontCompactMessages => 'Ne strnjuj sporočil';

  @override
  String get dontCompactMessagesSubtitle =>
      'Sporočila so prikazana nespremenjena';

  @override
  String get compactIndividualMessages => 'Strni posamezna sporočila';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Ponavljajoče se besedilo v sporočilih je skrajšano';

  @override
  String get announcementPinDuration => 'Trajanje pripetja obvestila';

  @override
  String get idleMessageAlertDuration => 'Opozorilo ob neaktivnem klepetu';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Če toliko časa ni nobenega sporočila in nato prispe novo, se bo predvajal opozorilni zvok.';

  @override
  String get realtimeCashSubtitle => 'Povežite denarnico ETH ali MATIC';

  @override
  String get walletAddress => 'Naslov denarnice';

  @override
  String get streamlabsSubtitle =>
      'Oglejte si svoje donacije v storitvi Streamlabs';

  @override
  String get streamElementsSubtitle =>
      'Oglejte si svoje donacije v storitvi StreamElements';

  @override
  String get thirdPartyAuthError =>
      'Hmm, to ni delovalo. Poskusite znova ali vprašajte na Discordu?';

  @override
  String get companionAuthBrowserTooOld =>
      'Vaš brskalnik je prestar za neposredno prijavo. Skenirajte to kodo QR s telefonom za prijavo v drugi napravi.';

  @override
  String get companionAuthScanQrCode =>
      'Skenirajte to kodo QR s telefonom za prijavo v drugi napravi.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> se je naročil!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> je podaljšal naročnino za $monthsString mesecev!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> je podaril $countString naročnin!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> je poslal $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Prijava s storitvijo Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Preveč je sporočil. Pretvorba besedila v govor je onemogočena';

  @override
  String get turnOffTextToSpeech => 'Izklopi';

  @override
  String get addToChat => 'Dodaj v klepet';

  @override
  String get inChat => 'V klepetu';

  @override
  String get removeFromChat => 'Odstrani iz klepeta';

  @override
  String cantChatWithAccount(String provider) {
    return 'Vaš račun $provider tukaj ne more klepetati';
  }

  @override
  String get cantChatWithAccounts => 'Vaši računi tukaj ne morejo klepetati';

  @override
  String sendAMessageTo(String channel) {
    return 'Pošlji sporočilo na $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Zamenjaj $channel';
  }

  @override
  String get voicePacks => 'Glasovni paketi';

  @override
  String get voicePacksDescription =>
      'Glasovni paketi berejo klepet z naravno zvenečimi glasovi v vaši napravi in po prenosu delujejo brez povezave. Glasove strojno ustvarja umetna inteligenca in jih ni posnel človek.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices glasov',
      few: '$voices glasovi',
      two: '$voices glasova',
      one: '$voices glas',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jezikov',
      few: '$count jeziki',
      two: '$count jezika',
      one: '$count jezik',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Licenca tega modela (OpenRAIL-M) prepoveduje škodljivo uporabo, kot je izdajanje za druge osebe ali širjenje dezinformacij, te omejitve pa veljajo tudi za vas.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Izbrišem paket $pack? S tem boste sprostili $size.';
  }

  @override
  String get voicePackDownload => 'Prenesi';

  @override
  String get voicePackUpdate => 'Posodobi';

  @override
  String get voicePackWaitingForWifi => 'Čakanje na Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Uporabi mobilne podatke';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Prenašanje: $downloaded od $total';
  }

  @override
  String get voicePackInstalling => 'Nameščanje';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Paketa $pack ni bilo mogoče namestiti. Preverite povezavo in poskusite znova.';
  }

  @override
  String get voices => 'Glasovi';

  @override
  String get perViewerVoice => 'Glas za vsakega gledalca';

  @override
  String get perViewerVoiceSubtitle =>
      'Vsak gledalec dobi svoj glas. Izbrani glas bere opozorila ali vse, ko je ta možnost izklopljena.';

  @override
  String get streamLanguage => 'Jezik pretoka';

  @override
  String get ttsEngineNeural => 'Nevronski glas (v napravi)';

  @override
  String get ttsEngineSystem => 'Sistemski glas';

  @override
  String languageUnsupported(String language) {
    return 'Vaši glasovni paketi ne podpirajo jezika $language; uporabljen bo sistemski glas';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Ta naprava nima dovolj pomnilnika za nevronske glasove, zato se klepet bere s sistemskim glasom.';

  @override
  String get neuralFallbackLoadFailed =>
      'Nevronskega glasu ni bilo mogoče naložiti, zato se klepet bere s sistemskim glasom.';

  @override
  String get accounts => 'Računi';

  @override
  String get accountsSubtitle =>
      'Prijavite se v vsako platformo, na kateri oddajate';

  @override
  String addProviderAccount(String provider) {
    return 'Dodaj račun $provider';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Prijava s storitvijo $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Odjava iz kanala $channel v storitvi $provider?';
  }

  @override
  String get signOutOfAll => 'Odjava iz vseh računov';
}
