// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get sendAMessage => 'Отправить сообщение...';

  @override
  String get writeSomething => 'Напишите что-нибудь...';

  @override
  String get speakToTheCrowds => 'Обратитесь к толпе...';

  @override
  String get shareYourThoughts => 'Поделитесь своими мыслями...';

  @override
  String get saySomethingYouLittleBitch =>
      'Скажи что-нибудь, маленький ублюдок...';

  @override
  String get search => 'Поиск';

  @override
  String get notSignedIn => 'Не вошли в систему';

  @override
  String get searchChannels => 'Поиск каналов';

  @override
  String get raidAChannel => 'Рейд на канал';

  @override
  String get noMessagesEmptyState => 'Нет сообщений';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count новых сообщений',
      one: '1 новое сообщение',
      zero: 'Нет новых сообщений',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Войти через Twitch';

  @override
  String get signInError =>
      'Произошла ошибка при входе. Пожалуйста, попробуйте еще раз.';

  @override
  String get continueAsGuest => 'Продолжить как гость';

  @override
  String get signInToSendMessages => 'Войдите, чтобы отправлять сообщения';

  @override
  String get currentViewers => 'Текущие зрители';

  @override
  String get textToSpeech => 'Текст в речь';

  @override
  String get streamPreview => 'Предварительный просмотр потока';

  @override
  String get activityFeed => 'Лента активности';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Поток онлайн с $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Поток оффлайн с $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Чат очищен в $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Настроить быстрые ссылки';

  @override
  String get disableRainMode => 'Отключить режим дождя';

  @override
  String get enableRainMode => 'Включить режим дождя';

  @override
  String get disableRainModeSubtitle => 'Взаимодействие будет включено';

  @override
  String get enableRainModeSubtitle => 'Взаимодействие будет отключено';

  @override
  String get refreshAudioSources => 'Обновить аудиоисточники';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аудиоисточников обновлено',
      one: '1 аудиоисточник обновлен',
      zero: 'Нет обновленных аудиоисточников',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Настройки';

  @override
  String get signOut => 'Выйти';

  @override
  String get cancel => 'Отмена';

  @override
  String get signOutConfirmation => 'Вы уверены, что хотите выйти?';

  @override
  String get broadcaster => 'Ведущий';

  @override
  String get moderators => 'Модераторы';

  @override
  String get viewers => 'Зрители';

  @override
  String get communityVips => 'VIP-сообщества';

  @override
  String get searchViewers => 'Поиск зрителей';

  @override
  String get reconnecting => 'Переподключение...';

  @override
  String get twitchBadges => 'Значки Twitch';

  @override
  String get selectAll => 'Выбрать все';

  @override
  String get quickLinks => 'Быстрые ссылки';

  @override
  String get swipeToDeleteQuickLinks =>
      'Проведите влево или вправо, чтобы удалить быструю ссылку';

  @override
  String get quickLinksLabelHint => 'Метка';

  @override
  String get invalidUrlErrorText => 'Это не похоже на действительный URL';

  @override
  String get duplicateUrlErrorText => 'Эта ссылка уже существует';

  @override
  String get or => 'или';

  @override
  String get clearCookies => 'Очистить куки';

  @override
  String get disabled => 'Отключено';

  @override
  String get twitchActivityFeed => 'Лента активности Twitch';

  @override
  String get signInToEnable => 'Вы должны войти в систему, чтобы включить это';

  @override
  String get customUrl => 'Пользовательский URL';

  @override
  String get preview => 'Предварительный просмотр';

  @override
  String get audioSources => 'Аудиоисточники';

  @override
  String get enableOffStreamSwitchTitle =>
      'Включить вне потока (использует больше батареи)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Аудио будет воспроизводиться, даже когда вы оффлайн';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Аудио будет воспроизводиться только когда вы в эфире';

  @override
  String get iosOggWarningTitle => 'Эй! Слушай!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS не поддерживает медиафайлы *.ogg, которые являются файлами по умолчанию в Streamlabs. Убедитесь, что ваши аудиоисточники используют другой формат, иначе они не будут воспроизводиться.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Настройте свою ленту активности';

  @override
  String get audioSourcesSubtitle =>
      'Добавьте веб-источники для звуковых оповещений';

  @override
  String get quickLinksSubtitle =>
      'Добавьте ярлыки для часто используемых инструментов';

  @override
  String get chatHistory => 'История чата';

  @override
  String get chatHistorySubtitle => 'Измените внешний вид чата';

  @override
  String get textToSpeechSubtitle => 'Измените настройки текста в речь';

  @override
  String get events => 'События';

  @override
  String get eventsSubtitle => 'Настройте события Twitch';

  @override
  String get thirdPartyServices => 'Сторонние сервисы';

  @override
  String get thirdPartyServicesSubtitle => 'Подключитесь к стороннему сервису';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> подписался на вас';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> и <b>$displayNameTwo</b> подписались на вас';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b> и еще $numOthersString подписались на вас';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Включить звук для $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Отключить звук для $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Временное отключение для $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Заблокировать $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Разблокировать $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Просмотреть профиль $displayName';
  }

  @override
  String get copyMessage => 'Копировать сообщение';

  @override
  String get deleteMessage => 'Удалить сообщение';

  @override
  String get longScrollNotification =>
      'Вы прокручиваете довольно далеко, не так ли?';

  @override
  String get stfu => 'заткнись';

  @override
  String get globalEmotes => 'Глобальные эмоции';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString подписчиков',
      one: '1 подписчик',
      zero: '0 подписчиков',
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
      other: '$countString зрителей',
      one: '1 зритель',
      zero: '0 зрителей',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Привет! Мы рады, что вам нравится использовать предварительный просмотр потока, но имейте в виду, что он использует много батареи. Чтение чата без него продлит время работы батареи.';

  @override
  String get okay => 'ОК';

  @override
  String get streamPreviewLoading => 'Загрузка (или поток оффлайн)...';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get audioSourcesRequirePermissions =>
      'Аудиоисточники требуют разрешений';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Разрешите RealtimeChat рисовать поверх других приложений, чтобы использовать аудиоисточники.';

  @override
  String get audioSourcesRemoveButton => 'Удалить аудиоисточники';

  @override
  String get audioSourcesOpenSettingsButton => 'Открыть настройки';

  @override
  String get flashOn => 'Включить вспышку';

  @override
  String get flashOff => 'Выключить вспышку';

  @override
  String get durationOneSecond => '1 секунда';

  @override
  String get durationOneMinute => '1 минута';

  @override
  String get durationTenMinutes => '10 минут';

  @override
  String get durationOneHour => '1 час';

  @override
  String get durationSixHours => '6 часов';

  @override
  String get durationOneDay => '1 день';

  @override
  String get durationTwoDays => '2 дня';

  @override
  String get durationOneWeek => '1 неделя';

  @override
  String get durationTwoWeeks => '2 недели';

  @override
  String get durationOneSecondTimeoutPrompt =>
      'Временное отключение на 1 секунду';

  @override
  String get durationOneMinuteTimeoutPrompt =>
      'Временное отключение на 1 минуту';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      'Временное отключение на 10 минут';

  @override
  String get durationOneHourTimeoutPrompt => 'Временное отключение на 1 час';

  @override
  String get durationSixHoursTimeoutPrompt => 'Временное отключение на 6 часов';

  @override
  String get durationOneDayTimeoutPrompt => 'Временное отключение на 1 день';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Временное отключение на 2 дня';

  @override
  String get durationOneWeekTimeoutPrompt => 'Временное отключение на 1 неделю';

  @override
  String get durationTwoWeeksTimeoutPrompt =>
      'Временное отключение на 2 недели';

  @override
  String get errorFetchingViewerList =>
      'Не удалось получить список зрителей для этого канала';

  @override
  String get eventsTitle => 'События';

  @override
  String get followEventConfigTitle => 'Событие подписки';

  @override
  String get customizeYourFollowEvent => 'Настройте свое событие подписки';

  @override
  String get subscribeEventConfigTitle => 'Событие подписки';

  @override
  String get customizeYourSubscriptionEvent =>
      'Настройте свое событие подписки';

  @override
  String get cheerEventConfigTitle => 'Событие поддержки';

  @override
  String get customizeYourCheerEvent => 'Настройте свое событие поддержки';

  @override
  String get raidEventConfigTitle => 'Событие рейда';

  @override
  String get customizeYourRaidEvent => 'Настройте свое событие рейда';

  @override
  String get hostEventConfigTitle => 'Событие хостинга';

  @override
  String get customizeYourHostEvent => 'Настройте свое событие хостинга';

  @override
  String get hypetrainEventConfigTitle => 'Событие hypetrain';

  @override
  String get customizeYourHypetrainEvent => 'Настройте свое событие hypetrain';

  @override
  String get pollEventConfigTitle => 'Событие опроса';

  @override
  String get customizeYourPollEvent => 'Настройте свое событие опроса';

  @override
  String get predictionEventConfigTitle => 'Событие предсказания';

  @override
  String get customizeYourPredictionEvent =>
      'Настройте свое событие предсказания';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Событие обмена баллов канала';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Настройте свое событие обмена баллов канала';

  @override
  String get outgoingRaidEventConfigTitle => 'Событие исходящего рейда';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Настройте свое событие исходящего рейда';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b> проводит рейд с <b>$viewerCountString</b> зрителями!';
  }

  @override
  String get shoutout => 'Шаут-аут';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Рейд на <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Осталось $secondsString секунд';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> провел рейд!';
  }

  @override
  String get raidingEventJoin => 'Присоединиться';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Рейд <b>$displayName</b> был отменен.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> подписался на уровень $tier!';
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

    return '<b>$gifterUserName</b> подарил $totalString подписок уровня $tier, всего $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> подписался на уровень $tier на $cumulativeMonthsString месяцев!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> дал чаевые в размере <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Аноним дал чаевые в размере <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> дал чаевые в размере <b>$formattedAmount</b> на StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> дал чаевые в размере <b>$formattedAmount</b> на Streamlabs.';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> обменял <b>$rewardName</b> за <b>$rewardCostString</b> баллов. $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> обменял <b>$rewardName</b> за <b>$rewardCostString</b> баллов.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> поддержал <b>$bitsString</b> битами. $cheerMessage';
  }

  @override
  String get anonymous => 'Аноним';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> хостит с группой из <b>$viewersString</b> зрителей.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hypetrain на уровне <b>$level</b> в процессе! Завершено на <b>$progressPercent%</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hypetrain на уровне <b>$levelString</b> завершен успешно.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hypetrain на уровне <b>$levelString</b> завершен неудачно.';
  }

  @override
  String get sampleMessage =>
      'Это пример сообщения для преобразования текста в речь.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author сказал: $text';
  }

  @override
  String get textToSpeechEnabled => 'Преобразование текста в речь включено';

  @override
  String get textToSpeechDisabled => 'Преобразование текста в речь отключено';

  @override
  String get alertsEnabled => 'Alerts only';

  @override
  String get sidebarActions => 'Sidebar Actions';
}
