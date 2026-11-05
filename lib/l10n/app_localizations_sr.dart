// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get sendAMessage => 'Пошаљите поруку...';

  @override
  String get writeSomething => 'Напишите нешто...';

  @override
  String get speakToTheCrowds => 'Обратите се публици...';

  @override
  String get shareYourThoughts => 'Поделите своје мисли...';

  @override
  String get saySomethingYouLittleBitch => 'Реци нешто, мала кучко...';

  @override
  String get search => 'Претрага';

  @override
  String get notSignedIn => 'Нисте пријављени';

  @override
  String get searchChannels => 'Претрага';

  @override
  String get raidAChannel => 'Рејд';

  @override
  String get noMessagesEmptyState => 'Овде је тихо.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count нових порука',
      few: '$count нове поруке',
      one: '$count нова порука',
      zero: 'Нема нових порука',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Пријавите се преко Twitch-а';

  @override
  String get signInError =>
      'Дошло је до грешке при пријављивању. Покушајте поново.';

  @override
  String get continueAsGuest => 'Наставите као гост';

  @override
  String get signInToSendMessages => 'Пријавите се да бисте слали поруке';

  @override
  String get currentViewers => 'Тренутни гледаоци';

  @override
  String get textToSpeech => 'Претварање текста у говор';

  @override
  String get streamPreview => 'Преглед стрима';

  @override
  String get activityFeed => 'Ток активности';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Стрим је уживо: $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Стрим је ван мреже: $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Чет је обрисан: $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Подеси брзе везе';

  @override
  String get disableRainMode => 'Искључи режим кише';

  @override
  String get enableRainMode => 'Укључи режим кише';

  @override
  String get disableRainModeSubtitle => 'Интеракција ће бити омогућена';

  @override
  String get enableRainModeSubtitle => 'Интеракција ће бити онемогућена';

  @override
  String get refreshAudioSources => 'Освежи изворе звука';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count извора звука је освежено',
      few: '$count извора звука су освежена',
      one: '$count извор звука је освежен',
      zero: 'Ниједан извор звука није освежен',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Подешавања';

  @override
  String get signOut => 'Одјави се';

  @override
  String get cancel => 'Откажи';

  @override
  String get signOutConfirmation => 'Желите ли заиста да се одјавите?';

  @override
  String get broadcaster => 'Емитер';

  @override
  String get moderators => 'Модератори';

  @override
  String get viewers => 'Гледаоци';

  @override
  String get communityVips => 'VIP чланови заједнице';

  @override
  String get searchViewers => 'Претражи гледаоце';

  @override
  String get reconnecting => 'Поновно повезивање...';

  @override
  String get twitchBadges => 'Twitch значке';

  @override
  String get selectAll => 'Изабери све';

  @override
  String get quickLinks => 'Брзе везе';

  @override
  String get swipeToDeleteQuickLinks =>
      'Превуците улево или удесно да бисте обрисали брзу везу';

  @override
  String get quickLinksLabelHint => 'Ознака';

  @override
  String get invalidUrlErrorText => 'Ово не изгледа као важећи URL';

  @override
  String get duplicateUrlErrorText => 'Ова веза већ постоји';

  @override
  String get or => 'или';

  @override
  String get clearCookies => 'Обриши колачиће';

  @override
  String get disabled => 'Онемогућено';

  @override
  String get twitchActivityFeed => 'Twitch ток активности';

  @override
  String get signInToEnable => 'Морате бити пријављени да бисте ово омогућили';

  @override
  String get customUrl => 'Прилагођени URL';

  @override
  String get preview => 'Преглед';

  @override
  String get audioSources => 'Извори звука';

  @override
  String get enableOffStreamSwitchTitle =>
      'Омогући ван стрима (троши више батерије)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Звук ће се репродуковати и када нисте уживо';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Звук ће се репродуковати само када сте уживо';

  @override
  String get iosOggWarningTitle => 'Хеј! Слушај!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS не подржава медијске датотеке *.ogg, које су подразумеване датотеке на платформи Streamlabs. Уверите се да ваши извори звука користе други формат, иначе се неће репродуковати.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Прилагодите свој ток активности';

  @override
  String get audioSourcesSubtitle => 'Додајте веб-изворе за звукове обавештења';

  @override
  String get quickLinksSubtitle => 'Додајте пречице до често коришћених алатки';

  @override
  String get chatHistory => 'Историја чета';

  @override
  String get chatHistorySubtitle => 'Промените изглед чета';

  @override
  String get textToSpeechSubtitle =>
      'Промените подешавања претварања текста у говор';

  @override
  String get events => 'Догађаји';

  @override
  String get eventsSubtitle => 'Подесите Twitch догађаје';

  @override
  String get thirdPartyServices => 'Услуге трећих страна';

  @override
  String get thirdPartyServicesSubtitle =>
      'Повежите се са услугом треће стране';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> вас прати';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> и <b>$displayNameTwo</b> вас прате';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> и још $numOthersString вас прате';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Укључи звук за $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Искључи звук за $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Привремено удаљи $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Блокирај $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Одблокирај $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Прикажи профил корисника $displayName';
  }

  @override
  String get copyMessage => 'Копирај поруку';

  @override
  String get deleteMessage => 'Обриши поруку';

  @override
  String get longScrollNotification =>
      'Прилично далеко сте одскроловали, зар не?';

  @override
  String get stfu => 'ућути';

  @override
  String get globalEmotes => 'Глобални емотикони';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString пратилаца',
      few: '$countString пратиоца',
      one: '$countString пратилац',
      zero: '0 пратилаца',
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
      other: '$countString гледалаца',
      few: '$countString гледаоца',
      one: '$countString гледалац',
      zero: '0 гледалаца',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Здраво! Драго нам је што волите преглед стрима, али имајте на уму да троши много батерије. Читање чета без њега продужиће трајање батерије.';

  @override
  String get okay => 'У реду';

  @override
  String get streamPreviewLoading => 'Учитавање (или је стрим ван мреже)...';

  @override
  String get copiedToClipboard => 'Копирано у привремену меморију';

  @override
  String get audioSourcesRequirePermissions => 'Извори звука захтевају дозволе';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Одобрите да се RealtimeChat приказује преко других апликација како бисте користили изворе звука.';

  @override
  String get audioSourcesRemoveButton => 'Уклони изворе звука';

  @override
  String get audioSourcesOpenSettingsButton => 'Отвори подешавања';

  @override
  String get flashOn => 'Блиц укључен';

  @override
  String get flashOff => 'Блиц искључен';

  @override
  String get durationOneSecond => '1 секунда';

  @override
  String get durationOneMinute => '1 минут';

  @override
  String get durationTenMinutes => '10 минута';

  @override
  String get durationOneHour => '1 сат';

  @override
  String get durationSixHours => '6 сати';

  @override
  String get durationOneDay => '1 дан';

  @override
  String get durationTwoDays => '2 дана';

  @override
  String get durationOneWeek => '1 недеља';

  @override
  String get durationTwoWeeks => '2 недеље';

  @override
  String get durationOneSecondTimeoutPrompt =>
      'Привремена забрана на 1 секунду';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Привремена забрана на 1 минут';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      'Привремена забрана на 10 минута';

  @override
  String get durationOneHourTimeoutPrompt => 'Привремена забрана на 1 сат';

  @override
  String get durationSixHoursTimeoutPrompt => 'Привремена забрана на 6 сати';

  @override
  String get durationOneDayTimeoutPrompt => 'Привремена забрана на 1 дан';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Привремена забрана на 2 дана';

  @override
  String get durationOneWeekTimeoutPrompt => 'Привремена забрана на 1 недељу';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Привремена забрана на 2 недеље';

  @override
  String get errorFetchingViewerList =>
      'Нисмо успели да преузмемо листу гледалаца за овај канал';

  @override
  String get eventsTitle => 'Догађаји';

  @override
  String get followEventConfigTitle => 'Догађај праћења';

  @override
  String get customizeYourFollowEvent => 'Прилагодите догађај праћења';

  @override
  String get subscribeEventConfigTitle => 'Догађај претплате';

  @override
  String get customizeYourSubscriptionEvent => 'Прилагодите догађај претплате';

  @override
  String get cheerEventConfigTitle => 'Догађај бодрења';

  @override
  String get customizeYourCheerEvent => 'Прилагодите догађај бодрења';

  @override
  String get raidEventConfigTitle => 'Догађај рејда';

  @override
  String get customizeYourRaidEvent => 'Прилагодите догађај рејда';

  @override
  String get hostEventConfigTitle => 'Догађај угошћавања';

  @override
  String get customizeYourHostEvent => 'Прилагодите догађај угошћавања';

  @override
  String get hypetrainEventConfigTitle => 'Догађај Hype Train';

  @override
  String get customizeYourHypetrainEvent => 'Прилагодите догађај Hype Train';

  @override
  String get pollEventConfigTitle => 'Догађај анкете';

  @override
  String get customizeYourPollEvent => 'Прилагодите догађај анкете';

  @override
  String get predictionEventConfigTitle => 'Догађај предвиђања';

  @override
  String get customizeYourPredictionEvent => 'Прилагодите догађај предвиђања';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Догађај искоришћавања поена канала';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Прилагодите догађај искоришћавања поена канала';

  @override
  String get outgoingRaidEventConfigTitle => 'Догађај одлазног рејда';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Прилагодите догађај одлазног рејда';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> рејдује са <b>$viewerCountString</b> гледалаца!';
  }

  @override
  String get shoutout => 'Похвала';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Рејдовање канала <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString с';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> је рејдовао!';
  }

  @override
  String get raidingEventJoin => 'Придружи се';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Рејд корисника <b>$displayName</b> је отказан.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> се претплатио на нивоу $tier!';
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

    return '<b>$gifterUserName</b> је поклонио $totalString претплата нивоа $tier, укупно $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> је претплаћен $cumulativeMonthsString месеци на нивоу $tier!';
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

    return '<b>$subscriberUserName</b> се претплатио на нивоу $tier на $durationMonthsString месеци унапред, укупно $cumulativeMonthsString месеци!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> је дао напојницу од <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Анонимни корисник је дао напојницу од <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> је дао напојницу од <b>$formattedAmount</b> на платформи StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> је дао напојницу од <b>$formattedAmount</b> на платформи Streamlabs.';
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

    return '<b>$redeemerUsername</b> је искористио <b>$rewardName</b> за <b>$rewardCostString</b> поена. $userInput';
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

    return '<b>$redeemerUsername</b> је искористио <b>$rewardName</b> за <b>$rewardCostString</b> поена.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> је послао <b>$bitsString</b> битова. $cheerMessage';
  }

  @override
  String get anonymous => 'Анонимно';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> угошћује са групом од <b>$viewersString</b> гледалаца.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train ниво <b>$level</b> је у току! Завршено је <b>$progressPercent%</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train ниво <b>$levelString</b> је успео.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train ниво <b>$levelString</b> није успео.';
  }

  @override
  String get sampleMessage =>
      'Ово је пример поруке за претварање текста у говор.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author је рекао: $text';
  }

  @override
  String get textToSpeechEnabled => 'Претварање текста у говор је омогућено';

  @override
  String get textToSpeechDisabled => 'Претварање текста у говор је онемогућено';

  @override
  String get alertsEnabled => 'Само обавештења';

  @override
  String get pinDuration => 'Трајање качења';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds секунди',
      few: '$seconds секунде',
      one: '$seconds секунда',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes минута',
      few: '$minutes минута',
      one: '$minutes минут',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Омогући догађај';

  @override
  String get showEventInChatHistory => 'Прикажи догађај у историји чета';

  @override
  String get enableShoutouts => 'Омогући похвале';

  @override
  String get enableShoutoutsSubtitle =>
      'Пошаљи везу до канала који рејдује у чет';

  @override
  String get raidConfigurationTitle => 'Подешавање рејда';

  @override
  String get cheerConfigurationTitle => 'Подешавање бодрења';

  @override
  String get followConfigurationTitle => 'Подешавање праћења';

  @override
  String get outgoingRaidConfigurationTitle => 'Подешавање одлазног рејда';

  @override
  String get hostConfigurationTitle => 'Подешавање угошћавања';

  @override
  String get channelPointConfigurationTitle => 'Подешавање поена канала';

  @override
  String get pollConfigurationTitle => 'Подешавање анкете';

  @override
  String get hypetrainConfigurationTitle => 'Подешавање за Hype Train';

  @override
  String get subscriptionConfigurationTitle => 'Подешавање претплате';

  @override
  String get predictionConfigurationTitle => 'Подешавање предвиђања';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Додатно трајање качења за неиспуњене награде';

  @override
  String get pollPinDuration => 'Трајање качења након коначног резултата';

  @override
  String get hypetrainPinDuration =>
      'Трајање качења након завршетка догађаја Hype Train';

  @override
  String get enableGiftedSubscriptions =>
      'Омогући појединачне поклоњене претплате';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Прикажи сваку поклоњену претплату';

  @override
  String get settingsBackupTitle => 'Резервна копија и враћање подешавања';

  @override
  String get cloudBackup => 'Резервна копија у облаку';

  @override
  String get lastBackupNever => 'Последња резервна копија: никада';

  @override
  String get backUp => 'Направи резервну копију';

  @override
  String get restore => 'Врати';

  @override
  String get localBackup => 'Локална резервна копија';

  @override
  String get exportSettings => 'Извези';

  @override
  String get importSettings => 'Увези';

  @override
  String get showViewerAndFollowerCount => 'Прикажи број гледалаца и пратилаца';

  @override
  String get screenOrientation => 'Оријентација екрана';

  @override
  String get appTheme => 'Тема апликације';

  @override
  String get systemDefault => 'Системска';

  @override
  String get portrait => 'Усправно';

  @override
  String get landscape => 'Водоравно';

  @override
  String get lightTheme => 'Светла';

  @override
  String get darkTheme => 'Тамна';

  @override
  String get openSourceTitle => 'RealtimeChat је отвореног кода';

  @override
  String get openSourceSubtitle => 'Пронађите нас на GitHub-у!';

  @override
  String get discordSubtitle => 'Придружите се Muxable Discord серверу!';

  @override
  String get earlyTestersThanks =>
      'Хвала свим раним тестерима који су слали извештаје о грешкама!';

  @override
  String get discoModeEnabled => '🕺 Диско режим је укључен! :D';

  @override
  String get discoModeDisabled => '🕺 Диско режим је искључен D:';

  @override
  String get playSampleMessage => 'Пусти пример поруке';

  @override
  String get textToSpeechRate => 'Брзина претварања текста у говор';

  @override
  String get textToSpeechPitch => 'Висина гласа за претварање текста у говор';

  @override
  String get muteBots => 'Искључи читање порука ботова';

  @override
  String get muteEmotes => 'Искључи читање емотикона';

  @override
  String get muteViewerNames => 'Искључи читање имена гледалаца';

  @override
  String get subscribersOnly => 'Само претплатници';

  @override
  String get fontSize => 'Величина фонта';

  @override
  String get usernameContrastBoost => 'Појачање контраста корисничког имена';

  @override
  String get twitchBadgeSettings => 'Подешавања Twitch значки';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Управљајте тиме које су значке видљиве';

  @override
  String get showDeletedMessages => 'Прикажи обрисане поруке';

  @override
  String get deletedMessagesGreyedOut => 'Обрисане поруке биће засивљене';

  @override
  String get deletedMessagesRemoved => 'Обрисане поруке биће уклоњене';

  @override
  String get showLoginNames => 'Прикажи корисничка имена за пријаву';

  @override
  String get loginNamesShown =>
      'Корисничка имена за пријаву биће приказана ако се разликују од приказаног имена';

  @override
  String get loginNamesHidden => 'Корисничка имена за пријаву биће сакривена';

  @override
  String get compactMessages => 'Сажимање порука';

  @override
  String get dontCompactMessages => 'Не сажимај поруке';

  @override
  String get dontCompactMessagesSubtitle => 'Поруке се приказују неизмењене';

  @override
  String get compactIndividualMessages => 'Сажми појединачне поруке';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Понављајући текст у порукама се скраћује';

  @override
  String get announcementPinDuration => 'Трајање качења обавештења';

  @override
  String get idleMessageAlertDuration =>
      'Трајање неактивности за звучно обавештење';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Ако нема порука током овог времена и стигне нова, огласиће се звук обавештења.';

  @override
  String get realtimeCashSubtitle => 'Повежите ETH или MATIC новчаник';

  @override
  String get walletAddress => 'Адреса новчаника';

  @override
  String get streamlabsSubtitle => 'Погледајте своје Streamlabs донације';

  @override
  String get streamElementsSubtitle =>
      'Погледајте своје StreamElements донације';

  @override
  String get thirdPartyAuthError =>
      'Хм, то није успело. Покушајте поново или питајте на Discord-у?';

  @override
  String get companionAuthBrowserTooOld =>
      'Ваш прегледач је престар да би подржао директно пријављивање. Скенирајте овај QR код телефоном да бисте се пријавили на другом уређају.';

  @override
  String get companionAuthScanQrCode =>
      'Скенирајте овај QR код телефоном да бисте се пријавили на другом уређају.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> се претплатио!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> је обновио претплату на $monthsString месеци!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> је поклонио $countString претплата!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> је послао $amountString Kicks-а!';
  }

  @override
  String get signInWithKick => 'Пријавите се преко Kick-а';

  @override
  String get textToSpeechTooManyMessages =>
      'Има превише порука. Претварање текста у говор је онемогућено';

  @override
  String get turnOffTextToSpeech => 'Искључи';

  @override
  String get addToChat => 'Додај у чет';

  @override
  String get inChat => 'У чету';

  @override
  String get removeFromChat => 'Уклони из чета';

  @override
  String cantChatWithAccount(String provider) {
    return 'Ваш $provider налог не може да четује овде';
  }

  @override
  String get cantChatWithAccounts => 'Ваши налози не могу да четују овде';

  @override
  String sendAMessageTo(String channel) {
    return 'Пошаљите поруку за $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Замени $channel';
  }

  @override
  String get voicePacks => 'Гласовни пакети';

  @override
  String get voicePacksDescription =>
      'Гласовни пакети читају чет природним гласовима који раде на вашем уређају, ван мреже након преузимања. Гласове машински генерише вештачка интелигенција, није их снимио човек.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices гласова',
      few: '$voices гласа',
      one: '$voices глас',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count језика',
      few: '$count језика',
      one: '$count језик',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Лиценца овог модела (OpenRAIL-M) забрањује штетну употребу, као што је лажно представљање или ширење дезинформација, а ова ограничења важе и за вас.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Обрисати пакет $pack? Овим се ослобађа $size.';
  }

  @override
  String get voicePackDownload => 'Преузми';

  @override
  String get voicePackUpdate => 'Ажурирај';

  @override
  String get voicePackWaitingForWifi => 'Чекање на Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Користи мобилне податке';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Преузимање: $downloaded од $total';
  }

  @override
  String get voicePackInstalling => 'Инсталирање';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Инсталирање пакета $pack није успело. Проверите везу и покушајте поново.';
  }

  @override
  String get voices => 'Гласови';

  @override
  String get perViewerVoice => 'Глас по гледаоцу';

  @override
  String get perViewerVoiceSubtitle =>
      'Сваки гледалац добија сопствени глас. Глас који изаберете чита обавештења или све када је ово искључено.';

  @override
  String get streamLanguage => 'Језик стрима';

  @override
  String get ttsEngineNeural => 'Неуронски глас (на уређају)';

  @override
  String get ttsEngineSystem => 'Системски глас';

  @override
  String languageUnsupported(String language) {
    return 'Ваши гласовни пакети не подржавају језик ($language); користиће се системски глас';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Овај уређај нема довољно меморије за неуронске гласове, па се чет чита системским гласом.';

  @override
  String get neuralFallbackLoadFailed =>
      'Неуронски глас није могао да се учита, па се чет чита системским гласом.';

  @override
  String get accounts => 'Налози';

  @override
  String get accountsSubtitle =>
      'Пријавите се на сваку платформу на којој стримујете';

  @override
  String addProviderAccount(String provider) {
    return 'Додај $provider налог';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Пријавите се преко платформе $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Одјавити се са канала $channel на платформи $provider?';
  }

  @override
  String get signOutOfAll => 'Одјави се са свих налога';
}
