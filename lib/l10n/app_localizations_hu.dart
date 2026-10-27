// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get sendAMessage => 'Üzenet küldése...';

  @override
  String get writeSomething => 'Írj valamit...';

  @override
  String get speakToTheCrowds => 'Szólj a tömeghez...';

  @override
  String get shareYourThoughts => 'Oszd meg a gondolataidat...';

  @override
  String get saySomethingYouLittleBitch => 'Mondj valamit, te kis ribanc...';

  @override
  String get search => 'Keresés';

  @override
  String get notSignedIn => 'Nincs bejelentkezve';

  @override
  String get searchChannels => 'Keresés';

  @override
  String get raidAChannel => 'Raid indítása';

  @override
  String get noMessagesEmptyState => 'Nagy itt a csend.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count új üzenet',
      one: '1 új üzenet',
      zero: 'Nincs új üzenet',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Bejelentkezés Twitch-fiókkal';

  @override
  String get signInError =>
      'Hiba történt a bejelentkezés során. Kérjük, próbáld újra.';

  @override
  String get continueAsGuest => 'Folytatás vendégként';

  @override
  String get signInToSendMessages => 'Jelentkezz be az üzenetküldéshez';

  @override
  String get currentViewers => 'Jelenlegi nézők';

  @override
  String get textToSpeech => 'Szövegfelolvasás';

  @override
  String get streamPreview => 'Közvetítés előnézete';

  @override
  String get activityFeed => 'Tevékenységfolyam';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Közvetítés élőben: $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Közvetítés offline: $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Csevegés törölve: $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Gyorshivatkozások beállítása';

  @override
  String get disableRainMode => 'Eső mód kikapcsolása';

  @override
  String get enableRainMode => 'Eső mód bekapcsolása';

  @override
  String get disableRainModeSubtitle => 'Az interakció engedélyezve lesz';

  @override
  String get enableRainModeSubtitle => 'Az interakció le lesz tiltva';

  @override
  String get refreshAudioSources => 'Hangforrások frissítése';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hangforrás frissítve',
      one: '1 hangforrás frissítve',
      zero: 'Egyetlen hangforrás sem frissült',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Beállítások';

  @override
  String get signOut => 'Kijelentkezés';

  @override
  String get cancel => 'Mégse';

  @override
  String get signOutConfirmation => 'Biztosan ki szeretnél jelentkezni?';

  @override
  String get broadcaster => 'Közvetítő';

  @override
  String get moderators => 'Moderátorok';

  @override
  String get viewers => 'Nézők';

  @override
  String get communityVips => 'Közösségi VIP-tagok';

  @override
  String get searchViewers => 'Nézők keresése';

  @override
  String get reconnecting => 'Újracsatlakozás...';

  @override
  String get twitchBadges => 'Twitch-jelvények';

  @override
  String get selectAll => 'Összes kijelölése';

  @override
  String get quickLinks => 'Gyorshivatkozások';

  @override
  String get swipeToDeleteQuickLinks =>
      'Húzd balra vagy jobbra a gyorshivatkozás törléséhez';

  @override
  String get quickLinksLabelHint => 'Címke';

  @override
  String get invalidUrlErrorText => 'Ez nem tűnik érvényes URL-nek';

  @override
  String get duplicateUrlErrorText => 'Ez a hivatkozás már létezik';

  @override
  String get or => 'vagy';

  @override
  String get clearCookies => 'Sütik törlése';

  @override
  String get disabled => 'Letiltva';

  @override
  String get twitchActivityFeed => 'Twitch tevékenységfolyam';

  @override
  String get signInToEnable =>
      'A funkció engedélyezéséhez be kell jelentkezned';

  @override
  String get customUrl => 'Egyéni URL';

  @override
  String get preview => 'Előnézet';

  @override
  String get audioSources => 'Hangforrások';

  @override
  String get enableOffStreamSwitchTitle =>
      'Engedélyezés közvetítésen kívül (több akkumulátort fogyaszt)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'A hang akkor is lejátszódik, amikor offline vagy';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'A hang csak akkor játszódik le, amikor élőben közvetítesz';

  @override
  String get iosOggWarningTitle => 'Hé! Figyelj!';

  @override
  String get iosOggWarningSubtitle =>
      'Az iOS nem támogatja az *.ogg médiafájlokat, amelyek a Streamlabs alapértelmezett fájljai. Győződj meg róla, hogy a hangforrásaid más formátumot használnak, különben nem fognak lejátszódni.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'A tevékenységfolyam testreszabása';

  @override
  String get audioSourcesSubtitle =>
      'Webes források hozzáadása értesítési hangokhoz';

  @override
  String get quickLinksSubtitle =>
      'Parancsikonok hozzáadása a gyakran használt eszközökhöz';

  @override
  String get chatHistory => 'Csevegési előzmények';

  @override
  String get chatHistorySubtitle => 'A csevegés megjelenésének módosítása';

  @override
  String get textToSpeechSubtitle =>
      'A szövegfelolvasás beállításainak módosítása';

  @override
  String get events => 'Események';

  @override
  String get eventsSubtitle => 'Twitch-események beállítása';

  @override
  String get thirdPartyServices => 'Külső szolgáltatások';

  @override
  String get thirdPartyServicesSubtitle => 'Csatlakozás külső szolgáltatáshoz';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> követ téged';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> és <b>$displayNameTwo</b> követ téged';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> és további $numOthersString felhasználó követ téged';
  }

  @override
  String unmuteUser(String displayName) {
    return '$displayName némításának feloldása';
  }

  @override
  String muteUser(String displayName) {
    return '$displayName némítása';
  }

  @override
  String timeoutUser(String displayName) {
    return '$displayName ideiglenes eltiltása';
  }

  @override
  String banUser(String displayName) {
    return '$displayName kitiltása';
  }

  @override
  String unbanUser(String displayName) {
    return '$displayName kitiltásának feloldása';
  }

  @override
  String viewProfile(String displayName) {
    return '$displayName profiljának megtekintése';
  }

  @override
  String get copyMessage => 'Üzenet másolása';

  @override
  String get deleteMessage => 'Üzenet törlése';

  @override
  String get longScrollNotification => 'Elég messzire görgettél, nem gondolod?';

  @override
  String get stfu => 'kuss';

  @override
  String get globalEmotes => 'Globális hangulatjelek';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString követő',
      one: '1 követő',
      zero: '0 követő',
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
      other: '$countString néző',
      one: '1 néző',
      zero: '0 néző',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Szia! Örülünk, hogy szereted használni a közvetítés előnézetét, de vedd figyelembe, hogy sok akkumulátort fogyaszt. A csevegés olvasása előnézet nélkül meghosszabbítja az akkumulátor üzemidejét.';

  @override
  String get okay => 'Rendben';

  @override
  String get streamPreviewLoading => 'Betöltés (vagy a közvetítés offline)...';

  @override
  String get copiedToClipboard => 'Vágólapra másolva';

  @override
  String get audioSourcesRequirePermissions =>
      'A hangforrásokhoz engedélyek szükségesek';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Engedélyezd a RealtimeChat számára a más alkalmazások feletti megjelenést a hangforrások használatához.';

  @override
  String get audioSourcesRemoveButton => 'Hangforrások eltávolítása';

  @override
  String get audioSourcesOpenSettingsButton => 'Beállítások megnyitása';

  @override
  String get flashOn => 'Vaku be';

  @override
  String get flashOff => 'Vaku ki';

  @override
  String get durationOneSecond => '1 másodperc';

  @override
  String get durationOneMinute => '1 perc';

  @override
  String get durationTenMinutes => '10 perc';

  @override
  String get durationOneHour => '1 óra';

  @override
  String get durationSixHours => '6 óra';

  @override
  String get durationOneDay => '1 nap';

  @override
  String get durationTwoDays => '2 nap';

  @override
  String get durationOneWeek => '1 hét';

  @override
  String get durationTwoWeeks => '2 hét';

  @override
  String get durationOneSecondTimeoutPrompt =>
      'Ideiglenes eltiltás 1 másodpercre';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Ideiglenes eltiltás 1 percre';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Ideiglenes eltiltás 10 percre';

  @override
  String get durationOneHourTimeoutPrompt => 'Ideiglenes eltiltás 1 órára';

  @override
  String get durationSixHoursTimeoutPrompt => 'Ideiglenes eltiltás 6 órára';

  @override
  String get durationOneDayTimeoutPrompt => 'Ideiglenes eltiltás 1 napra';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Ideiglenes eltiltás 2 napra';

  @override
  String get durationOneWeekTimeoutPrompt => 'Ideiglenes eltiltás 1 hétre';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Ideiglenes eltiltás 2 hétre';

  @override
  String get errorFetchingViewerList =>
      'Nem sikerült lekérni a csatorna nézőinek listáját';

  @override
  String get eventsTitle => 'Események';

  @override
  String get followEventConfigTitle => 'Követési esemény';

  @override
  String get customizeYourFollowEvent => 'A követési esemény testreszabása';

  @override
  String get subscribeEventConfigTitle => 'Feliratkozási esemény';

  @override
  String get customizeYourSubscriptionEvent =>
      'A feliratkozási esemény testreszabása';

  @override
  String get cheerEventConfigTitle => 'Cheer-esemény';

  @override
  String get customizeYourCheerEvent => 'A Cheer-esemény testreszabása';

  @override
  String get raidEventConfigTitle => 'Raid-esemény';

  @override
  String get customizeYourRaidEvent => 'A Raid-esemény testreszabása';

  @override
  String get hostEventConfigTitle => 'Hosztolási esemény';

  @override
  String get customizeYourHostEvent => 'A hosztolási esemény testreszabása';

  @override
  String get hypetrainEventConfigTitle => 'Hype Train-esemény';

  @override
  String get customizeYourHypetrainEvent =>
      'A Hype Train-esemény testreszabása';

  @override
  String get pollEventConfigTitle => 'Szavazási esemény';

  @override
  String get customizeYourPollEvent => 'A szavazási esemény testreszabása';

  @override
  String get predictionEventConfigTitle => 'Jóslási esemény';

  @override
  String get customizeYourPredictionEvent => 'A jóslási esemény testreszabása';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Csatornapont-beváltási esemény';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'A csatornapont-beváltási esemény testreszabása';

  @override
  String get outgoingRaidEventConfigTitle => 'Kimenő Raid-esemény';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'A kimenő Raid-esemény testreszabása';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> raidet indított <b>$viewerCountString</b> nézővel!';
  }

  @override
  String get shoutout => 'Kiemelés';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Raid indítása <b>$displayName</b> csatornájára...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString mp';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> végrehajtotta a raidet!';
  }

  @override
  String get raidingEventJoin => 'Csatlakozás';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> raidje megszakadt.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> feliratkozott $tier. szinten!';
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

    return '<b>$gifterUserName</b> $totalString db $tier. szintű feliratkozást ajándékozott, összesen $cumulativeTotalString alkalommal!';
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

    return '<b>$subscriberUserName</b> $cumulativeMonthsString hónapja feliratkozó $tier. szinten!';
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

    return '<b>$subscriberUserName</b> $durationMonthsString hónapra előre feliratkozott $tier. szinten, összesen $cumulativeMonthsString hónapja!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> <b>$value $currency</b> borravalót küldött.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Névtelen felhasználó <b>$value $currency</b> borravalót küldött.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> <b>$formattedAmount</b> borravalót küldött a StreamElements-en.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> <b>$formattedAmount</b> borravalót küldött a Streamlabs-en.';
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

    return '<b>$redeemerUsername</b> beváltotta a következőt: <b>$rewardName</b> (<b>$rewardCostString</b> pont). $userInput';
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

    return '<b>$redeemerUsername</b> beváltotta a következőt: <b>$rewardName</b> (<b>$rewardCostString</b> pont).';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> <b>$bitsString</b> bitet küldött. $cheerMessage';
  }

  @override
  String get anonymous => 'Névtelen';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> hosztol <b>$viewersString</b> nézővel.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'A(z) <b>$level</b>. szintű Hype Train folyamatban! <b>$progressPercent%</b> teljesítve!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'A(z) <b>$levelString</b>. szintű Hype Train sikeresen véget ért.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'A(z) <b>$levelString</b>. szintű Hype Train sikertelen volt.';
  }

  @override
  String get sampleMessage => 'Ez egy mintaszöveg a szövegfelolvasáshoz.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author azt mondta: $text';
  }

  @override
  String get textToSpeechEnabled => 'Szövegfelolvasás bekapcsolva';

  @override
  String get textToSpeechDisabled => 'Szövegfelolvasás kikapcsolva';

  @override
  String get alertsEnabled => 'Csak értesítések';

  @override
  String get pinDuration => 'Rögzítés időtartama';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds másodperc',
      one: '1 másodperc',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes perc',
      one: '1 perc',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Esemény engedélyezése';

  @override
  String get showEventInChatHistory =>
      'Esemény megjelenítése a csevegési előzményekben';

  @override
  String get enableShoutouts => 'Kiemelések engedélyezése';

  @override
  String get enableShoutoutsSubtitle =>
      'A raidelő csatorna hivatkozásának beküldése a csevegésbe';

  @override
  String get raidConfigurationTitle => 'Raid beállítása';

  @override
  String get cheerConfigurationTitle => 'Cheer beállítása';

  @override
  String get followConfigurationTitle => 'Követés beállítása';

  @override
  String get outgoingRaidConfigurationTitle => 'Kimenő raid beállítása';

  @override
  String get hostConfigurationTitle => 'Hosztolás beállítása';

  @override
  String get channelPointConfigurationTitle => 'Csatornapontok beállítása';

  @override
  String get pollConfigurationTitle => 'Szavazás beállítása';

  @override
  String get hypetrainConfigurationTitle => 'Hype Train beállítása';

  @override
  String get subscriptionConfigurationTitle => 'Feliratkozás beállítása';

  @override
  String get predictionConfigurationTitle => 'Jóslás beállítása';

  @override
  String get unfulfilledRewardsPinDuration =>
      'További rögzítési időtartam a nem teljesített jutalmakhoz';

  @override
  String get pollPinDuration =>
      'Rögzítés időtartama az eredmény véglegesítése után';

  @override
  String get hypetrainPinDuration =>
      'Rögzítés időtartama a Hype Train vége után';

  @override
  String get enableGiftedSubscriptions =>
      'Egyéni ajándék feliratkozások engedélyezése';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Minden ajándékozott feliratkozás megjelenítése';

  @override
  String get settingsBackupTitle =>
      'Beállítások biztonsági mentése és visszaállítása';

  @override
  String get cloudBackup => 'Felhőalapú biztonsági mentés';

  @override
  String get lastBackupNever => 'Utolsó mentés: soha';

  @override
  String get backUp => 'Mentés';

  @override
  String get restore => 'Visszaállítás';

  @override
  String get localBackup => 'Helyi biztonsági mentés';

  @override
  String get exportSettings => 'Exportálás';

  @override
  String get importSettings => 'Importálás';

  @override
  String get showViewerAndFollowerCount =>
      'Nézők és követők számának megjelenítése';

  @override
  String get screenOrientation => 'Képernyő tájolása';

  @override
  String get appTheme => 'Alkalmazás témája';

  @override
  String get systemDefault => 'Rendszer';

  @override
  String get portrait => 'Álló';

  @override
  String get landscape => 'Fekvő';

  @override
  String get lightTheme => 'Világos';

  @override
  String get darkTheme => 'Sötét';

  @override
  String get openSourceTitle => 'A RealtimeChat nyílt forráskódú';

  @override
  String get openSourceSubtitle => 'Keress minket a GitHubon!';

  @override
  String get discordSubtitle => 'Csatlakozz a Muxable Discord-szerveréhez!';

  @override
  String get earlyTestersThanks =>
      'Köszönjük minden korai tesztelőnek, aki hibajelentést küldött!';

  @override
  String get discoModeEnabled => '🕺 Diszkó mód bekapcsolva! :D';

  @override
  String get discoModeDisabled => '🕺 Diszkó mód kikapcsolva D:';

  @override
  String get playSampleMessage => 'Mintaüzenet lejátszása';

  @override
  String get textToSpeechRate => 'Szövegfelolvasás sebessége';

  @override
  String get textToSpeechPitch => 'Szövegfelolvasás hangmagassága';

  @override
  String get muteBots => 'Szövegfelolvasás némítása botoknál';

  @override
  String get muteEmotes => 'Összes hangulatjel némítása a szövegfelolvasásnál';

  @override
  String get muteViewerNames => 'Nézők nevének némítása a szövegfelolvasásnál';

  @override
  String get subscribersOnly => 'Csak feliratkozóknak';

  @override
  String get fontSize => 'Betűméret';

  @override
  String get usernameContrastBoost => 'Felhasználónév kontrasztjának növelése';

  @override
  String get twitchBadgeSettings => 'Twitch-jelvények beállításai';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Állítsd be, mely jelvények legyenek láthatók';

  @override
  String get showDeletedMessages => 'Törölt üzenetek megjelenítése';

  @override
  String get deletedMessagesGreyedOut =>
      'A törölt üzenetek szürkén jelennek meg';

  @override
  String get deletedMessagesRemoved => 'A törölt üzenetek el lesznek távolítva';

  @override
  String get showLoginNames => 'Bejelentkezési nevek megjelenítése';

  @override
  String get loginNamesShown =>
      'A bejelentkezési nevek megjelennek, ha eltérnek a megjelenített névtől';

  @override
  String get loginNamesHidden => 'A bejelentkezési nevek rejtve maradnak';

  @override
  String get compactMessages => 'Üzenetek tömörítése';

  @override
  String get dontCompactMessages => 'Ne tömörítse az üzeneteket';

  @override
  String get dontCompactMessagesSubtitle =>
      'Az üzenetek változatlanul jelennek meg';

  @override
  String get compactIndividualMessages => 'Egyes üzenetek tömörítése';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Az üzenetekben lévő ismétlődő szöveg lerövidül';

  @override
  String get announcementPinDuration => 'Közlemény rögzítésének időtartama';

  @override
  String get idleMessageAlertDuration =>
      'Tétlenségi üzenetértesítés időtartama';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Ha ennyi ideig nincs üzenet, és új üzenet érkezik, figyelmeztető hang szólal meg.';

  @override
  String get realtimeCashSubtitle => 'ETH- vagy MATIC-tárca csatlakoztatása';

  @override
  String get walletAddress => 'Tárcacím';

  @override
  String get streamlabsSubtitle => 'Streamlabs-adományok megtekintése';

  @override
  String get streamElementsSubtitle => 'StreamElements-adományok megtekintése';

  @override
  String get thirdPartyAuthError =>
      'Hmm, ez nem sikerült. Próbáld újra, vagy kérdezz rá Discordon!';

  @override
  String get companionAuthBrowserTooOld =>
      'A böngésződ túl régi a közvetlen bejelentkezéshez. Olvasd be ezt a QR-kódot a telefonoddal, hogy egy másik eszközön jelentkezz be.';

  @override
  String get companionAuthScanQrCode =>
      'Olvasd be ezt a QR-kódot a telefonoddal, hogy egy másik eszközön jelentkezz be.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> feliratkozott!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> újra feliratkozott $monthsString hónapja!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> $countString feliratkozást ajándékozott!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> $amountString Kicks-et küldött!';
  }

  @override
  String get signInWithKick => 'Bejelentkezés Kick-fiókkal';

  @override
  String get textToSpeechTooManyMessages =>
      'Túl sok az üzenet. A szövegfelolvasás kikapcsolva';

  @override
  String get turnOffTextToSpeech => 'Kikapcsolás';

  @override
  String get addToChat => 'Hozzáadás a csevegéshez';

  @override
  String get inChat => 'A csevegésben';

  @override
  String get removeFromChat => 'Eltávolítás a csevegésből';

  @override
  String cantChatWithAccount(String provider) {
    return 'A(z) $provider-fiókod nem tud itt csevegni';
  }

  @override
  String get cantChatWithAccounts => 'A fiókjaid nem tudnak itt csevegni';

  @override
  String sendAMessageTo(String channel) {
    return 'Üzenet küldése $channel csatornájára...';
  }

  @override
  String replaceChannel(String channel) {
    return '$channel lecserélése';
  }

  @override
  String get voicePacks => 'Hangcsomagok';

  @override
  String get voicePacksDescription =>
      'A hangcsomagok természetes hangzású hangokkal olvassák fel a csevegést, amelyek a letöltés után offline futnak az eszközödön. A hangokat mesterséges intelligencia generálja, nem valódi személy rögzítette őket.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices hang',
      one: '1 hang',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nyelv',
      one: '1 nyelv',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'A modell licence (OpenRAIL-M) tiltja a káros felhasználást, például mások megszemélyesítését vagy a félretájékoztatás terjesztését, és ezek a korlátozások rád is vonatkoznak.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Törlöd a következőt: $pack? Ezzel $size hely szabadul fel.';
  }

  @override
  String get voicePackDownload => 'Letöltés';

  @override
  String get voicePackUpdate => 'Frissítés';

  @override
  String get voicePackWaitingForWifi => 'Várakozás Wi-Fi-re';

  @override
  String get voicePackUseMobileData => 'Mobiladat-forgalom használata';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Letöltés: $downloaded / $total';
  }

  @override
  String get voicePackInstalling => 'Telepítés';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Nem sikerült telepíteni a következőt: $pack. Ellenőrizd a kapcsolatot, majd próbáld újra.';
  }

  @override
  String get voices => 'Hangok';

  @override
  String get perViewerVoice => 'Nézőnként egyedi hang';

  @override
  String get perViewerVoiceSubtitle =>
      'Minden néző saját hangot kap. A kiválasztott hang az értesítéseket olvassa fel, vagy mindent, ha ez ki van kapcsolva.';

  @override
  String get streamLanguage => 'Közvetítés nyelve';

  @override
  String get ttsEngineNeural => 'Neurális hang (eszközön futó)';

  @override
  String get ttsEngineSystem => 'Rendszerhang';

  @override
  String languageUnsupported(String language) {
    return 'A hangcsomagok nem támogatják a(z) $language nyelvet; a rendszerhang lesz használva';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Ezen az eszközön nincs elég memória a neurális hangokhoz, ezért a csevegést a rendszerhang olvassa fel.';

  @override
  String get neuralFallbackLoadFailed =>
      'A neurális hangot nem sikerült betölteni, ezért a csevegést a rendszerhang olvassa fel.';

  @override
  String get accounts => 'Fiókok';

  @override
  String get accountsSubtitle =>
      'Jelentkezz be minden platformra, amelyen közvetítesz';

  @override
  String addProviderAccount(String provider) {
    return '$provider-fiók hozzáadása';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Bejelentkezés $provider-fiókkal';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Kijelentkezel a(z) $channel csatornából a(z) $provider platformon?';
  }

  @override
  String get signOutOfAll => 'Kijelentkezés az összes fiókból';
}
