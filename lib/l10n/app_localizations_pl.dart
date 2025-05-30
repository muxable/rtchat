// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get sendAMessage => 'Wyślij wiadomość...';

  @override
  String get writeSomething => 'Napisz coś...';

  @override
  String get speakToTheCrowds => 'Mów do tłumów...';

  @override
  String get shareYourThoughts => 'Podziel się swoimi myślami...';

  @override
  String get saySomethingYouLittleBitch => 'Powiedz coś, ty mała suko...';

  @override
  String get search => 'Szukaj';

  @override
  String get notSignedIn => 'Nie zalogowany';

  @override
  String get searchChannels => 'Szukaj kanałów';

  @override
  String get raidAChannel => 'Najazd na kanał';

  @override
  String get noMessagesEmptyState => 'Brak wiadomości';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nowych wiadomości',
      one: '1 nowa wiadomość',
      zero: 'Brak nowych wiadomości',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Zaloguj się przez Twitch';

  @override
  String get signInError =>
      'Wystąpił błąd podczas logowania. Spróbuj ponownie.';

  @override
  String get continueAsGuest => 'Kontynuuj jako gość';

  @override
  String get signInToSendMessages => 'Zaloguj się, aby wysyłać wiadomości';

  @override
  String get currentViewers => 'Obecni widzowie';

  @override
  String get textToSpeech => 'Tekst na mowę';

  @override
  String get streamPreview => 'Podgląd strumienia';

  @override
  String get activityFeed => 'Kanał aktywności';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Strumień online od $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Strumień offline od $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Czat wyczyszczony o $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Konfiguruj szybkie linki';

  @override
  String get disableRainMode => 'Wyłącz tryb deszczu';

  @override
  String get enableRainMode => 'Włącz tryb deszczu';

  @override
  String get disableRainModeSubtitle => 'Interakcja będzie włączona';

  @override
  String get enableRainModeSubtitle => 'Interakcja będzie wyłączona';

  @override
  String get refreshAudioSources => 'Odśwież źródła dźwięku';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count źródeł dźwięku odświeżonych',
      one: '1 źródło dźwięku odświeżone',
      zero: 'Brak odświeżonych źródeł dźwięku',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Ustawienia';

  @override
  String get signOut => 'Wyloguj się';

  @override
  String get cancel => 'Anuluj';

  @override
  String get signOutConfirmation => 'Czy na pewno chcesz się wylogować?';

  @override
  String get broadcaster => 'Nadawca';

  @override
  String get moderators => 'Moderatorzy';

  @override
  String get viewers => 'Widzowie';

  @override
  String get communityVips => 'VIP-y społeczności';

  @override
  String get searchViewers => 'Szukaj widzów';

  @override
  String get reconnecting => 'Ponowne łączenie...';

  @override
  String get twitchBadges => 'Odznaki Twitch';

  @override
  String get selectAll => 'Zaznacz wszystko';

  @override
  String get quickLinks => 'Szybkie linki';

  @override
  String get swipeToDeleteQuickLinks => 'Przesuń, aby usunąć szybki link';

  @override
  String get quickLinksLabelHint => 'Etykieta';

  @override
  String get invalidUrlErrorText => 'To nie wygląda na prawidłowy URL';

  @override
  String get duplicateUrlErrorText => 'Ten link już istnieje';

  @override
  String get or => 'lub';

  @override
  String get clearCookies => 'Wyczyść ciasteczka';

  @override
  String get disabled => 'Wyłączone';

  @override
  String get twitchActivityFeed => 'Kanał aktywności Twitch';

  @override
  String get signInToEnable => 'Musisz się zalogować, aby to włączyć';

  @override
  String get customUrl => 'Niestandardowy URL';

  @override
  String get preview => 'Podgląd';

  @override
  String get audioSources => 'Źródła dźwięku';

  @override
  String get enableOffStreamSwitchTitle =>
      'Włącz poza strumieniem (zużywa więcej baterii)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Dźwięk będzie odtwarzany również, gdy jesteś offline';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Dźwięk będzie odtwarzany tylko, gdy jesteś na żywo';

  @override
  String get iosOggWarningTitle => 'Hej! Słuchaj!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS nie obsługuje plików multimedialnych *.ogg, które są domyślnymi plikami w Streamlabs. Upewnij się, że twoje źródła dźwięku używają innego formatu, w przeciwnym razie nie będą odtwarzane.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Dostosuj swój kanał aktywności';

  @override
  String get audioSourcesSubtitle =>
      'Dodaj źródła internetowe dla dźwięków alertów';

  @override
  String get quickLinksSubtitle => 'Dodaj skróty do często używanych narzędzi';

  @override
  String get chatHistory => 'Historia czatu';

  @override
  String get chatHistorySubtitle => 'Zmień wygląd czatu';

  @override
  String get textToSpeechSubtitle => 'Zmień ustawienia tekstu na mowę';

  @override
  String get events => 'Wydarzenia';

  @override
  String get eventsSubtitle => 'Konfiguruj wydarzenia Twitch';

  @override
  String get thirdPartyServices => 'Usługi zewnętrzne';

  @override
  String get thirdPartyServicesSubtitle => 'Połącz się z usługą zewnętrzną';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> obserwuje cię';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> i <b>$displayNameTwo</b> obserwują cię';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b> i $numOthersString innych obserwują cię';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Wyłącz wyciszenie $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Wycisz $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Czasowe wyciszenie $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Zablokuj $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Odblokuj $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Zobacz profil $displayName';
  }

  @override
  String get copyMessage => 'Kopiuj wiadomość';

  @override
  String get deleteMessage => 'Usuń wiadomość';

  @override
  String get longScrollNotification => 'Przewijasz dość daleko, nie sądzisz?';

  @override
  String get stfu => 'zamknij się';

  @override
  String get globalEmotes => 'Globalne emotikony';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString obserwujących',
      one: '1 obserwujący',
      zero: '0 obserwujących',
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
      other: '$countString widzów',
      one: '1 widz',
      zero: '0 widzów',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Hej! Cieszymy się, że lubisz korzystać z podglądu strumienia, ale pamiętaj, że zużywa on dużo baterii. Czytanie czatu bez niego wydłuży czas pracy baterii.';

  @override
  String get okay => 'OK';

  @override
  String get streamPreviewLoading => 'Ładowanie (lub strumień jest offline)...';

  @override
  String get copiedToClipboard => 'Skopiowano do schowka';

  @override
  String get audioSourcesRequirePermissions =>
      'Źródła dźwięku wymagają uprawnień';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Zezwól RealtimeChat na rysowanie nad innymi aplikacjami, aby korzystać ze źródeł dźwięku.';

  @override
  String get audioSourcesRemoveButton => 'Usuń źródła dźwięku';

  @override
  String get audioSourcesOpenSettingsButton => 'Otwórz ustawienia';

  @override
  String get flashOn => 'Włącz lampę błyskową';

  @override
  String get flashOff => 'Wyłącz lampę błyskową';

  @override
  String get durationOneSecond => '1 sekunda';

  @override
  String get durationOneMinute => '1 minuta';

  @override
  String get durationTenMinutes => '10 minut';

  @override
  String get durationOneHour => '1 godzina';

  @override
  String get durationSixHours => '6 godzin';

  @override
  String get durationOneDay => '1 dzień';

  @override
  String get durationTwoDays => '2 dni';

  @override
  String get durationOneWeek => '1 tydzień';

  @override
  String get durationTwoWeeks => '2 tygodnie';

  @override
  String get durationOneSecondTimeoutPrompt =>
      'Czasowe wyciszenie na 1 sekundę';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Czasowe wyciszenie na 1 minutę';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      'Czasowe wyciszenie na 10 minut';

  @override
  String get durationOneHourTimeoutPrompt => 'Czasowe wyciszenie na 1 godzinę';

  @override
  String get durationSixHoursTimeoutPrompt => 'Czasowe wyciszenie na 6 godzin';

  @override
  String get durationOneDayTimeoutPrompt => 'Czasowe wyciszenie na 1 dzień';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Czasowe wyciszenie na 2 dni';

  @override
  String get durationOneWeekTimeoutPrompt => 'Czasowe wyciszenie na 1 tydzień';

  @override
  String get durationTwoWeeksTimeoutPrompt =>
      'Czasowe wyciszenie na 2 tygodnie';

  @override
  String get errorFetchingViewerList =>
      'Nie udało się pobrać listy widzów dla tego kanału';

  @override
  String get eventsTitle => 'Wydarzenia';

  @override
  String get followEventConfigTitle => 'Wydarzenie obserwowania';

  @override
  String get customizeYourFollowEvent =>
      'Dostosuj swoje wydarzenie obserwowania';

  @override
  String get subscribeEventConfigTitle => 'Wydarzenie subskrypcji';

  @override
  String get customizeYourSubscriptionEvent =>
      'Dostosuj swoje wydarzenie subskrypcji';

  @override
  String get cheerEventConfigTitle => 'Wydarzenie cheer';

  @override
  String get customizeYourCheerEvent => 'Dostosuj swoje wydarzenie cheer';

  @override
  String get raidEventConfigTitle => 'Wydarzenie najazdu';

  @override
  String get customizeYourRaidEvent => 'Dostosuj swoje wydarzenie najazdu';

  @override
  String get hostEventConfigTitle => 'Wydarzenie hostowania';

  @override
  String get customizeYourHostEvent => 'Dostosuj swoje wydarzenie hostowania';

  @override
  String get hypetrainEventConfigTitle => 'Wydarzenie hypetrain';

  @override
  String get customizeYourHypetrainEvent =>
      'Dostosuj swoje wydarzenie hypetrain';

  @override
  String get pollEventConfigTitle => 'Wydarzenie ankiety';

  @override
  String get customizeYourPollEvent => 'Dostosuj swoje wydarzenie ankiety';

  @override
  String get predictionEventConfigTitle => 'Wydarzenie przewidywania';

  @override
  String get customizeYourPredictionEvent =>
      'Dostosuj swoje wydarzenie przewidywania';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Wydarzenie wymiany punktów kanału';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Dostosuj swoje wydarzenie wymiany punktów kanału';

  @override
  String get outgoingRaidEventConfigTitle => 'Wydarzenie wychodzącego najazdu';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Dostosuj swoje wydarzenie wychodzącego najazdu';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b> przeprowadza najazd z <b>$viewerCountString</b> widzami!';
  }

  @override
  String get shoutout => 'Shoutout';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Najazd na <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Pozostało $secondsString sekund';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> przeprowadził najazd!';
  }

  @override
  String get raidingEventJoin => 'Dołącz';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Najazd <b>$displayName</b> został anulowany.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> zasubskrybował na poziomie $tier!';
  }

  @override
  String subscriptionGiftEvent(
      String gifterUserName, int total, String tier, int cumulativeTotal) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat cumulativeTotalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeTotalString =
        cumulativeTotalNumberFormat.format(cumulativeTotal);

    return '<b>$gifterUserName</b> podarował $totalString subskrypcji na poziomie $tier, łącznie $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> zasubskrybował na poziomie $tier przez $cumulativeMonthsString miesięcy!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> dał napiwek w wysokości <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonimowy dał napiwek w wysokości <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> dał napiwek w wysokości <b>$formattedAmount</b> na StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> dał napiwek w wysokości <b>$formattedAmount</b> na Streamlabs.';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> wymienił <b>$rewardName</b> za <b>$rewardCostString</b> punktów. $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> wymienił <b>$rewardName</b> za <b>$rewardCostString</b> punktów.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> cheerował <b>$bitsString</b> bitów. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonimowy';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> hostuje z grupą <b>$viewersString</b> widzów.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hypetrain na poziomie <b>$level</b> w toku! Ukończono <b>$progressPercent%</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hypetrain na poziomie <b>$levelString</b> zakończony sukcesem.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hypetrain na poziomie <b>$levelString</b> zakończony niepowodzeniem.';
  }

  @override
  String get sampleMessage => 'To jest przykładowa wiadomość tekstowa na mowę.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author powiedział: $text';
  }

  @override
  String get textToSpeechEnabled => 'Włączono funkcję zamiany tekstu na mowę';

  @override
  String get textToSpeechDisabled => 'Tekst na mowę wyłączony';

  @override
  String get alertsEnabled => 'Alerts only';
}
