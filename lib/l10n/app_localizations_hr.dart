// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'package:rtchat/l10n/app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get sendAMessage => 'Pošalji poruku...';

  @override
  String get writeSomething => 'Napiši nešto...';

  @override
  String get speakToTheCrowds => 'Obratite se publici...';

  @override
  String get shareYourThoughts => 'Podijelite svoje misli...';

  @override
  String get saySomethingYouLittleBitch => 'Reci nešto, mala kujice...';

  @override
  String get search => 'Pretraži';

  @override
  String get notSignedIn => 'Niste prijavljeni';

  @override
  String get searchChannels => 'Pretraži';

  @override
  String get raidAChannel => 'Raid kanala';

  @override
  String get noMessagesEmptyState => 'Ovdje je tiho.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count novih poruka',
      few: '$count nove poruke',
      one: '$count nova poruka',
      zero: 'Nema novih poruka',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Prijavi se putem Twitcha';

  @override
  String get signInError =>
      'Došlo je do pogreške prilikom prijave. Pokušajte ponovno.';

  @override
  String get continueAsGuest => 'Nastavi kao gost';

  @override
  String get signInToSendMessages => 'Prijavite se za slanje poruka';

  @override
  String get currentViewers => 'Trenutačni gledatelji';

  @override
  String get textToSpeech => 'Pretvaranje teksta u govor';

  @override
  String get streamPreview => 'Pregled prijenosa';

  @override
  String get activityFeed => 'Sažetak aktivnosti';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Prijenos uživo: $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Prijenos izvan mreže: $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Chat je očišćen: $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Konfiguriraj brze poveznice';

  @override
  String get disableRainMode => 'Onemogući način rada za kišu';

  @override
  String get enableRainMode => 'Omogući način rada za kišu';

  @override
  String get disableRainModeSubtitle => 'Interakcija će biti omogućena';

  @override
  String get enableRainModeSubtitle => 'Interakcija će biti onemogućena';

  @override
  String get refreshAudioSources => 'Osvježi izvore zvuka';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count izvora zvuka je osvježeno',
      few: '$count izvora zvuka su osvježena',
      one: '$count izvor zvuka je osvježen',
      zero: 'Nijedan izvor zvuka nije osvježen',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Postavke';

  @override
  String get signOut => 'Odjava';

  @override
  String get cancel => 'Odustani';

  @override
  String get signOutConfirmation => 'Jeste li sigurni da se želite odjaviti?';

  @override
  String get broadcaster => 'Voditelj prijenosa';

  @override
  String get moderators => 'Moderatori';

  @override
  String get viewers => 'Gledatelji';

  @override
  String get communityVips => 'VIP članovi zajednice';

  @override
  String get searchViewers => 'Pretraži gledatelje';

  @override
  String get reconnecting => 'Ponovno povezivanje...';

  @override
  String get twitchBadges => 'Twitch značke';

  @override
  String get selectAll => 'Odaberi sve';

  @override
  String get quickLinks => 'Brze poveznice';

  @override
  String get swipeToDeleteQuickLinks =>
      'Povucite ulijevo ili udesno za brisanje brze poveznice';

  @override
  String get quickLinksLabelHint => 'Oznaka';

  @override
  String get invalidUrlErrorText => 'Ovo ne izgleda kao valjani URL';

  @override
  String get duplicateUrlErrorText => 'Ova poveznica već postoji';

  @override
  String get or => 'ili';

  @override
  String get clearCookies => 'Očisti kolačiće';

  @override
  String get disabled => 'Onemogućeno';

  @override
  String get twitchActivityFeed => 'Twitch sažetak aktivnosti';

  @override
  String get signInToEnable =>
      'Morate biti prijavljeni kako biste ovo omogućili';

  @override
  String get customUrl => 'Prilagođeni URL';

  @override
  String get preview => 'Pregled';

  @override
  String get audioSources => 'Izvori zvuka';

  @override
  String get enableOffStreamSwitchTitle =>
      'Omogući izvan prijenosa (troši više baterije)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Zvuk će se reproducirati i kada niste uživo';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Zvuk će se reproducirati samo kada ste uživo';

  @override
  String get iosOggWarningTitle => 'Hej! Slušaj!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS ne podržava medijske datoteke *.ogg, koje su zadane datoteke na platformi Streamlabs. Provjerite koriste li vaši izvori zvuka drugi format, inače se neće reproducirati.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Prilagodite svoj sažetak aktivnosti';

  @override
  String get audioSourcesSubtitle => 'Dodajte web-izvore za zvukove obavijesti';

  @override
  String get quickLinksSubtitle => 'Dodajte prečace do često korištenih alata';

  @override
  String get chatHistory => 'Povijest chata';

  @override
  String get chatHistorySubtitle => 'Promijenite izgled chata';

  @override
  String get textToSpeechSubtitle =>
      'Promijenite postavke pretvaranja teksta u govor';

  @override
  String get events => 'Događaji';

  @override
  String get eventsSubtitle => 'Konfigurirajte Twitch događaje';

  @override
  String get thirdPartyServices => 'Usluge trećih strana';

  @override
  String get thirdPartyServicesSubtitle => 'Povežite se s uslugom treće strane';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> vas prati';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> i <b>$displayNameTwo</b> vas prate';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> i još $numOthersString vas prate';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Uključi zvuk za $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Isključi zvuk za $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Privremeno udalji $displayName';
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
    return 'Prikaži profil korisnika $displayName';
  }

  @override
  String get copyMessage => 'Kopiraj poruku';

  @override
  String get deleteMessage => 'Izbriši poruku';

  @override
  String get longScrollNotification =>
      'Prilično ste daleko odskrolali, zar ne?';

  @override
  String get stfu => 'ušuti';

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
      other: '$countString pratitelja',
      few: '$countString pratitelja',
      one: '$countString pratitelj',
      zero: '0 pratitelja',
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
      other: '$countString gledatelja',
      few: '$countString gledatelja',
      one: '$countString gledatelj',
      zero: '0 gledatelja',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Bok! Drago nam je što koristite pregled prijenosa, no imajte na umu da troši puno baterije. Čitanje chata bez njega produljit će trajanje baterije.';

  @override
  String get okay => 'U redu';

  @override
  String get streamPreviewLoading =>
      'Učitavanje (ili je prijenos izvan mreže)...';

  @override
  String get copiedToClipboard => 'Kopirano u međuspremnik';

  @override
  String get audioSourcesRequirePermissions =>
      'Izvori zvuka zahtijevaju dopuštenja';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Odobrite aplikaciji RealtimeChat prikaz preko drugih aplikacija kako biste koristili izvore zvuka.';

  @override
  String get audioSourcesRemoveButton => 'Ukloni izvore zvuka';

  @override
  String get audioSourcesOpenSettingsButton => 'Otvori postavke';

  @override
  String get flashOn => 'Bljeskalica uključena';

  @override
  String get flashOff => 'Bljeskalica isključena';

  @override
  String get durationOneSecond => '1 sekunda';

  @override
  String get durationOneMinute => '1 minuta';

  @override
  String get durationTenMinutes => '10 minuta';

  @override
  String get durationOneHour => '1 sat';

  @override
  String get durationSixHours => '6 sati';

  @override
  String get durationOneDay => '1 dan';

  @override
  String get durationTwoDays => '2 dana';

  @override
  String get durationOneWeek => '1 tjedan';

  @override
  String get durationTwoWeeks => '2 tjedna';

  @override
  String get durationOneSecondTimeoutPrompt =>
      'Privremena zabrana na 1 sekundu';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Privremena zabrana na 1 minutu';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      'Privremena zabrana na 10 minuta';

  @override
  String get durationOneHourTimeoutPrompt => 'Privremena zabrana na 1 sat';

  @override
  String get durationSixHoursTimeoutPrompt => 'Privremena zabrana na 6 sati';

  @override
  String get durationOneDayTimeoutPrompt => 'Privremena zabrana na 1 dan';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Privremena zabrana na 2 dana';

  @override
  String get durationOneWeekTimeoutPrompt => 'Privremena zabrana na 1 tjedan';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Privremena zabrana na 2 tjedna';

  @override
  String get errorFetchingViewerList =>
      'Nismo uspjeli dohvatiti popis gledatelja za ovaj kanal';

  @override
  String get eventsTitle => 'Događaji';

  @override
  String get followEventConfigTitle => 'Događaj praćenja';

  @override
  String get customizeYourFollowEvent => 'Prilagodite događaj praćenja';

  @override
  String get subscribeEventConfigTitle => 'Događaj pretplate';

  @override
  String get customizeYourSubscriptionEvent => 'Prilagodite događaj pretplate';

  @override
  String get cheerEventConfigTitle => 'Događaj bodrenja';

  @override
  String get customizeYourCheerEvent => 'Prilagodite događaj bodrenja';

  @override
  String get raidEventConfigTitle => 'Događaj raida';

  @override
  String get customizeYourRaidEvent => 'Prilagodite događaj raida';

  @override
  String get hostEventConfigTitle => 'Događaj ugošćivanja';

  @override
  String get customizeYourHostEvent => 'Prilagodite događaj ugošćivanja';

  @override
  String get hypetrainEventConfigTitle => 'Događaj Hype Train';

  @override
  String get customizeYourHypetrainEvent => 'Prilagodite događaj Hype Train';

  @override
  String get pollEventConfigTitle => 'Događaj ankete';

  @override
  String get customizeYourPollEvent => 'Prilagodite događaj ankete';

  @override
  String get predictionEventConfigTitle => 'Događaj predviđanja';

  @override
  String get customizeYourPredictionEvent => 'Prilagodite događaj predviđanja';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Događaj iskorištavanja bodova kanala';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Prilagodite događaj iskorištavanja bodova kanala';

  @override
  String get outgoingRaidEventConfigTitle => 'Događaj odlaznog raida';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Prilagodite događaj odlaznog raida';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> radi raid s <b>$viewerCountString</b> gledatelja!';
  }

  @override
  String get shoutout => 'Preporuka';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Raidanje kanala <b>$displayName</b>...';
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
    return '<b>$displayName</b> je napravio raid!';
  }

  @override
  String get raidingEventJoin => 'Pridruži se';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Raid korisnika <b>$displayName</b> je otkazan.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> se pretplatio na razini $tier!';
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

    return '<b>$gifterUserName</b> je darovao $totalString pretplata razine $tier, ukupno $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> je pretplaćen $cumulativeMonthsString mjeseci na razini $tier!';
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

    return '<b>$subscriberUserName</b> se pretplatio na razini $tier na $durationMonthsString mjeseci unaprijed, ukupno $cumulativeMonthsString mjeseci!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> je dao napojnicu od <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonimni korisnik je dao napojnicu od <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> je dao napojnicu od <b>$formattedAmount</b> na platformi StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> je dao napojnicu od <b>$formattedAmount</b> na platformi Streamlabs.';
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

    return '<b>$redeemerUsername</b> je iskoristio <b>$rewardName</b> za <b>$rewardCostString</b> bodova. $userInput';
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

    return '<b>$redeemerUsername</b> je iskoristio <b>$rewardName</b> za <b>$rewardCostString</b> bodova.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> je poslao <b>$bitsString</b> bitova. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonimno';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> ugošćuje sa skupinom od <b>$viewersString</b> gledatelja.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train razine <b>$level</b> je u tijeku! Dovršeno <b>$progressPercent%</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train razine <b>$levelString</b> je uspio.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train razine <b>$levelString</b> nije uspio.';
  }

  @override
  String get sampleMessage =>
      'Ovo je primjer poruke za pretvaranje teksta u govor.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author je rekao: $text';
  }

  @override
  String get textToSpeechEnabled => 'Pretvaranje teksta u govor je omogućeno';

  @override
  String get textToSpeechDisabled =>
      'Pretvaranje teksta u govor je onemogućeno';

  @override
  String get alertsEnabled => 'Samo obavijesti';

  @override
  String get pinDuration => 'Trajanje prikvačivanja';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekundi',
      few: '$seconds sekunde',
      one: '$seconds sekunda',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuta',
      few: '$minutes minute',
      one: '$minutes minuta',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Omogući događaj';

  @override
  String get showEventInChatHistory => 'Prikaži događaj u povijesti chata';

  @override
  String get enableShoutouts => 'Omogući preporuke';

  @override
  String get enableShoutoutsSubtitle =>
      'Pošalji poveznicu na kanal koji radi raid u chat';

  @override
  String get raidConfigurationTitle => 'Konfiguracija raida';

  @override
  String get cheerConfigurationTitle => 'Konfiguracija bodrenja';

  @override
  String get followConfigurationTitle => 'Konfiguracija praćenja';

  @override
  String get outgoingRaidConfigurationTitle => 'Konfiguracija odlaznog raida';

  @override
  String get hostConfigurationTitle => 'Konfiguracija ugošćivanja';

  @override
  String get channelPointConfigurationTitle => 'Konfiguracija bodova kanala';

  @override
  String get pollConfigurationTitle => 'Konfiguracija ankete';

  @override
  String get hypetrainConfigurationTitle => 'Konfiguracija za Hype Train';

  @override
  String get subscriptionConfigurationTitle => 'Konfiguracija pretplate';

  @override
  String get predictionConfigurationTitle => 'Konfiguracija predviđanja';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Dodatno trajanje prikvačivanja za neispunjene nagrade';

  @override
  String get pollPinDuration =>
      'Trajanje prikvačivanja nakon konačnog rezultata';

  @override
  String get hypetrainPinDuration =>
      'Trajanje prikvačivanja nakon završetka događaja Hype Train';

  @override
  String get enableGiftedSubscriptions =>
      'Omogući pojedinačne darovane pretplate';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Prikaži svaku darovanu pretplatu';

  @override
  String get settingsBackupTitle => 'Sigurnosno kopiranje i vraćanje postavki';

  @override
  String get cloudBackup => 'Sigurnosna kopija u oblaku';

  @override
  String get lastBackupNever => 'Posljednja sigurnosna kopija: nikada';

  @override
  String get backUp => 'Sigurnosno kopiraj';

  @override
  String get restore => 'Vrati';

  @override
  String get localBackup => 'Lokalna sigurnosna kopija';

  @override
  String get exportSettings => 'Izvezi';

  @override
  String get importSettings => 'Uvezi';

  @override
  String get showViewerAndFollowerCount =>
      'Prikaži broj gledatelja i pratitelja';

  @override
  String get screenOrientation => 'Orijentacija zaslona';

  @override
  String get appTheme => 'Tema aplikacije';

  @override
  String get systemDefault => 'Sustav';

  @override
  String get portrait => 'Portret';

  @override
  String get landscape => 'Pejzaž';

  @override
  String get lightTheme => 'Svijetla';

  @override
  String get darkTheme => 'Tamna';

  @override
  String get openSourceTitle => 'RealtimeChat je otvorenog koda';

  @override
  String get openSourceSubtitle => 'Pronađite nas na GitHubu!';

  @override
  String get discordSubtitle => 'Pridružite se Muxable Discord poslužitelju!';

  @override
  String get earlyTestersThanks =>
      'Hvala svim ranim testerima koji su poslali prijave pogrešaka!';

  @override
  String get discoModeEnabled => '🕺 Disko način rada je omogućen! :D';

  @override
  String get discoModeDisabled => '🕺 Disko način rada je onemogućen D:';

  @override
  String get playSampleMessage => 'Reproduciraj oglednu poruku';

  @override
  String get textToSpeechRate => 'Brzina pretvaranja teksta u govor';

  @override
  String get textToSpeechPitch => 'Visina glasa za pretvaranje teksta u govor';

  @override
  String get muteBots => 'Isključi čitanje poruka botova';

  @override
  String get muteEmotes => 'Isključi čitanje emotikona';

  @override
  String get muteViewerNames => 'Isključi čitanje imena gledatelja';

  @override
  String get subscribersOnly => 'Samo pretplatnici';

  @override
  String get fontSize => 'Veličina fonta';

  @override
  String get usernameContrastBoost => 'Pojačanje kontrasta korisničkog imena';

  @override
  String get twitchBadgeSettings => 'Postavke Twitch znački';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Upravljajte time koje su značke vidljive';

  @override
  String get showDeletedMessages => 'Prikaži izbrisane poruke';

  @override
  String get deletedMessagesGreyedOut => 'Izbrisane poruke bit će zasivljene';

  @override
  String get deletedMessagesRemoved => 'Izbrisane poruke bit će uklonjene';

  @override
  String get showLoginNames => 'Prikaži korisnička imena za prijavu';

  @override
  String get loginNamesShown =>
      'Korisnička imena za prijavu bit će prikazana ako se razlikuju od prikazanog imena';

  @override
  String get loginNamesHidden => 'Korisnička imena za prijavu bit će skrivena';

  @override
  String get compactMessages => 'Sažimanje poruka';

  @override
  String get dontCompactMessages => 'Ne sažimaj poruke';

  @override
  String get dontCompactMessagesSubtitle =>
      'Poruke se prikazuju nepromijenjene';

  @override
  String get compactIndividualMessages => 'Sažmi pojedinačne poruke';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Ponavljajući tekst u porukama se skraćuje';

  @override
  String get announcementPinDuration => 'Trajanje prikvačivanja obavijesti';

  @override
  String get idleMessageAlertDuration =>
      'Trajanje neaktivnosti za zvučnu obavijest';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Ako tijekom ovog vremena nema poruka i stigne nova, oglasit će se zvuk obavijesti.';

  @override
  String get realtimeCashSubtitle => 'Povežite ETH ili MATIC novčanik';

  @override
  String get walletAddress => 'Adresa novčanika';

  @override
  String get streamlabsSubtitle => 'Pogledajte svoje Streamlabs donacije';

  @override
  String get streamElementsSubtitle =>
      'Pogledajte svoje StreamElements donacije';

  @override
  String get thirdPartyAuthError =>
      'Hm, to nije uspjelo. Pokušajte ponovno ili pitajte na Discordu?';

  @override
  String get companionAuthBrowserTooOld =>
      'Vaš je preglednik prestar za izravnu prijavu. Skenirajte ovaj QR kod telefonom kako biste se prijavili na drugom uređaju.';

  @override
  String get companionAuthScanQrCode =>
      'Skenirajte ovaj QR kod telefonom kako biste se prijavili na drugom uređaju.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> se pretplatio!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> je obnovio pretplatu na $monthsString mjeseci!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> je darovao $countString pretplata!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> je poslao $amountString Kicksa!';
  }

  @override
  String get signInWithKick => 'Prijavi se putem Kicka';

  @override
  String get textToSpeechTooManyMessages =>
      'Ima previše poruka. Pretvaranje teksta u govor je onemogućeno';

  @override
  String get turnOffTextToSpeech => 'Isključi';

  @override
  String get addToChat => 'Dodaj u chat';

  @override
  String get inChat => 'U chatu';

  @override
  String get removeFromChat => 'Ukloni iz chata';

  @override
  String cantChatWithAccount(String provider) {
    return 'Vaš $provider račun ne može pisati u chatu ovdje';
  }

  @override
  String get cantChatWithAccounts => 'Vaši računi ne mogu pisati u chatu ovdje';

  @override
  String sendAMessageTo(String channel) {
    return 'Pošalji poruku kanalu $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Zamijeni $channel';
  }

  @override
  String get voicePacks => 'Glasovni paketi';

  @override
  String get voicePacksDescription =>
      'Glasovni paketi čitaju chat prirodnim glasovima koji rade na vašem uređaju, izvan mreže nakon preuzimanja. Glasove strojno generira umjetna inteligencija, nije ih snimila osoba.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices glasova',
      few: '$voices glasa',
      one: '$voices glas',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jezika',
      few: '$count jezika',
      one: '$count jezik',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Licenca ovog modela (OpenRAIL-M) zabranjuje štetnu upotrebu, poput lažnog predstavljanja ili širenja dezinformacija, a ta se ograničenja odnose i na vas.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Izbrisati paket $pack? Time se oslobađa $size.';
  }

  @override
  String get voicePackDownload => 'Preuzmi';

  @override
  String get voicePackUpdate => 'Ažuriraj';

  @override
  String get voicePackWaitingForWifi => 'Čekanje na Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Koristi mobilne podatke';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Preuzimanje: $downloaded od $total';
  }

  @override
  String get voicePackInstalling => 'Instaliranje';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Instaliranje paketa $pack nije uspjelo. Provjerite vezu i pokušajte ponovno.';
  }

  @override
  String get voices => 'Glasovi';

  @override
  String get perViewerVoice => 'Glas po gledatelju';

  @override
  String get perViewerVoiceSubtitle =>
      'Svaki gledatelj dobiva vlastiti glas. Glas koji odaberete čita obavijesti ili sve kada je ova opcija isključena.';

  @override
  String get streamLanguage => 'Jezik prijenosa';

  @override
  String get ttsEngineNeural => 'Neuronski glas (na uređaju)';

  @override
  String get ttsEngineSystem => 'Glas sustava';

  @override
  String languageUnsupported(String language) {
    return 'Vaši glasovni paketi ne podržavaju jezik ($language); koristit će se glas sustava';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Ovaj uređaj nema dovoljno memorije za neuronske glasove, pa se chat čita glasom sustava.';

  @override
  String get neuralFallbackLoadFailed =>
      'Neuronski glas nije se mogao učitati, pa se chat čita glasom sustava.';

  @override
  String get accounts => 'Računi';

  @override
  String get accountsSubtitle =>
      'Prijavite se na svaku platformu na kojoj emitirate';

  @override
  String addProviderAccount(String provider) {
    return 'Dodaj $provider račun';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Prijavi se putem platforme $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Odjaviti se s kanala $channel na platformi $provider?';
  }

  @override
  String get signOutOfAll => 'Odjavi se sa svih računa';
}
