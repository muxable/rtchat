// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get sendAMessage => 'Lähetä viesti...';

  @override
  String get writeSomething => 'Kirjoita jotain...';

  @override
  String get speakToTheCrowds => 'Puhu yleisölle...';

  @override
  String get shareYourThoughts => 'Jaa ajatuksesi...';

  @override
  String get saySomethingYouLittleBitch =>
      'Sano jotain, senkin pikku narttu...';

  @override
  String get search => 'Hae';

  @override
  String get notSignedIn => 'Et ole kirjautunut sisään';

  @override
  String get searchChannels => 'Hae';

  @override
  String get raidAChannel => 'Raid';

  @override
  String get noMessagesEmptyState => 'Täällä on hiljaista.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uutta viestiä',
      one: '1 uusi viesti',
      zero: 'Ei uusia viestejä',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Kirjaudu palveluun Twitch';

  @override
  String get signInError => 'Kirjautumisessa tapahtui virhe. Yritä uudelleen.';

  @override
  String get continueAsGuest => 'Jatka vieraana';

  @override
  String get signInToSendMessages => 'Kirjaudu sisään lähettääksesi viestejä';

  @override
  String get currentViewers => 'Nykyiset katsojat';

  @override
  String get textToSpeech => 'Tekstin puheeksi muuntaminen';

  @override
  String get streamPreview => 'Lähetyksen esikatselu';

  @override
  String get activityFeed => 'Tapahtumasyöte';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Lähetys alkoi $dateString klo $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Lähetys päättyi $dateString klo $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Keskustelu tyhjennettiin $dateString klo $timeString';
  }

  @override
  String get configureQuickLinks => 'Määritä pikalinkit';

  @override
  String get disableRainMode => 'Poista sadetila käytöstä';

  @override
  String get enableRainMode => 'Ota sadetila käyttöön';

  @override
  String get disableRainModeSubtitle => 'Vuorovaikutus otetaan käyttöön';

  @override
  String get enableRainModeSubtitle => 'Vuorovaikutus poistetaan käytöstä';

  @override
  String get refreshAudioSources => 'Päivitä äänilähteet';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count äänilähdettä päivitetty',
      one: '1 äänilähde päivitetty',
      zero: 'Äänilähteitä ei päivitetty',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Asetukset';

  @override
  String get signOut => 'Kirjaudu ulos';

  @override
  String get cancel => 'Peruuta';

  @override
  String get signOutConfirmation => 'Haluatko varmasti kirjautua ulos?';

  @override
  String get broadcaster => 'Lähettäjä';

  @override
  String get moderators => 'Moderaattorit';

  @override
  String get viewers => 'Katsojat';

  @override
  String get communityVips => 'Yhteisön VIP-jäsenet';

  @override
  String get searchViewers => 'Hae katsojia';

  @override
  String get reconnecting => 'Yhdistetään uudelleen...';

  @override
  String get twitchBadges => 'Twitch-merkit';

  @override
  String get selectAll => 'Valitse kaikki';

  @override
  String get quickLinks => 'Pikalinkit';

  @override
  String get swipeToDeleteQuickLinks =>
      'Poista pikalinkki pyyhkäisemällä vasemmalle tai oikealle';

  @override
  String get quickLinksLabelHint => 'Nimi';

  @override
  String get invalidUrlErrorText =>
      'Tämä ei näytä kelvolliselta URL-osoitteelta';

  @override
  String get duplicateUrlErrorText => 'Tämä linkki on jo olemassa';

  @override
  String get or => 'tai';

  @override
  String get clearCookies => 'Tyhjennä evästeet';

  @override
  String get disabled => 'Ei käytössä';

  @override
  String get twitchActivityFeed => 'Twitchin tapahtumasyöte';

  @override
  String get signInToEnable => 'Tämän käyttöönotto edellyttää kirjautumista';

  @override
  String get customUrl => 'Mukautettu URL-osoite';

  @override
  String get preview => 'Esikatselu';

  @override
  String get audioSources => 'Äänilähteet';

  @override
  String get enableOffStreamSwitchTitle =>
      'Ota käyttöön myös lähetyksen ulkopuolella (kuluttaa enemmän akkua)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Ääntä toistetaan myös, kun et lähetä';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Ääntä toistetaan vain lähetyksen aikana';

  @override
  String get iosOggWarningTitle => 'Hei! Kuuntele!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS ei tue *.ogg-äänitiedostoja, joita Streamlabs käyttää oletuksena. Varmista, että äänilähteesi käyttävät muuta tiedostomuotoa, jotta ne voidaan toistaa.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Mukauta tapahtumasyötettä';

  @override
  String get audioSourcesSubtitle => 'Lisää verkkolähteitä ilmoitusäänille';

  @override
  String get quickLinksSubtitle =>
      'Lisää pikavalintoja usein käytettyihin työkaluihin';

  @override
  String get chatHistory => 'Keskusteluhistoria';

  @override
  String get chatHistorySubtitle => 'Muuta keskustelun ulkoasua';

  @override
  String get textToSpeechSubtitle => 'Muuta puheeksi muuntamisen asetuksia';

  @override
  String get events => 'Tapahtumat';

  @override
  String get eventsSubtitle => 'Määritä Twitch-tapahtumat';

  @override
  String get thirdPartyServices => 'Kolmannen osapuolen palvelut';

  @override
  String get thirdPartyServicesSubtitle =>
      'Yhdistä kolmannen osapuolen palveluun';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> seuraa sinua';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> ja <b>$displayNameTwo</b> seuraavat sinua';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> ja $numOthersString muuta seuraavat sinua';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Poista käyttäjän $displayName mykistys';
  }

  @override
  String muteUser(String displayName) {
    return 'Mykistä $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Anna käyttäjälle $displayName aikajäähy';
  }

  @override
  String banUser(String displayName) {
    return 'Estä $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Poista käyttäjän $displayName esto';
  }

  @override
  String viewProfile(String displayName) {
    return 'Näytä käyttäjän $displayName profiili';
  }

  @override
  String get copyMessage => 'Kopioi viesti';

  @override
  String get deleteMessage => 'Poista viesti';

  @override
  String get longScrollNotification => 'Etkö olekin vierittänyt jo aika kauas?';

  @override
  String get stfu => 'stfu';

  @override
  String get globalEmotes => 'Yleiset emote-kuvat';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString seuraajaa',
      one: '1 seuraaja',
      zero: '0 seuraajaa',
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
      other: '$countString katsojaa',
      one: '1 katsoja',
      zero: '0 katsojaa',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Hei! Mukavaa, että pidät lähetyksen esikatselusta, mutta se kuluttaa paljon akkua. Keskustelun lukeminen ilman esikatselua pidentää akun kestoa.';

  @override
  String get okay => 'OK';

  @override
  String get streamPreviewLoading => 'Ladataan (tai lähetys on päättynyt)...';

  @override
  String get copiedToClipboard => 'Kopioitu leikepöydälle';

  @override
  String get audioSourcesRequirePermissions =>
      'Äänilähteet tarvitsevat käyttöoikeuksia';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Salli RealtimeChatin näkyä muiden sovellusten päällä, jotta voit käyttää äänilähteitä.';

  @override
  String get audioSourcesRemoveButton => 'Poista äänilähteet';

  @override
  String get audioSourcesOpenSettingsButton => 'Avaa asetukset';

  @override
  String get flashOn => 'Salama päälle';

  @override
  String get flashOff => 'Salama pois';

  @override
  String get durationOneSecond => '1 sekunti';

  @override
  String get durationOneMinute => '1 minuutti';

  @override
  String get durationTenMinutes => '10 minuuttia';

  @override
  String get durationOneHour => '1 tunti';

  @override
  String get durationSixHours => '6 tuntia';

  @override
  String get durationOneDay => '1 päivä';

  @override
  String get durationTwoDays => '2 päivää';

  @override
  String get durationOneWeek => '1 viikko';

  @override
  String get durationTwoWeeks => '2 viikkoa';

  @override
  String get durationOneSecondTimeoutPrompt => 'Aikajäähy: 1 sekunti';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Aikajäähy: 1 minuutti';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Aikajäähy: 10 minuuttia';

  @override
  String get durationOneHourTimeoutPrompt => 'Aikajäähy: 1 tunti';

  @override
  String get durationSixHoursTimeoutPrompt => 'Aikajäähy: 6 tuntia';

  @override
  String get durationOneDayTimeoutPrompt => 'Aikajäähy: 1 päivä';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Aikajäähy: 2 päivää';

  @override
  String get durationOneWeekTimeoutPrompt => 'Aikajäähy: 1 viikko';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Aikajäähy: 2 viikkoa';

  @override
  String get errorFetchingViewerList =>
      'Tämän kanavan katsojaluetteloa ei voitu hakea';

  @override
  String get eventsTitle => 'Tapahtumat';

  @override
  String get followEventConfigTitle => 'Seuraamistapahtuma';

  @override
  String get customizeYourFollowEvent => 'Mukauta: Seuraamistapahtuma';

  @override
  String get subscribeEventConfigTitle => 'Tilaustapahtuma';

  @override
  String get customizeYourSubscriptionEvent => 'Mukauta: Tilaustapahtuma';

  @override
  String get cheerEventConfigTitle => 'Kannustustapahtuma';

  @override
  String get customizeYourCheerEvent => 'Mukauta: Kannustustapahtuma';

  @override
  String get raidEventConfigTitle => 'Raid-tapahtuma';

  @override
  String get customizeYourRaidEvent => 'Mukauta: Raid-tapahtuma';

  @override
  String get hostEventConfigTitle => 'Isännöintitapahtuma';

  @override
  String get customizeYourHostEvent => 'Mukauta: Isännöintitapahtuma';

  @override
  String get hypetrainEventConfigTitle => 'Hype Train -tapahtuma';

  @override
  String get customizeYourHypetrainEvent => 'Mukauta: Hype Train -tapahtuma';

  @override
  String get pollEventConfigTitle => 'Äänestystapahtuma';

  @override
  String get customizeYourPollEvent => 'Mukauta: Äänestystapahtuma';

  @override
  String get predictionEventConfigTitle => 'Ennustustapahtuma';

  @override
  String get customizeYourPredictionEvent => 'Mukauta: Ennustustapahtuma';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Kanavapisteiden lunastus';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Mukauta: Kanavapisteiden lunastus';

  @override
  String get outgoingRaidEventConfigTitle => 'Lähtevä raid';

  @override
  String get customizeYourOutgoingRaidEvent => 'Mukauta: Lähtevä raid';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> saapuu raidille <b>$viewerCountString</b> katsojan kanssa!';
  }

  @override
  String get shoutout => 'Kanavasuositus';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Raidataan kanavalle <b>$displayName</b>...';
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
    return '<b>$displayName</b> teki raidin!';
  }

  @override
  String get raidingEventJoin => 'Liity';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Käyttäjän <b>$displayName</b> raid peruttiin.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> tilasi tasolla $tier!';
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

    return '<b>$gifterUserName</b> lahjoitti $totalString tason $tier tilausta, yhteensä $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> on tilannut $cumulativeMonthsString kuukautta tasolla $tier!';
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

    return '<b>$subscriberUserName</b> tilasi tasolla $tier $durationMonthsString kuukaudeksi etukäteen, yhteensä $cumulativeMonthsString kuukautta!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> antoi juomarahaa <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonyymi antoi juomarahaa <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> antoi juomarahaa <b>$formattedAmount</b> StreamElementsissä.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> antoi juomarahaa <b>$formattedAmount</b> Streamlabsissa.';
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

    return '<b>$redeemerUsername</b> lunasti palkinnon <b>$rewardName</b> <b>$rewardCostString</b> pisteellä. $userInput';
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

    return '<b>$redeemerUsername</b> lunasti palkinnon <b>$rewardName</b> <b>$rewardCostString</b> pisteellä.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> kannusti <b>$bitsString</b> bitillä. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonyymi';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> isännöi <b>$viewersString</b> hengen seurueen kanssa.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Trainin taso <b>$level</b> on käynnissä! <b>$progressPercent%</b> valmiina!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Trainin taso <b>$levelString</b> onnistui.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Trainin taso <b>$levelString</b> epäonnistui.';
  }

  @override
  String get sampleMessage =>
      'Tämä on esimerkkiviesti tekstin puheeksi muuntamista varten.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author sanoi: $text';
  }

  @override
  String get textToSpeechEnabled => 'Tekstin puheeksi muuntaminen käytössä';

  @override
  String get textToSpeechDisabled =>
      'Tekstin puheeksi muuntaminen pois käytöstä';

  @override
  String get alertsEnabled => 'Vain ilmoitukset';

  @override
  String get pinDuration => 'Kiinnityksen kesto';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekuntia',
      one: '1 sekunti',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuuttia',
      one: '1 minuutti',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Ota tapahtuma käyttöön';

  @override
  String get showEventInChatHistory => 'Näytä tapahtuma keskusteluhistoriassa';

  @override
  String get enableShoutouts => 'Ota kanavasuositukset käyttöön';

  @override
  String get enableShoutoutsSubtitle =>
      'Lähetä raidattavan kanavan linkki keskusteluun';

  @override
  String get raidConfigurationTitle => 'Asetukset: Raid-tapahtuma';

  @override
  String get cheerConfigurationTitle => 'Asetukset: Kannustustapahtuma';

  @override
  String get followConfigurationTitle => 'Asetukset: Seuraamistapahtuma';

  @override
  String get outgoingRaidConfigurationTitle => 'Asetukset: Lähtevä raid';

  @override
  String get hostConfigurationTitle => 'Asetukset: Isännöintitapahtuma';

  @override
  String get channelPointConfigurationTitle =>
      'Asetukset: Kanavapisteiden lunastus';

  @override
  String get pollConfigurationTitle => 'Asetukset: Äänestystapahtuma';

  @override
  String get hypetrainConfigurationTitle => 'Asetukset: Hype Train -tapahtuma';

  @override
  String get subscriptionConfigurationTitle => 'Asetukset: Tilaustapahtuma';

  @override
  String get predictionConfigurationTitle => 'Asetukset: Ennustustapahtuma';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Täyttämättömien palkintojen lisäkiinnitysaika';

  @override
  String get pollPinDuration => 'Kiinnitysaika tuloksen vahvistamisen jälkeen';

  @override
  String get hypetrainPinDuration => 'Kiinnitysaika Hype Trainin päätyttyä';

  @override
  String get enableGiftedSubscriptions =>
      'Ota yksittäiset lahjatilaukset käyttöön';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Näytä jokainen lahjoitettu tilaus';

  @override
  String get settingsBackupTitle => 'Asetusten varmuuskopiointi ja palautus';

  @override
  String get cloudBackup => 'Pilvivarmuuskopio';

  @override
  String get lastBackupNever => 'Viimeisin varmuuskopio: ei koskaan';

  @override
  String get backUp => 'Varmuuskopioi';

  @override
  String get restore => 'Palauta';

  @override
  String get localBackup => 'Paikallinen varmuuskopio';

  @override
  String get exportSettings => 'Vie';

  @override
  String get importSettings => 'Tuo';

  @override
  String get showViewerAndFollowerCount =>
      'Näytä katsojien ja seuraajien määrä';

  @override
  String get screenOrientation => 'Näytön suunta';

  @override
  String get appTheme => 'Sovelluksen teema';

  @override
  String get systemDefault => 'Järjestelmä';

  @override
  String get portrait => 'Pysty';

  @override
  String get landscape => 'Vaaka';

  @override
  String get lightTheme => 'Vaalea';

  @override
  String get darkTheme => 'Tumma';

  @override
  String get openSourceTitle => 'RealtimeChat on avoimen lähdekoodin sovellus';

  @override
  String get openSourceSubtitle => 'Löydät meidät GitHubista!';

  @override
  String get discordSubtitle => 'Liity Muxablen Discordiin!';

  @override
  String get earlyTestersThanks =>
      'Kiitos kaikille varhaisille testaajille virheraporteista!';

  @override
  String get discoModeEnabled => '🕺 Diskotila käytössä! :D';

  @override
  String get discoModeDisabled => '🕺 Diskotila pois käytöstä D:';

  @override
  String get playSampleMessage => 'Toista esimerkkiviesti';

  @override
  String get textToSpeechRate => 'Puheen nopeus';

  @override
  String get textToSpeechPitch => 'Puheen äänenkorkeus';

  @override
  String get muteBots => 'Mykistä bottien puhe';

  @override
  String get muteEmotes => 'Mykistä kaikki emote-kuvat puheessa';

  @override
  String get muteViewerNames => 'Älä lue katsojien nimiä';

  @override
  String get subscribersOnly => 'Vain tilaajat';

  @override
  String get fontSize => 'Fonttikoko';

  @override
  String get usernameContrastBoost => 'Käyttäjänimien kontrastin vahvistus';

  @override
  String get twitchBadgeSettings => 'Twitch-merkkien asetukset';

  @override
  String get twitchBadgeSettingsSubtitle => 'Valitse näytettävät merkit';

  @override
  String get showDeletedMessages => 'Näytä poistetut viestit';

  @override
  String get deletedMessagesGreyedOut => 'Poistetut viestit näytetään harmaina';

  @override
  String get deletedMessagesRemoved => 'Poistetut viestit piilotetaan';

  @override
  String get showLoginNames => 'Näytä kirjautumisnimet';

  @override
  String get loginNamesShown =>
      'Kirjautumisnimi näytetään, jos se eroaa näyttönimestä';

  @override
  String get loginNamesHidden => 'Kirjautumisnimet piilotetaan';

  @override
  String get compactMessages => 'Tiivistä viestit';

  @override
  String get dontCompactMessages => 'Älä tiivistä viestejä';

  @override
  String get dontCompactMessagesSubtitle => 'Viestit näytetään muuttamattomina';

  @override
  String get compactIndividualMessages => 'Tiivistä yksittäiset viestit';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Viestien toistuvaa tekstiä lyhennetään';

  @override
  String get announcementPinDuration => 'Ilmoitusten kiinnitysaika';

  @override
  String get idleMessageAlertDuration =>
      'Hiljaisen keskustelun äänimerkin viive';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Jos uusia viestejä ei ole tullut tänä aikana, seuraava viesti toistaa ilmoitusäänen.';

  @override
  String get realtimeCashSubtitle => 'Yhdistä ETH- tai MATIC-lompakko';

  @override
  String get walletAddress => 'Lompakon osoite';

  @override
  String get streamlabsSubtitle => 'Näytä Streamlabs-lahjoitukset';

  @override
  String get streamElementsSubtitle => 'Näytä StreamElements-lahjoitukset';

  @override
  String get thirdPartyAuthError =>
      'Hmm, se ei onnistunut. Yritä uudelleen tai kysy Discordissa.';

  @override
  String get companionAuthBrowserTooOld =>
      'Selaimesi on liian vanha suoraan kirjautumiseen. Skannaa QR-koodi puhelimella kirjautuaksesi toisella laitteella.';

  @override
  String get companionAuthScanQrCode =>
      'Skannaa QR-koodi puhelimella kirjautuaksesi toisella laitteella.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> tilasi!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> uusi tilauksensa $monthsString kuukaudeksi!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> lahjoitti $countString tilausta!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> lähetti $amountString Kicksiä!';
  }

  @override
  String get signInWithKick => 'Kirjaudu palveluun Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Viestejä on liian paljon. Tekstin puheeksi muuntaminen poistettiin käytöstä';

  @override
  String get turnOffTextToSpeech => 'Poista käytöstä';

  @override
  String get addToChat => 'Lisää keskusteluun';

  @override
  String get inChat => 'Keskustelussa';

  @override
  String get removeFromChat => 'Poista keskustelusta';

  @override
  String cantChatWithAccount(String provider) {
    return 'Tilisi palvelussa $provider ei voi keskustella täällä';
  }

  @override
  String get cantChatWithAccounts => 'Tilisi eivät voi keskustella täällä';

  @override
  String sendAMessageTo(String channel) {
    return 'Lähetä viesti kanavalle $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Vaihda kanavaksi $channel';
  }

  @override
  String get voicePacks => 'Äänipaketit';

  @override
  String get voicePacksDescription =>
      'Äänipaketit lukevat keskustelua luonnolliselta kuulostavilla äänillä laitteellasi. Lataamisen jälkeen ne toimivat ilman verkkoyhteyttä. Äänet tuotetaan tekoälyllä, eikä niitä ole äänittänyt ihminen.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices ääntä',
      one: '1 ääni',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kieltä',
      one: '1 kieli',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Tämän mallin lisenssi (OpenRAIL-M) kieltää haitallisen käytön, kuten toisena henkilönä esiintymisen ja väärän tiedon levittämisen. Rajoitukset koskevat myös sinua.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Poistetaanko $pack? Tämä vapauttaa $size.';
  }

  @override
  String get voicePackDownload => 'Lataa';

  @override
  String get voicePackUpdate => 'Päivitä';

  @override
  String get voicePackWaitingForWifi => 'Odotetaan Wi-Fi-yhteyttä';

  @override
  String get voicePackUseMobileData => 'Käytä mobiilidataa';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Ladataan: $downloaded / $total';
  }

  @override
  String get voicePackInstalling => 'Asennetaan';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Pakettia $pack ei voitu asentaa. Tarkista yhteys ja yritä uudelleen.';
  }

  @override
  String get voices => 'Äänet';

  @override
  String get perViewerVoice => 'Ääni katsojakohtaisesti';

  @override
  String get perViewerVoiceSubtitle =>
      'Jokainen katsoja saa oman äänen. Valitsemasi ääni lukee ilmoitukset tai kaiken puheen, kun tämä asetus on pois käytöstä.';

  @override
  String get streamLanguage => 'Lähetyksen kieli';

  @override
  String get ttsEngineNeural => 'Neuraalinen ääni (laitteella)';

  @override
  String get ttsEngineSystem => 'Järjestelmän ääni';

  @override
  String languageUnsupported(String language) {
    return 'Äänipakettisi eivät tue kieltä $language. Käytetään järjestelmän ääntä';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Tämän laitteen muisti ei riitä neuraalisille äänille. Keskustelu luetaan järjestelmän äänellä.';

  @override
  String get neuralFallbackLoadFailed =>
      'Neuraalista ääntä ei voitu ladata. Keskustelu luetaan järjestelmän äänellä.';

  @override
  String get accounts => 'Tilit';

  @override
  String get accountsSubtitle => 'Kirjaudu jokaiseen palveluun, jossa lähetät';

  @override
  String addProviderAccount(String provider) {
    return 'Lisää $provider-tili';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Kirjaudu palveluun $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Kirjaudutaanko ulos kanavalta $channel palvelussa $provider?';
  }

  @override
  String get signOutOfAll => 'Kirjaudu ulos kaikista tileistä';
}
