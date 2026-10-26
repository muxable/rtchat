// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latvian (`lv`).
class AppLocalizationsLv extends AppLocalizations {
  AppLocalizationsLv([String locale = 'lv']) : super(locale);

  @override
  String get sendAMessage => 'Nosūtīt ziņojumu...';

  @override
  String get writeSomething => 'Uzrakstiet kaut ko...';

  @override
  String get speakToTheCrowds => 'Uzrunājiet pūli...';

  @override
  String get shareYourThoughts => 'Dalieties savās domās...';

  @override
  String get saySomethingYouLittleBitch => 'Pasaki kaut ko, sīkā kuce...';

  @override
  String get search => 'Meklēt';

  @override
  String get notSignedIn => 'Nav pierakstījies';

  @override
  String get searchChannels => 'Meklēšana';

  @override
  String get raidAChannel => 'Reids';

  @override
  String get noMessagesEmptyState => 'Šeit ir kluss.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jauni ziņojumi',
      one: '$count jauns ziņojums',
      zero: '$count jaunu ziņojumu',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Pierakstīties ar Twitch';

  @override
  String get signInError =>
      'Pierakstoties radās kļūda. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get continueAsGuest => 'Turpināt kā viesim';

  @override
  String get signInToSendMessages => 'Pierakstieties, lai sūtītu ziņojumus';

  @override
  String get currentViewers => 'Pašreizējie skatītāji';

  @override
  String get textToSpeech => 'Teksta pārvēršana runā';

  @override
  String get streamPreview => 'Straumes priekšskatījums';

  @override
  String get activityFeed => 'Aktivitāšu plūsma';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Straume tiešsaistē: $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Straume bezsaistē: $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Tērzēšana notīrīta: $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Konfigurēt ātrās saites';

  @override
  String get disableRainMode => 'Atspējot lietus režīmu';

  @override
  String get enableRainMode => 'Iespējot lietus režīmu';

  @override
  String get disableRainModeSubtitle => 'Mijiedarbība tiks iespējota';

  @override
  String get enableRainModeSubtitle => 'Mijiedarbība tiks atspējota';

  @override
  String get refreshAudioSources => 'Atsvaidzināt audio avotus';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Atsvaidzināti $count audio avoti',
      one: 'Atsvaidzināts $count audio avots',
      zero: 'Atsvaidzināti $count audio avoti',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Iestatījumi';

  @override
  String get signOut => 'Izrakstīties';

  @override
  String get cancel => 'Atcelt';

  @override
  String get signOutConfirmation => 'Vai tiešām vēlaties izrakstīties?';

  @override
  String get broadcaster => 'Straumētājs';

  @override
  String get moderators => 'Moderatori';

  @override
  String get viewers => 'Skatītāji';

  @override
  String get communityVips => 'Kopienas VIP';

  @override
  String get searchViewers => 'Meklēt skatītājus';

  @override
  String get reconnecting => 'Atkārtota savienošana...';

  @override
  String get twitchBadges => 'Twitch nozīmītes';

  @override
  String get selectAll => 'Atlasīt visu';

  @override
  String get quickLinks => 'Ātrās saites';

  @override
  String get swipeToDeleteQuickLinks =>
      'Pavelciet pa kreisi vai pa labi, lai dzēstu ātro saiti';

  @override
  String get quickLinksLabelHint => 'Etiķete';

  @override
  String get invalidUrlErrorText => 'Šis neizskatās pēc derīga URL';

  @override
  String get duplicateUrlErrorText => 'Šī saite jau pastāv';

  @override
  String get or => 'vai';

  @override
  String get clearCookies => 'Notīrīt sīkfailus';

  @override
  String get disabled => 'Atspējots';

  @override
  String get twitchActivityFeed => 'Twitch aktivitāšu plūsma';

  @override
  String get signInToEnable => 'Lai to iespējotu, jums ir jāpierakstās';

  @override
  String get customUrl => 'Pielāgots URL';

  @override
  String get preview => 'Priekšskatījums';

  @override
  String get audioSources => 'Audio avoti';

  @override
  String get enableOffStreamSwitchTitle =>
      'Iespējot ārpus straumes (patērē vairāk akumulatora)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Audio tiks atskaņots arī tad, kad esat bezsaistē';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Audio tiks atskaņots tikai tad, kad esat tiešraidē';

  @override
  String get iosOggWarningTitle => 'Hei! Klausieties!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS neatbalsta *.ogg multivides failus, kas ir noklusējuma faili pakalpojumā Streamlabs. Pārliecinieties, ka jūsu audio avoti izmanto citu formātu, citādi tie netiks atskaņoti.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Pielāgojiet savu aktivitāšu plūsmu';

  @override
  String get audioSourcesSubtitle =>
      'Pievienojiet tīmekļa avotus brīdinājuma skaņām';

  @override
  String get quickLinksSubtitle =>
      'Pievienojiet saīsnes bieži izmantotiem rīkiem';

  @override
  String get chatHistory => 'Tērzēšanas vēsture';

  @override
  String get chatHistorySubtitle => 'Mainiet tērzēšanas izskatu';

  @override
  String get textToSpeechSubtitle =>
      'Mainiet teksta pārvēršanas runā iestatījumus';

  @override
  String get events => 'Notikumi';

  @override
  String get eventsSubtitle => 'Konfigurējiet Twitch notikumus';

  @override
  String get thirdPartyServices => 'Trešo pušu pakalpojumi';

  @override
  String get thirdPartyServicesSubtitle =>
      'Savienojieties ar trešās puses pakalpojumu';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> jums seko';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> un <b>$displayNameTwo</b> jums seko';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> un vēl $numOthersString jums seko';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Noņemt apklusināšanu lietotājam $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Apklusināt lietotāju $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Uz laiku ierobežot $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Bloķēt lietotāju $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Atbloķēt lietotāju $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Skatīt lietotāja $displayName profilu';
  }

  @override
  String get copyMessage => 'Kopēt ziņojumu';

  @override
  String get deleteMessage => 'Dzēst ziņojumu';

  @override
  String get longScrollNotification => 'Jūs ritināt diezgan tālu, vai ne?';

  @override
  String get stfu => 'aizveries';

  @override
  String get globalEmotes => 'Globālās emocijzīmes';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString sekotāji',
      one: '$countString sekotājs',
      zero: '$countString sekotāju',
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
      other: '$countString skatītāji',
      one: '$countString skatītājs',
      zero: '$countString skatītāju',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Sveiki! Prieks, ka jums patīk izmantot straumes priekšskatījumu, taču ņemiet vērā, ka tas patērē daudz akumulatora enerģijas. Lasot tērzēšanu bez tā, akumulators darbosies ilgāk.';

  @override
  String get okay => 'Labi';

  @override
  String get streamPreviewLoading => 'Ielādē (vai straume ir bezsaistē)...';

  @override
  String get copiedToClipboard => 'Nokopēts starpliktuvē';

  @override
  String get audioSourcesRequirePermissions =>
      'Audio avotiem ir nepieciešamas atļaujas';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Atļaujiet RealtimeChat rādīt saturu virs citām lietotnēm, lai izmantotu audio avotus.';

  @override
  String get audioSourcesRemoveButton => 'Noņemt audio avotus';

  @override
  String get audioSourcesOpenSettingsButton => 'Atvērt iestatījumus';

  @override
  String get flashOn => 'Zibspuldze ieslēgta';

  @override
  String get flashOff => 'Zibspuldze izslēgta';

  @override
  String get durationOneSecond => '1 sekunde';

  @override
  String get durationOneMinute => '1 minūte';

  @override
  String get durationTenMinutes => '10 minūtes';

  @override
  String get durationOneHour => '1 stunda';

  @override
  String get durationSixHours => '6 stundas';

  @override
  String get durationOneDay => '1 diena';

  @override
  String get durationTwoDays => '2 dienas';

  @override
  String get durationOneWeek => '1 nedēļa';

  @override
  String get durationTwoWeeks => '2 nedēļas';

  @override
  String get durationOneSecondTimeoutPrompt => 'Ierobežot uz 1 sekundi';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Ierobežot uz 1 minūti';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Ierobežot uz 10 minūtēm';

  @override
  String get durationOneHourTimeoutPrompt => 'Ierobežot uz 1 stundu';

  @override
  String get durationSixHoursTimeoutPrompt => 'Ierobežot uz 6 stundām';

  @override
  String get durationOneDayTimeoutPrompt => 'Ierobežot uz 1 dienu';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Ierobežot uz 2 dienām';

  @override
  String get durationOneWeekTimeoutPrompt => 'Ierobežot uz 1 nedēļu';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Ierobežot uz 2 nedēļām';

  @override
  String get errorFetchingViewerList =>
      'Neizdevās iegūt šī kanāla skatītāju sarakstu';

  @override
  String get eventsTitle => 'Notikumi';

  @override
  String get followEventConfigTitle => 'Sekošanas notikums';

  @override
  String get customizeYourFollowEvent => 'Pielāgojiet savu sekošanas notikumu';

  @override
  String get subscribeEventConfigTitle => 'Abonēšanas notikums';

  @override
  String get customizeYourSubscriptionEvent =>
      'Pielāgojiet savu abonēšanas notikumu';

  @override
  String get cheerEventConfigTitle => 'Cheer notikums';

  @override
  String get customizeYourCheerEvent => 'Pielāgojiet savu Cheer notikumu';

  @override
  String get raidEventConfigTitle => 'Reida notikums';

  @override
  String get customizeYourRaidEvent => 'Pielāgojiet savu reida notikumu';

  @override
  String get hostEventConfigTitle => 'Viesošanas (Host) notikums';

  @override
  String get customizeYourHostEvent =>
      'Pielāgojiet savu viesošanas (Host) notikumu';

  @override
  String get hypetrainEventConfigTitle => 'Hype Train notikums';

  @override
  String get customizeYourHypetrainEvent =>
      'Pielāgojiet savu Hype Train notikumu';

  @override
  String get pollEventConfigTitle => 'Aptaujas notikums';

  @override
  String get customizeYourPollEvent => 'Pielāgojiet savu aptaujas notikumu';

  @override
  String get predictionEventConfigTitle => 'Prognožu notikums';

  @override
  String get customizeYourPredictionEvent =>
      'Pielāgojiet savu prognožu notikumu';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Kanāla punktu izmantošanas notikums';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Pielāgojiet savu kanāla punktu izmantošanas notikumu';

  @override
  String get outgoingRaidEventConfigTitle => 'Izejošā reida notikums';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Pielāgojiet savu izejošā reida notikumu';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> veic reidu ar <b>$viewerCountString</b> skatītājiem!';
  }

  @override
  String get shoutout => 'Izcelšana';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Notiek reids uz <b>$displayName</b>...';
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
    return '<b>$displayName</b> veica reidu!';
  }

  @override
  String get raidingEventJoin => 'Pievienoties';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> reids tika atcelts.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> abonēja $tier. līmenī!';
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

    return '<b>$gifterUserName</b> uzdāvināja $totalString $tier. līmeņa abonementus, kopā $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> abonē $tier. līmenī jau $cumulativeMonthsString mēnešus!';
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

    return '<b>$subscriberUserName</b> abonēja $tier. līmenī uz $durationMonthsString mēnešiem iepriekš, kopā $cumulativeMonthsString mēnešus!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> atstāja dzeramnaudu <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Anonīms lietotājs atstāja dzeramnaudu <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> atstāja dzeramnaudu <b>$formattedAmount</b> pakalpojumā StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> atstāja dzeramnaudu <b>$formattedAmount</b> pakalpojumā Streamlabs.';
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

    return '<b>$redeemerUsername</b> izmantoja atlīdzību <b>$rewardName</b> par <b>$rewardCostString</b> punktiem. $userInput';
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

    return '<b>$redeemerUsername</b> izmantoja atlīdzību <b>$rewardName</b> par <b>$rewardCostString</b> punktiem.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> atbalstīja ar <b>$bitsString</b> bitiem. $cheerMessage';
  }

  @override
  String get anonymous => 'Anonīms';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> rāda kanālu ar <b>$viewersString</b> skatītāju grupu.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Notiek Hype Train <b>$level</b>. līmenis! Pabeigts par <b>$progressPercent%</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train <b>$levelString</b>. līmenis bija veiksmīgs.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train <b>$levelString</b>. līmenis neizdevās.';
  }

  @override
  String get sampleMessage =>
      'Šis ir teksta pārvēršanas runā parauga ziņojums.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author teica: $text';
  }

  @override
  String get textToSpeechEnabled => 'Teksta pārvēršana runā iespējota';

  @override
  String get textToSpeechDisabled => 'Teksta pārvēršana runā atspējota';

  @override
  String get alertsEnabled => 'Tikai brīdinājumi';

  @override
  String get pinDuration => 'Piespraušanas ilgums';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekundes',
      one: '$seconds sekunde',
      zero: '$seconds sekunžu',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minūtes',
      one: '$minutes minūte',
      zero: '$minutes minūšu',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Iespējot notikumu';

  @override
  String get showEventInChatHistory => 'Rādīt notikumu tērzēšanas vēsturē';

  @override
  String get enableShoutouts => 'Iespējot izcelšanas';

  @override
  String get enableShoutoutsSubtitle =>
      'Nosūtīt saiti uz reidojošo kanālu tērzēšanā';

  @override
  String get raidConfigurationTitle => 'Reida konfigurācija';

  @override
  String get cheerConfigurationTitle => 'Cheer konfigurācija';

  @override
  String get followConfigurationTitle => 'Sekošanas konfigurācija';

  @override
  String get outgoingRaidConfigurationTitle => 'Izejošā reida konfigurācija';

  @override
  String get hostConfigurationTitle => 'Viesošanas (Host) konfigurācija';

  @override
  String get channelPointConfigurationTitle => 'Kanāla punktu konfigurācija';

  @override
  String get pollConfigurationTitle => 'Aptaujas konfigurācija';

  @override
  String get hypetrainConfigurationTitle => 'Hype Train konfigurācija';

  @override
  String get subscriptionConfigurationTitle => 'Abonēšanas konfigurācija';

  @override
  String get predictionConfigurationTitle => 'Prognožu konfigurācija';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Papildu piespraušanas ilgums neizpildītajām atlīdzībām';

  @override
  String get pollPinDuration =>
      'Piespraušanas ilgums pēc rezultāta apstiprināšanas';

  @override
  String get hypetrainPinDuration =>
      'Piespraušanas ilgums pēc Hype Train beigām';

  @override
  String get enableGiftedSubscriptions =>
      'Iespējot atsevišķus dāvinātos abonementus';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Rādīt katru uzdāvināto abonementu';

  @override
  String get settingsBackupTitle => 'Iestatījumu dublēšana un atjaunošana';

  @override
  String get cloudBackup => 'Mākoņa dublējums';

  @override
  String get lastBackupNever => 'Pēdējais dublējums: nekad';

  @override
  String get backUp => 'Dublēt';

  @override
  String get restore => 'Atjaunot';

  @override
  String get localBackup => 'Vietējais dublējums';

  @override
  String get exportSettings => 'Eksportēt';

  @override
  String get importSettings => 'Importēt';

  @override
  String get showViewerAndFollowerCount => 'Rādīt skatītāju un sekotāju skaitu';

  @override
  String get screenOrientation => 'Ekrāna orientācija';

  @override
  String get appTheme => 'Lietotnes motīvs';

  @override
  String get systemDefault => 'Sistēmas';

  @override
  String get portrait => 'Portreta';

  @override
  String get landscape => 'Ainavas';

  @override
  String get lightTheme => 'Gaišs';

  @override
  String get darkTheme => 'Tumšs';

  @override
  String get openSourceTitle => 'RealtimeChat ir atvērtā pirmkoda';

  @override
  String get openSourceSubtitle => 'Atrodiet mūs GitHub!';

  @override
  String get discordSubtitle => 'Pievienojieties Muxable Discord!';

  @override
  String get earlyTestersThanks =>
      'Paldies visiem agrīnajiem testētājiem, kuri iesūtīja kļūdu ziņojumus!';

  @override
  String get discoModeEnabled => '🕺 Disko režīms iespējots! :D';

  @override
  String get discoModeDisabled => '🕺 Disko režīms atspējots D:';

  @override
  String get playSampleMessage => 'Atskaņot parauga ziņojumu';

  @override
  String get textToSpeechRate => 'Teksta pārvēršanas runā ātrums';

  @override
  String get textToSpeechPitch => 'Teksta pārvēršanas runā augstums';

  @override
  String get muteBots => 'Apklusināt teksta pārvēršanu runā robotiem';

  @override
  String get muteEmotes =>
      'Apklusināt visas emocijzīmes teksta pārvēršanā runā';

  @override
  String get muteViewerNames =>
      'Apklusināt skatītāju vārdus teksta pārvēršanā runā';

  @override
  String get subscribersOnly => 'Tikai abonentiem';

  @override
  String get fontSize => 'Fonta lielums';

  @override
  String get usernameContrastBoost => 'Lietotājvārda kontrasta pastiprināšana';

  @override
  String get twitchBadgeSettings => 'Twitch nozīmīšu iestatījumi';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Kontrolējiet, kuras nozīmītes ir redzamas';

  @override
  String get showDeletedMessages => 'Rādīt dzēstos ziņojumus';

  @override
  String get deletedMessagesGreyedOut =>
      'Dzēstie ziņojumi tiks rādīti pelēkā krāsā';

  @override
  String get deletedMessagesRemoved => 'Dzēstie ziņojumi tiks noņemti';

  @override
  String get showLoginNames => 'Rādīt pieteikšanās vārdus';

  @override
  String get loginNamesShown =>
      'Pieteikšanās vārdi tiks rādīti, ja tie atšķiras no redzamā vārda';

  @override
  String get loginNamesHidden => 'Pieteikšanās vārdi tiks paslēpti';

  @override
  String get compactMessages => 'Kompaktie ziņojumi';

  @override
  String get dontCompactMessages => 'Nesaspiest ziņojumus';

  @override
  String get dontCompactMessagesSubtitle => 'Ziņojumi tiek rādīti nemainīti';

  @override
  String get compactIndividualMessages => 'Saspiest atsevišķus ziņojumus';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Atkārtots teksts ziņojumos tiek saīsināts';

  @override
  String get announcementPinDuration => 'Paziņojuma piespraušanas ilgums';

  @override
  String get idleMessageAlertDuration =>
      'Dīkstāves ziņojuma brīdinājuma ilgums';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Ja šajā laika posmā nav neviena ziņojuma un pienāk jauns, tiks atskaņota brīdinājuma skaņa.';

  @override
  String get realtimeCashSubtitle => 'Pievienojiet ETH vai MATIC maku';

  @override
  String get walletAddress => 'Maka adrese';

  @override
  String get streamlabsSubtitle => 'Skatiet savus Streamlabs ziedojumus';

  @override
  String get streamElementsSubtitle =>
      'Skatiet savus StreamElements ziedojumus';

  @override
  String get thirdPartyAuthError =>
      'Hmm, tas neizdevās. Mēģiniet vēlreiz vai pajautājiet Discord?';

  @override
  String get companionAuthBrowserTooOld =>
      'Jūsu pārlūkprogramma ir pārāk veca, lai atbalstītu tiešu pierakstīšanos. Skenējiet šo QR kodu ar tālruni, lai pierakstītos citā ierīcē.';

  @override
  String get companionAuthScanQrCode =>
      'Skenējiet šo QR kodu ar tālruni, lai pierakstītos citā ierīcē.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> abonēja!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> atkārtoti abonēja uz $monthsString mēnešiem!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> uzdāvināja $countString abonementus!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> nosūtīja $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Pierakstīties ar Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Ir pārāk daudz ziņojumu. Teksta pārvēršana runā atspējota';

  @override
  String get turnOffTextToSpeech => 'Izslēgt';

  @override
  String get addToChat => 'Pievienot tērzēšanai';

  @override
  String get inChat => 'Tērzēšanā';

  @override
  String get removeFromChat => 'Noņemt no tērzēšanas';

  @override
  String cantChatWithAccount(String provider) {
    return 'Jūsu $provider konts šeit nevar tērzēt';
  }

  @override
  String get cantChatWithAccounts => 'Jūsu konti šeit nevar tērzēt';

  @override
  String sendAMessageTo(String channel) {
    return 'Nosūtīt ziņojumu kanālam $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Aizstāt $channel';
  }

  @override
  String get voicePacks => 'Balss pakotnes';

  @override
  String get voicePacksDescription =>
      'Balss pakotnes lasa tērzēšanu ar dabiski skanošām balsīm, kas darbojas jūsu ierīcē un pēc lejupielādes ir pieejamas bezsaistē. Balsis ir mākslīgā intelekta ģenerētas, nevis cilvēka ierakstītas.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices balsis',
      one: '$voices balss',
      zero: '$voices balsu',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count valodas',
      one: '$count valoda',
      zero: '$count valodu',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Šī modeļa licence (OpenRAIL-M) aizliedz kaitīgu izmantošanu, piemēram, uzdošanos par citiem cilvēkiem vai dezinformācijas izplatīšanu, un šie ierobežojumi attiecas arī uz jums.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Dzēst $pack? Tas atbrīvos $size.';
  }

  @override
  String get voicePackDownload => 'Lejupielādēt';

  @override
  String get voicePackUpdate => 'Atjaunināt';

  @override
  String get voicePackWaitingForWifi => 'Gaida Wi-Fi savienojumu';

  @override
  String get voicePackUseMobileData => 'Izmantot mobilos datus';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Lejupielādē: $downloaded no $total';
  }

  @override
  String get voicePackInstalling => 'Instalē';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Neizdevās instalēt $pack. Pārbaudiet savienojumu un mēģiniet vēlreiz.';
  }

  @override
  String get voices => 'Balsis';

  @override
  String get perViewerVoice => 'Atsevišķa balss katram skatītājam';

  @override
  String get perViewerVoiceSubtitle =>
      'Katrs skatītājs saņem savu balsi. Jūsu izvēlētā balss lasa brīdinājumus vai visu, kad šī opcija ir izslēgta.';

  @override
  String get streamLanguage => 'Straumes valoda';

  @override
  String get ttsEngineNeural => 'Neironu balss (ierīcē)';

  @override
  String get ttsEngineSystem => 'Sistēmas balss';

  @override
  String languageUnsupported(String language) {
    return 'Jūsu balss pakotnes neatbalsta šo valodu ($language); tiks izmantota sistēmas balss';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Šai ierīcei nav pietiekami daudz atmiņas neironu balsīm, tāpēc tērzēšana tiek lasīta ar sistēmas balsi.';

  @override
  String get neuralFallbackLoadFailed =>
      'Neironu balsi neizdevās ielādēt, tāpēc tērzēšana tiek lasīta ar sistēmas balsi.';

  @override
  String get accounts => 'Konti';

  @override
  String get accountsSubtitle =>
      'Pierakstieties katrā platformā, kurā straumējat';

  @override
  String addProviderAccount(String provider) {
    return 'Pievienot $provider kontu';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Pierakstīties ar $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Izrakstīties no $channel platformā $provider?';
  }

  @override
  String get signOutOfAll => 'Izrakstīties no visiem kontiem';
}
