// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get sendAMessage => 'Trimite un mesaj...';

  @override
  String get writeSomething => 'Scrie ceva...';

  @override
  String get speakToTheCrowds => 'Vorbește mulțimii...';

  @override
  String get shareYourThoughts => 'Împărtășește-ți gândurile...';

  @override
  String get saySomethingYouLittleBitch => 'Zi ceva, fricosule...';

  @override
  String get search => 'Caută';

  @override
  String get notSignedIn => 'Neconectat';

  @override
  String get searchChannels => 'Caută';

  @override
  String get raidAChannel => 'Fă un raid';

  @override
  String get noMessagesEmptyState => 'E liniște pe aici.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de mesaje noi',
      few: '$count mesaje noi',
      one: '1 mesaj nou',
      zero: 'Niciun mesaj nou',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Conectează-te cu Twitch';

  @override
  String get signInError =>
      'A apărut o eroare la conectare. Te rugăm să încerci din nou.';

  @override
  String get continueAsGuest => 'Continuă ca oaspete';

  @override
  String get signInToSendMessages => 'Conectează-te pentru a trimite mesaje';

  @override
  String get currentViewers => 'Spectatori actuali';

  @override
  String get textToSpeech => 'Text în vorbire';

  @override
  String get streamPreview => 'Previzualizare stream';

  @override
  String get activityFeed => 'Flux de activitate';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream online pe $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Stream offline pe $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Chat șters pe $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Configurează linkurile rapide';

  @override
  String get disableRainMode => 'Dezactivează modul ploaie';

  @override
  String get enableRainMode => 'Activează modul ploaie';

  @override
  String get disableRainModeSubtitle => 'Interacțiunea va fi activată';

  @override
  String get enableRainModeSubtitle => 'Interacțiunea va fi dezactivată';

  @override
  String get refreshAudioSources => 'Reîmprospătează sursele audio';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de surse audio reîmprospătate',
      few: '$count surse audio reîmprospătate',
      one: '1 sursă audio reîmprospătată',
      zero: 'Nicio sursă audio reîmprospătată',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Setări';

  @override
  String get signOut => 'Deconectează-te';

  @override
  String get cancel => 'Anulează';

  @override
  String get signOutConfirmation => 'Sigur dorești să te deconectezi?';

  @override
  String get broadcaster => 'Streamer';

  @override
  String get moderators => 'Moderatori';

  @override
  String get viewers => 'Spectatori';

  @override
  String get communityVips => 'VIP-uri ale comunității';

  @override
  String get searchViewers => 'Caută spectatori';

  @override
  String get reconnecting => 'Se reconectează...';

  @override
  String get twitchBadges => 'Insigne Twitch';

  @override
  String get selectAll => 'Selectează tot';

  @override
  String get quickLinks => 'Linkuri rapide';

  @override
  String get swipeToDeleteQuickLinks =>
      'Glisează la stânga sau la dreapta pentru a șterge linkul rapid';

  @override
  String get quickLinksLabelHint => 'Etichetă';

  @override
  String get invalidUrlErrorText => 'Acesta nu pare a fi un URL valid';

  @override
  String get duplicateUrlErrorText => 'Acest link există deja';

  @override
  String get or => 'sau';

  @override
  String get clearCookies => 'Șterge modulele cookie';

  @override
  String get disabled => 'Dezactivat';

  @override
  String get twitchActivityFeed => 'Flux de activitate Twitch';

  @override
  String get signInToEnable =>
      'Trebuie să fii conectat pentru a activa această opțiune';

  @override
  String get customUrl => 'URL personalizat';

  @override
  String get preview => 'Previzualizare';

  @override
  String get audioSources => 'Surse audio';

  @override
  String get enableOffStreamSwitchTitle =>
      'Activează în afara streamului (consumă mai multă baterie)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Sunetul va fi redat și când ești offline';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Sunetul va fi redat doar când ești în direct';

  @override
  String get iosOggWarningTitle => 'Hei! Ascultă!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS nu acceptă fișiere media *.ogg, care sunt fișierele implicite pe Streamlabs. Asigură-te că sursele tale audio folosesc alt format, altfel nu vor fi redate.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Personalizează-ți fluxul de activitate';

  @override
  String get audioSourcesSubtitle =>
      'Adaugă surse web pentru sunetele de alertă';

  @override
  String get quickLinksSubtitle =>
      'Adaugă scurtături către instrumentele folosite frecvent';

  @override
  String get chatHistory => 'Istoric chat';

  @override
  String get chatHistorySubtitle => 'Schimbă aspectul chatului';

  @override
  String get textToSpeechSubtitle =>
      'Schimbă setările pentru conversia textului în vorbire';

  @override
  String get events => 'Evenimente';

  @override
  String get eventsSubtitle => 'Configurează evenimentele Twitch';

  @override
  String get thirdPartyServices => 'Servicii terțe';

  @override
  String get thirdPartyServicesSubtitle => 'Conectează-te la un serviciu terț';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> te urmărește';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> și <b>$displayNameTwo</b> te urmăresc';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> și alți $numOthersString te urmăresc';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Reactivează sunetul pentru $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Dezactivează sunetul pentru $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Suspendă temporar pe $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Blochează pe $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Deblochează pe $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Vezi profilul lui $displayName';
  }

  @override
  String get copyMessage => 'Copiază mesajul';

  @override
  String get deleteMessage => 'Șterge mesajul';

  @override
  String get longScrollNotification => 'Derulezi cam departe, nu crezi?';

  @override
  String get stfu => 'taci';

  @override
  String get globalEmotes => 'Emoticoane globale';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString de urmăritori',
      few: '$countString urmăritori',
      one: '1 urmăritor',
      zero: '0 urmăritori',
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
      other: '$countString de spectatori',
      few: '$countString spectatori',
      one: '1 spectator',
      zero: '0 spectatori',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Salut! Ne bucurăm că îți place previzualizarea streamului, dar ține cont că folosește multă baterie. Citirea chatului fără ea îți va prelungi autonomia bateriei.';

  @override
  String get okay => 'În regulă';

  @override
  String get streamPreviewLoading =>
      'Se încarcă (sau streamul este offline)...';

  @override
  String get copiedToClipboard => 'Copiat în clipboard';

  @override
  String get audioSourcesRequirePermissions =>
      'Sursele audio necesită permisiuni';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Aprobă ca RealtimeChat să se afișeze peste alte aplicații pentru a folosi sursele audio.';

  @override
  String get audioSourcesRemoveButton => 'Elimină sursele audio';

  @override
  String get audioSourcesOpenSettingsButton => 'Deschide setările';

  @override
  String get flashOn => 'Bliț activat';

  @override
  String get flashOff => 'Bliț dezactivat';

  @override
  String get durationOneSecond => '1 secundă';

  @override
  String get durationOneMinute => '1 minut';

  @override
  String get durationTenMinutes => '10 minute';

  @override
  String get durationOneHour => '1 oră';

  @override
  String get durationSixHours => '6 ore';

  @override
  String get durationOneDay => '1 zi';

  @override
  String get durationTwoDays => '2 zile';

  @override
  String get durationOneWeek => '1 săptămână';

  @override
  String get durationTwoWeeks => '2 săptămâni';

  @override
  String get durationOneSecondTimeoutPrompt =>
      'Suspendă temporar timp de 1 secundă';

  @override
  String get durationOneMinuteTimeoutPrompt =>
      'Suspendă temporar timp de 1 minut';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      'Suspendă temporar timp de 10 minute';

  @override
  String get durationOneHourTimeoutPrompt => 'Suspendă temporar timp de 1 oră';

  @override
  String get durationSixHoursTimeoutPrompt => 'Suspendă temporar timp de 6 ore';

  @override
  String get durationOneDayTimeoutPrompt => 'Suspendă temporar timp de 1 zi';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Suspendă temporar timp de 2 zile';

  @override
  String get durationOneWeekTimeoutPrompt =>
      'Suspendă temporar timp de 1 săptămână';

  @override
  String get durationTwoWeeksTimeoutPrompt =>
      'Suspendă temporar timp de 2 săptămâni';

  @override
  String get errorFetchingViewerList =>
      'Nu am putut prelua lista de spectatori pentru acest canal';

  @override
  String get eventsTitle => 'Evenimente';

  @override
  String get followEventConfigTitle => 'Eveniment de urmărire';

  @override
  String get customizeYourFollowEvent =>
      'Personalizează evenimentul de urmărire';

  @override
  String get subscribeEventConfigTitle => 'Eveniment de abonare';

  @override
  String get customizeYourSubscriptionEvent =>
      'Personalizează evenimentul de abonare';

  @override
  String get cheerEventConfigTitle => 'Eveniment de Cheer';

  @override
  String get customizeYourCheerEvent => 'Personalizează evenimentul de Cheer';

  @override
  String get raidEventConfigTitle => 'Eveniment de raid';

  @override
  String get customizeYourRaidEvent => 'Personalizează evenimentul de raid';

  @override
  String get hostEventConfigTitle => 'Eveniment de găzduire';

  @override
  String get customizeYourHostEvent => 'Personalizează evenimentul de găzduire';

  @override
  String get hypetrainEventConfigTitle => 'Eveniment Trenul Hype';

  @override
  String get customizeYourHypetrainEvent =>
      'Personalizează evenimentul Trenul Hype';

  @override
  String get pollEventConfigTitle => 'Eveniment de sondaj';

  @override
  String get customizeYourPollEvent => 'Personalizează evenimentul de sondaj';

  @override
  String get predictionEventConfigTitle => 'Eveniment de predicție';

  @override
  String get customizeYourPredictionEvent =>
      'Personalizează evenimentul de predicție';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Eveniment de revendicare a punctelor de canal';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Personalizează evenimentul de revendicare a punctelor de canal';

  @override
  String get outgoingRaidEventConfigTitle => 'Eveniment de raid inițiat';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Personalizează evenimentul de raid inițiat';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> face un raid cu <b>$viewerCountString</b> spectatori!';
  }

  @override
  String get shoutout => 'Mențiune';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Se face raid către <b>$displayName</b>...';
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
    return '<b>$displayName</b> a făcut raid!';
  }

  @override
  String get raidingEventJoin => 'Alătură-te';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Raidul lui <b>$displayName</b> a fost anulat.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> s-a abonat la nivelul $tier!';
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

    return '<b>$gifterUserName</b> a oferit cadou $totalString abonamente de nivelul $tier, în total $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> s-a abonat timp de $cumulativeMonthsString luni la nivelul $tier!';
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

    return '<b>$subscriberUserName</b> s-a abonat la nivelul $tier pentru $durationMonthsString luni în avans, $cumulativeMonthsString luni în total!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> a oferit un bacșiș de <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonim a oferit un bacșiș de <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> a oferit un bacșiș de <b>$formattedAmount</b> pe StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> a oferit un bacșiș de <b>$formattedAmount</b> pe Streamlabs.';
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

    return '<b>$redeemerUsername</b> a revendicat <b>$rewardName</b> pentru <b>$rewardCostString</b> puncte. $userInput';
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

    return '<b>$redeemerUsername</b> a revendicat <b>$rewardName</b> pentru <b>$rewardCostString</b> puncte.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> a trimis <b>$bitsString</b> bits. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonim';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> găzduiește canalul cu un grup de <b>$viewersString</b>.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Trenul Hype de nivelul <b>$level</b> este în desfășurare! Finalizat în proporție de <b>$progressPercent%</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Trenul Hype de nivelul <b>$levelString</b> s-a încheiat cu succes.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Trenul Hype de nivelul <b>$levelString</b> a eșuat.';
  }

  @override
  String get sampleMessage =>
      'Acesta este un mesaj de probă pentru conversia textului în vorbire.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author a spus: $text';
  }

  @override
  String get textToSpeechEnabled =>
      'Conversia textului în vorbire a fost activată';

  @override
  String get textToSpeechDisabled =>
      'Conversia textului în vorbire a fost dezactivată';

  @override
  String get alertsEnabled => 'Doar alerte';

  @override
  String get pinDuration => 'Durata fixării';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds de secunde',
      few: '$seconds secunde',
      one: '1 secundă',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes de minute',
      few: '$minutes minute',
      one: '1 minut',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Activează evenimentul';

  @override
  String get showEventInChatHistory =>
      'Afișează evenimentul în istoricul chatului';

  @override
  String get enableShoutouts => 'Activează mențiunile';

  @override
  String get enableShoutoutsSubtitle =>
      'Trimite în chat un link către canalul care face raid';

  @override
  String get raidConfigurationTitle => 'Configurare raid';

  @override
  String get cheerConfigurationTitle => 'Configurare Cheer';

  @override
  String get followConfigurationTitle => 'Configurare urmărire';

  @override
  String get outgoingRaidConfigurationTitle => 'Configurare raid inițiat';

  @override
  String get hostConfigurationTitle => 'Configurare găzduire';

  @override
  String get channelPointConfigurationTitle => 'Configurare puncte de canal';

  @override
  String get pollConfigurationTitle => 'Configurare sondaj';

  @override
  String get hypetrainConfigurationTitle => 'Configurare Trenul Hype';

  @override
  String get subscriptionConfigurationTitle => 'Configurare abonamente';

  @override
  String get predictionConfigurationTitle => 'Configurare predicții';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Durată suplimentară de fixare pentru recompensele neonorate';

  @override
  String get pollPinDuration => 'Durata fixării după finalizarea rezultatului';

  @override
  String get hypetrainPinDuration =>
      'Durata fixării după încheierea Trenului Hype';

  @override
  String get enableGiftedSubscriptions =>
      'Activează abonamentele cadou individuale';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Afișează fiecare abonament oferit cadou';

  @override
  String get settingsBackupTitle =>
      'Copie de rezervă și restaurare a setărilor';

  @override
  String get cloudBackup => 'Copie de rezervă în cloud';

  @override
  String get lastBackupNever => 'Ultima copie de rezervă: niciodată';

  @override
  String get backUp => 'Creează copie de rezervă';

  @override
  String get restore => 'Restaurează';

  @override
  String get localBackup => 'Copie de rezervă locală';

  @override
  String get exportSettings => 'Exportă';

  @override
  String get importSettings => 'Importă';

  @override
  String get showViewerAndFollowerCount =>
      'Afișează numărul de spectatori și de urmăritori';

  @override
  String get screenOrientation => 'Orientarea ecranului';

  @override
  String get appTheme => 'Tema aplicației';

  @override
  String get systemDefault => 'Sistem';

  @override
  String get portrait => 'Portret';

  @override
  String get landscape => 'Peisaj';

  @override
  String get lightTheme => 'Luminos';

  @override
  String get darkTheme => 'Întunecat';

  @override
  String get openSourceTitle => 'RealtimeChat este open source';

  @override
  String get openSourceSubtitle => 'Găsește-ne pe GitHub!';

  @override
  String get discordSubtitle => 'Alătură-te serverului Discord Muxable!';

  @override
  String get earlyTestersThanks =>
      'Mulțumim tuturor primilor testeri care au trimis rapoarte de erori!';

  @override
  String get discoModeEnabled => '🕺 Modul disco a fost activat! :D';

  @override
  String get discoModeDisabled => '🕺 Modul disco a fost dezactivat D:';

  @override
  String get playSampleMessage => 'Redă mesajul de probă';

  @override
  String get textToSpeechRate => 'Viteză text în vorbire';

  @override
  String get textToSpeechPitch => 'Tonalitate text în vorbire';

  @override
  String get muteBots => 'Dezactivează citirea vocală pentru boți';

  @override
  String get muteEmotes => 'Dezactivează citirea vocală a emoticoanelor';

  @override
  String get muteViewerNames =>
      'Dezactivează citirea vocală a numelor spectatorilor';

  @override
  String get subscribersOnly => 'Doar abonați';

  @override
  String get fontSize => 'Dimensiunea fontului';

  @override
  String get usernameContrastBoost =>
      'Amplificarea contrastului pentru numele de utilizator';

  @override
  String get twitchBadgeSettings => 'Setări insigne Twitch';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Controlează care insigne sunt vizibile';

  @override
  String get showDeletedMessages => 'Afișează mesajele șterse';

  @override
  String get deletedMessagesGreyedOut =>
      'Mesajele șterse vor fi afișate cu gri';

  @override
  String get deletedMessagesRemoved => 'Mesajele șterse vor fi eliminate';

  @override
  String get showLoginNames => 'Afișează numele de conectare';

  @override
  String get loginNamesShown =>
      'Numele de conectare vor fi afișate dacă diferă de numele afișat';

  @override
  String get loginNamesHidden => 'Numele de conectare vor fi ascunse';

  @override
  String get compactMessages => 'Compactează mesajele';

  @override
  String get dontCompactMessages => 'Nu compacta mesajele';

  @override
  String get dontCompactMessagesSubtitle => 'Mesajele sunt afișate neschimbate';

  @override
  String get compactIndividualMessages => 'Compactează mesajele individuale';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Textul repetitiv din mesaje este scurtat';

  @override
  String get announcementPinDuration => 'Durata fixării anunțurilor';

  @override
  String get idleMessageAlertDuration =>
      'Durata alertei de inactivitate pentru mesaje';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Dacă nu există mesaje pentru această perioadă de timp și sosește unul nou, va fi redat un sunet de alertă.';

  @override
  String get realtimeCashSubtitle => 'Conectează un portofel ETH sau MATIC';

  @override
  String get walletAddress => 'Adresa portofelului';

  @override
  String get streamlabsSubtitle => 'Vezi donațiile tale de pe Streamlabs';

  @override
  String get streamElementsSubtitle =>
      'Vezi donațiile tale de pe StreamElements';

  @override
  String get thirdPartyAuthError =>
      'Hmm, nu a funcționat. Încearcă din nou sau întreabă pe Discord?';

  @override
  String get companionAuthBrowserTooOld =>
      'Browserul tău este prea vechi pentru a permite conectarea directă. Scanează acest cod QR cu telefonul pentru a te conecta pe alt dispozitiv.';

  @override
  String get companionAuthScanQrCode =>
      'Scanează acest cod QR cu telefonul pentru a te conecta pe alt dispozitiv.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> s-a abonat!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> s-a reabonat pentru $monthsString luni!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> a oferit cadou $countString abonamente!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> a trimis $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Conectează-te cu Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Sunt prea multe mesaje. Conversia textului în vorbire a fost dezactivată';

  @override
  String get turnOffTextToSpeech => 'Dezactivează';

  @override
  String get addToChat => 'Adaugă în chat';

  @override
  String get inChat => 'În chat';

  @override
  String get removeFromChat => 'Elimină din chat';

  @override
  String cantChatWithAccount(String provider) {
    return 'Contul tău $provider nu poate scrie în chat aici';
  }

  @override
  String get cantChatWithAccounts => 'Conturile tale nu pot scrie în chat aici';

  @override
  String sendAMessageTo(String channel) {
    return 'Trimite un mesaj către $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Înlocuiește $channel';
  }

  @override
  String get voicePacks => 'Pachete de voci';

  @override
  String get voicePacksDescription =>
      'Pachetele de voci citesc chatul cu voci naturale care rulează pe dispozitivul tău, offline după descărcare. Vocile sunt generate automat de IA, nu înregistrate de o persoană.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices de voci',
      few: '$voices voci',
      one: '1 voce',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de limbi',
      few: '$count limbi',
      one: '1 limbă',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Licența acestui model (OpenRAIL-M) interzice utilizările dăunătoare, cum ar fi uzurparea identității unor persoane sau răspândirea dezinformării, iar aceste restricții ți se aplică și ție.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Ștergi $pack? Aceasta eliberează $size.';
  }

  @override
  String get voicePackDownload => 'Descarcă';

  @override
  String get voicePackUpdate => 'Actualizează';

  @override
  String get voicePackWaitingForWifi => 'Se așteaptă conexiunea Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Folosește datele mobile';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Se descarcă: $downloaded din $total';
  }

  @override
  String get voicePackInstalling => 'Se instalează';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Nu s-a putut instala $pack. Verifică conexiunea și încearcă din nou.';
  }

  @override
  String get voices => 'Voci';

  @override
  String get perViewerVoice => 'Voce per spectator';

  @override
  String get perViewerVoiceSubtitle =>
      'Fiecare spectator primește propria voce. Vocea pe care o alegi citește alertele sau totul atunci când această opțiune este dezactivată.';

  @override
  String get streamLanguage => 'Limba streamului';

  @override
  String get ttsEngineNeural => 'Voce neurală (pe dispozitiv)';

  @override
  String get ttsEngineSystem => 'Vocea sistemului';

  @override
  String languageUnsupported(String language) {
    return 'Limba $language nu este acceptată de pachetele tale de voci; va fi folosită vocea sistemului';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Acest dispozitiv nu are suficientă memorie pentru vocile neurale, astfel încât chatul este citit cu vocea sistemului.';

  @override
  String get neuralFallbackLoadFailed =>
      'Vocea neurală nu a putut fi încărcată, astfel încât chatul este citit cu vocea sistemului.';

  @override
  String get accounts => 'Conturi';

  @override
  String get accountsSubtitle =>
      'Conectează-te pe fiecare platformă pe care faci stream';

  @override
  String addProviderAccount(String provider) {
    return 'Adaugă cont $provider';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Conectează-te cu $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Te deconectezi de la $channel pe $provider?';
  }

  @override
  String get signOutOfAll => 'Deconectează-te de la toate conturile';
}
