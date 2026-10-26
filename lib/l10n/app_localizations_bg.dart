// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get sendAMessage => 'Изпратете съобщение...';

  @override
  String get writeSomething => 'Напишете нещо...';

  @override
  String get speakToTheCrowds => 'Говорете пред тълпата...';

  @override
  String get shareYourThoughts => 'Споделете мислите си...';

  @override
  String get saySomethingYouLittleBitch => 'Кажи нещо, малко куче...';

  @override
  String get search => 'Търсене';

  @override
  String get notSignedIn => 'Не сте влезли';

  @override
  String get searchChannels => 'Търсене';

  @override
  String get raidAChannel => 'Рейд';

  @override
  String get noMessagesEmptyState => 'Тук е тихо.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count нови съобщения',
      one: '$count ново съобщение',
      zero: 'Няма нови съобщения',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Вход с Twitch';

  @override
  String get signInError =>
      'Възникна грешка при влизане. Моля, опитайте отново.';

  @override
  String get continueAsGuest => 'Продължете като гост';

  @override
  String get signInToSendMessages => 'Влезте, за да изпращате съобщения';

  @override
  String get currentViewers => 'Текущи зрители';

  @override
  String get textToSpeech => 'Текст в реч';

  @override
  String get streamPreview => 'Преглед на потока';

  @override
  String get activityFeed => 'Емисия за активност';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Потокът е на живо на $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Потокът е офлайн на $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Чатът е изчистен на $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Конфигуриране на бързи връзки';

  @override
  String get disableRainMode => 'Изключване на режим за дъжд';

  @override
  String get enableRainMode => 'Включване на режим за дъжд';

  @override
  String get disableRainModeSubtitle => 'Взаимодействието ще бъде разрешено';

  @override
  String get enableRainModeSubtitle => 'Взаимодействието ще бъде забранено';

  @override
  String get refreshAudioSources => 'Обновяване на аудио източниците';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count обновени аудио източника',
      one: '$count обновен аудио източник',
      zero: 'Няма обновени аудио източници',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Настройки';

  @override
  String get signOut => 'Изход';

  @override
  String get cancel => 'Отказ';

  @override
  String get signOutConfirmation => 'Сигурни ли сте, че искате да излезете?';

  @override
  String get broadcaster => 'Стриймър';

  @override
  String get moderators => 'Модератори';

  @override
  String get viewers => 'Зрители';

  @override
  String get communityVips => 'VIP потребители на общността';

  @override
  String get searchViewers => 'Търсене на зрители';

  @override
  String get reconnecting => 'Повторно свързване...';

  @override
  String get twitchBadges => 'Значки в Twitch';

  @override
  String get selectAll => 'Избиране на всички';

  @override
  String get quickLinks => 'Бързи връзки';

  @override
  String get swipeToDeleteQuickLinks =>
      'Плъзнете наляво или надясно, за да изтриете бърза връзка';

  @override
  String get quickLinksLabelHint => 'Етикет';

  @override
  String get invalidUrlErrorText => 'Това не прилича на валиден URL адрес';

  @override
  String get duplicateUrlErrorText => 'Тази връзка вече съществува';

  @override
  String get or => 'или';

  @override
  String get clearCookies => 'Изчистване на бисквитките';

  @override
  String get disabled => 'Изключено';

  @override
  String get twitchActivityFeed => 'Емисия за активност на Twitch';

  @override
  String get signInToEnable => 'Трябва да сте влезли, за да активирате това';

  @override
  String get customUrl => 'Персонализиран URL адрес';

  @override
  String get preview => 'Преглед';

  @override
  String get audioSources => 'Аудио източници';

  @override
  String get enableOffStreamSwitchTitle =>
      'Включване извън поток (използва повече батерия)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Аудиото ще се възпроизвежда и когато сте офлайн';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Аудиото ще се възпроизвежда само когато сте на живо';

  @override
  String get iosOggWarningTitle => 'Хей! Слушайте!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS не поддържа мултимедийни файлове *.ogg, които са файловете по подразбиране в Streamlabs. Уверете се, че аудио източниците ви използват друг формат, в противен случай няма да се възпроизвеждат.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle =>
      'Персонализирайте емисията си за активност';

  @override
  String get audioSourcesSubtitle =>
      'Добавете уеб източници за звукови известия';

  @override
  String get quickLinksSubtitle =>
      'Добавете преки пътища към често използвани инструменти';

  @override
  String get chatHistory => 'История на чата';

  @override
  String get chatHistorySubtitle => 'Променете облика на чата';

  @override
  String get textToSpeechSubtitle =>
      'Променете настройките за преобразуване на текст в реч';

  @override
  String get events => 'Събития';

  @override
  String get eventsSubtitle => 'Конфигурирайте събитията в Twitch';

  @override
  String get thirdPartyServices => 'Услуги на трети страни';

  @override
  String get thirdPartyServicesSubtitle =>
      'Свържете се с услуга на трета страна';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> ви последва';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> и <b>$displayNameTwo</b> ви последваха';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> и още $numOthersString ви последваха';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Включване на звука за $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Заглушаване на $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Временно блокиране на $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Блокиране на $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Отблокиране на $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Преглед на профила на $displayName';
  }

  @override
  String get copyMessage => 'Копиране на съобщението';

  @override
  String get deleteMessage => 'Изтриване на съобщението';

  @override
  String get longScrollNotification => 'Превъртате доста далеч, не мислите ли?';

  @override
  String get stfu => 'млъкни';

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
      other: '$countString последователи',
      one: '$countString последовател',
      zero: '0 последователи',
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
      other: '$countString зрители',
      one: '$countString зрител',
      zero: '0 зрители',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Здравейте! Радваме се, че харесвате прегледа на потока, но имайте предвид, че той изразходва много батерия. Четенето на чата без него ще удължи живота на батерията ви.';

  @override
  String get okay => 'Добре';

  @override
  String get streamPreviewLoading => 'Зареждане (или потокът е офлайн)...';

  @override
  String get copiedToClipboard => 'Копирано в клипборда';

  @override
  String get audioSourcesRequirePermissions =>
      'Аудио източниците изискват разрешения';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Разрешете на RealtimeChat да се показва върху други приложения, за да използвате аудио източници.';

  @override
  String get audioSourcesRemoveButton => 'Премахване на аудио източниците';

  @override
  String get audioSourcesOpenSettingsButton => 'Отваряне на настройките';

  @override
  String get flashOn => 'Светкавицата е включена';

  @override
  String get flashOff => 'Светкавицата е изключена';

  @override
  String get durationOneSecond => '1 секунда';

  @override
  String get durationOneMinute => '1 минута';

  @override
  String get durationTenMinutes => '10 минути';

  @override
  String get durationOneHour => '1 час';

  @override
  String get durationSixHours => '6 часа';

  @override
  String get durationOneDay => '1 ден';

  @override
  String get durationTwoDays => '2 дни';

  @override
  String get durationOneWeek => '1 седмица';

  @override
  String get durationTwoWeeks => '2 седмици';

  @override
  String get durationOneSecondTimeoutPrompt =>
      'Временно блокиране за 1 секунда';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Временно блокиране за 1 минута';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      'Временно блокиране за 10 минути';

  @override
  String get durationOneHourTimeoutPrompt => 'Временно блокиране за 1 час';

  @override
  String get durationSixHoursTimeoutPrompt => 'Временно блокиране за 6 часа';

  @override
  String get durationOneDayTimeoutPrompt => 'Временно блокиране за 1 ден';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Временно блокиране за 2 дни';

  @override
  String get durationOneWeekTimeoutPrompt => 'Временно блокиране за 1 седмица';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Временно блокиране за 2 седмици';

  @override
  String get errorFetchingViewerList =>
      'Не успяхме да извлечем списъка със зрители за този канал';

  @override
  String get eventsTitle => 'Събития';

  @override
  String get followEventConfigTitle => 'Събитие за последване';

  @override
  String get customizeYourFollowEvent =>
      'Персонализирайте събитието си за последване';

  @override
  String get subscribeEventConfigTitle => 'Събитие за абониране';

  @override
  String get customizeYourSubscriptionEvent =>
      'Персонализирайте събитието си за абонамент';

  @override
  String get cheerEventConfigTitle => 'Събитие за подкрепа с битове';

  @override
  String get customizeYourCheerEvent =>
      'Персонализирайте събитието си за подкрепа с битове';

  @override
  String get raidEventConfigTitle => 'Събитие за рейд';

  @override
  String get customizeYourRaidEvent => 'Персонализирайте събитието си за рейд';

  @override
  String get hostEventConfigTitle => 'Събитие за хостване';

  @override
  String get customizeYourHostEvent =>
      'Персонализирайте събитието си за хостване';

  @override
  String get hypetrainEventConfigTitle => 'Събитие за Hype Train';

  @override
  String get customizeYourHypetrainEvent =>
      'Персонализирайте събитието си за Hype Train';

  @override
  String get pollEventConfigTitle => 'Събитие за анкета';

  @override
  String get customizeYourPollEvent =>
      'Персонализирайте събитието си за анкета';

  @override
  String get predictionEventConfigTitle => 'Събитие за прогноза';

  @override
  String get customizeYourPredictionEvent =>
      'Персонализирайте събитието си за прогноза';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Събитие за осребряване на точки на канала';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Персонализирайте събитието си за осребряване на точки на канала';

  @override
  String get outgoingRaidEventConfigTitle => 'Събитие за изходящ рейд';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Персонализирайте събитието си за изходящ рейд';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> прави рейд с <b>$viewerCountString</b> зрители!';
  }

  @override
  String get shoutout => 'Препоръка';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Рейд към <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString с';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> направи рейд!';
  }

  @override
  String get raidingEventJoin => 'Присъединяване';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Рейдът на <b>$displayName</b> беше отменен.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> се абонира на ниво $tier!';
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

    return '<b>$gifterUserName</b> подари $totalString абонамента от ниво $tier, общо $cumulativeTotalString!';
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

    return '<b>$subscriberUserName</b> се абонира за $cumulativeMonthsString месеца на ниво $tier!';
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

    return '<b>$subscriberUserName</b> се абонира на ниво $tier за $durationMonthsString месеца предварително, общо $cumulativeMonthsString месеца!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> даде бакшиш от <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Анонимен даде бакшиш от <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> даде бакшиш от <b>$formattedAmount</b> в StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> даде бакшиш от <b>$formattedAmount</b> в Streamlabs.';
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

    return '<b>$redeemerUsername</b> осребри <b>$rewardName</b> за <b>$rewardCostString</b> точки. $userInput';
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

    return '<b>$redeemerUsername</b> осребри <b>$rewardName</b> за <b>$rewardCostString</b> точки.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> подкрепи с <b>$bitsString</b> бита. $cheerMessage';
  }

  @override
  String get anonymous => 'Анонимен';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> хоства с група от <b>$viewersString</b> зрители.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train ниво <b>$level</b> е в ход! Завършено на <b>$progressPercent%</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train ниво <b>$levelString</b> завърши успешно.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train ниво <b>$levelString</b> беше неуспешно.';
  }

  @override
  String get sampleMessage =>
      'Това е примерно съобщение за преобразуване на текст в реч.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author каза: $text';
  }

  @override
  String get textToSpeechEnabled => 'Преобразуването на текст в реч е включено';

  @override
  String get textToSpeechDisabled =>
      'Преобразуването на текст в реч е изключено';

  @override
  String get alertsEnabled => 'Само известия';

  @override
  String get pinDuration => 'Продължителност на закачване';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds секунди',
      one: '$seconds секунда',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes минути',
      one: '$minutes минута',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Включване на събитието';

  @override
  String get showEventInChatHistory =>
      'Показване на събитието в историята на чата';

  @override
  String get enableShoutouts => 'Включване на препоръките';

  @override
  String get enableShoutoutsSubtitle =>
      'Изпращане на връзка към рейдващия канал в чата';

  @override
  String get raidConfigurationTitle => 'Конфигуриране на рейд';

  @override
  String get cheerConfigurationTitle => 'Конфигуриране на подкрепа с битове';

  @override
  String get followConfigurationTitle => 'Конфигуриране на последване';

  @override
  String get outgoingRaidConfigurationTitle => 'Конфигуриране на изходящ рейд';

  @override
  String get hostConfigurationTitle => 'Конфигуриране на хостване';

  @override
  String get channelPointConfigurationTitle =>
      'Конфигуриране на точки на канала';

  @override
  String get pollConfigurationTitle => 'Конфигуриране на анкета';

  @override
  String get hypetrainConfigurationTitle => 'Конфигуриране на Hype Train';

  @override
  String get subscriptionConfigurationTitle => 'Конфигуриране на абонамент';

  @override
  String get predictionConfigurationTitle => 'Конфигуриране на прогноза';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Допълнителна продължителност на закачване за неизпълнени награди';

  @override
  String get pollPinDuration =>
      'Продължителност на закачване след финализиране на резултата';

  @override
  String get hypetrainPinDuration =>
      'Продължителност на закачване след края на Hype Train';

  @override
  String get enableGiftedSubscriptions =>
      'Включване на отделни подарени абонаменти';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Показване на всеки подарен абонамент';

  @override
  String get settingsBackupTitle =>
      'Архивиране и възстановяване на настройките';

  @override
  String get cloudBackup => 'Архивиране в облака';

  @override
  String get lastBackupNever => 'Последно архивиране: никога';

  @override
  String get backUp => 'Архивиране';

  @override
  String get restore => 'Възстановяване';

  @override
  String get localBackup => 'Локално архивиране';

  @override
  String get exportSettings => 'Експортиране';

  @override
  String get importSettings => 'Импортиране';

  @override
  String get showViewerAndFollowerCount =>
      'Показване на броя на зрителите и последователите';

  @override
  String get screenOrientation => 'Ориентация на екрана';

  @override
  String get appTheme => 'Тема на приложението';

  @override
  String get systemDefault => 'Системна';

  @override
  String get portrait => 'Портретна';

  @override
  String get landscape => 'Пейзажна';

  @override
  String get lightTheme => 'Светла';

  @override
  String get darkTheme => 'Тъмна';

  @override
  String get openSourceTitle => 'RealtimeChat е с отворен код';

  @override
  String get openSourceSubtitle => 'Намерете ни в GitHub!';

  @override
  String get discordSubtitle =>
      'Присъединете се към Discord сървъра на Muxable!';

  @override
  String get earlyTestersThanks =>
      'Благодарим на всички ранни тестери, които изпратиха доклади за грешки!';

  @override
  String get discoModeEnabled => '🕺 Диско режимът е включен! :D';

  @override
  String get discoModeDisabled => '🕺 Диско режимът е изключен D:';

  @override
  String get playSampleMessage => 'Възпроизвеждане на примерно съобщение';

  @override
  String get textToSpeechRate => 'Скорост на речта';

  @override
  String get textToSpeechPitch => 'Височина на гласа';

  @override
  String get muteBots => 'Заглушаване на текст в реч за ботове';

  @override
  String get muteEmotes => 'Заглушаване на всички емотикони при текст в реч';

  @override
  String get muteViewerNames =>
      'Заглушаване на имената на зрителите при текст в реч';

  @override
  String get subscribersOnly => 'Само за абонати';

  @override
  String get fontSize => 'Размер на шрифта';

  @override
  String get usernameContrastBoost =>
      'Усилване на контраста на потребителските имена';

  @override
  String get twitchBadgeSettings => 'Настройки за значки в Twitch';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Управлявайте кои значки да са видими';

  @override
  String get showDeletedMessages => 'Показване на изтритите съобщения';

  @override
  String get deletedMessagesGreyedOut =>
      'Изтритите съобщения ще бъдат показани в сиво';

  @override
  String get deletedMessagesRemoved =>
      'Изтритите съобщения ще бъдат премахвани';

  @override
  String get showLoginNames => 'Показване на потребителските имена за вход';

  @override
  String get loginNamesShown =>
      'Потребителските имена за вход ще се показват, ако се различават от показваното име';

  @override
  String get loginNamesHidden =>
      'Потребителските имена за вход ще бъдат скрити';

  @override
  String get compactMessages => 'Компактни съобщения';

  @override
  String get dontCompactMessages => 'Без съкращаване на съобщенията';

  @override
  String get dontCompactMessagesSubtitle =>
      'Съобщенията се показват без промяна';

  @override
  String get compactIndividualMessages => 'Съкращаване на отделни съобщения';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Повтарящият се текст в съобщенията се съкращава';

  @override
  String get announcementPinDuration =>
      'Продължителност на закачване на известия';

  @override
  String get idleMessageAlertDuration =>
      'Продължителност на неактивност за звуково известие';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Ако няма съобщения през това време и пристигне ново, ще се възпроизведе звуков сигнал.';

  @override
  String get realtimeCashSubtitle => 'Свържете ETH или MATIC портфейл';

  @override
  String get walletAddress => 'Адрес на портфейла';

  @override
  String get streamlabsSubtitle => 'Вижте даренията си в Streamlabs';

  @override
  String get streamElementsSubtitle => 'Вижте даренията си в StreamElements';

  @override
  String get thirdPartyAuthError =>
      'Хм, това не проработи. Опитайте отново или попитайте в Discord?';

  @override
  String get companionAuthBrowserTooOld =>
      'Браузърът ви е твърде стар, за да поддържа директно влизане. Сканирайте този QR код с телефона си, за да влезете от друго устройство.';

  @override
  String get companionAuthScanQrCode =>
      'Сканирайте този QR код с телефона си, за да влезете от друго устройство.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> се абонира!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> поднови абонамента си за $monthsString месеца!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> подари $countString абонамента!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> изпрати $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Вход с Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Има твърде много съобщения. Преобразуването на текст в реч е изключено';

  @override
  String get turnOffTextToSpeech => 'Изключване';

  @override
  String get addToChat => 'Добавяне в чата';

  @override
  String get inChat => 'В чата';

  @override
  String get removeFromChat => 'Премахване от чата';

  @override
  String cantChatWithAccount(String provider) {
    return 'Вашият профил в $provider не може да пише тук';
  }

  @override
  String get cantChatWithAccounts => 'Вашите профили не могат да пишат тук';

  @override
  String sendAMessageTo(String channel) {
    return 'Изпратете съобщение до $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Замяна на $channel';
  }

  @override
  String get voicePacks => 'Гласови пакети';

  @override
  String get voicePacksDescription =>
      'Гласовите пакети четат чата с естествено звучащи гласове, които работят на вашето устройство офлайн след изтегляне. Гласовете са машинно генерирани от ИИ, а не записани от човек.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices гласа',
      one: '$voices глас',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count езика',
      one: '$count език',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Лицензът на този модел (OpenRAIL-M) забранява вредни употреби, като представяне за други хора или разпространяване на дезинформация, като тези ограничения важат и за вас.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Изтриване на $pack? Това ще освободи $size.';
  }

  @override
  String get voicePackDownload => 'Изтегляне';

  @override
  String get voicePackUpdate => 'Обновяване';

  @override
  String get voicePackWaitingForWifi => 'Изчакване на Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Използване на мобилни данни';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Изтегляне: $downloaded от $total';
  }

  @override
  String get voicePackInstalling => 'Инсталиране';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Неуспешно инсталиране на $pack. Проверете връзката си и опитайте отново.';
  }

  @override
  String get voices => 'Гласове';

  @override
  String get perViewerVoice => 'Индивидуален глас за всеки зрител';

  @override
  String get perViewerVoiceSubtitle =>
      'Всеки зрител получава свой собствен глас. Избраният от вас глас чете известията или всичко, когато тази опция е изключена.';

  @override
  String get streamLanguage => 'Език на потока';

  @override
  String get ttsEngineNeural => 'Невронен глас (на устройството)';

  @override
  String get ttsEngineSystem => 'Системен глас';

  @override
  String languageUnsupported(String language) {
    return '$language не се поддържа от вашите гласови пакети; ще се използва системният глас';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Това устройство няма достатъчно памет за невронни гласове, затова чатът се чете със системния глас.';

  @override
  String get neuralFallbackLoadFailed =>
      'Невронният глас не можа да се зареди, затова чатът се чете със системния глас.';

  @override
  String get accounts => 'Профили';

  @override
  String get accountsSubtitle =>
      'Влезте във всяка платформа, в която стриймвате';

  @override
  String addProviderAccount(String provider) {
    return 'Добавяне на профил в $provider';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Вход с $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Излизане от $channel в $provider?';
  }

  @override
  String get signOutOfAll => 'Излизане от всички профили';
}
