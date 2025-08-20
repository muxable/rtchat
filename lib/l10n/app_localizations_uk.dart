// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get sendAMessage => 'Надіслати повідомлення...';

  @override
  String get writeSomething => 'Напишіть щось...';

  @override
  String get speakToTheCrowds => 'Говоріть до натовпу...';

  @override
  String get shareYourThoughts => 'Поділіться своїми думками...';

  @override
  String get saySomethingYouLittleBitch =>
      'Скажи щось, маленький сучий сину...';

  @override
  String get search => 'Пошук';

  @override
  String get notSignedIn => 'Не увійшли в систему';

  @override
  String get searchChannels => 'Пошук каналів';

  @override
  String get raidAChannel => 'Рейд на канал';

  @override
  String get noMessagesEmptyState => 'Немає повідомлень';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count нових повідомлень',
      one: '1 нове повідомлення',
      zero: 'Немає нових повідомлень',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Увійти через Twitch';

  @override
  String get signInError =>
      'Сталася помилка під час входу. Будь ласка, спробуйте ще раз.';

  @override
  String get continueAsGuest => 'Продовжити як гість';

  @override
  String get signInToSendMessages => 'Увійдіть, щоб надсилати повідомлення';

  @override
  String get currentViewers => 'Поточні глядачі';

  @override
  String get textToSpeech => 'Текст у мову';

  @override
  String get streamPreview => 'Попередній перегляд потоку';

  @override
  String get activityFeed => 'Стрічка активності';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Потік онлайн з $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Потік офлайн з $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Чат очищено о $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Налаштувати швидкі посилання';

  @override
  String get disableRainMode => 'Вимкнути режим дощу';

  @override
  String get enableRainMode => 'Увімкнути режим дощу';

  @override
  String get disableRainModeSubtitle => 'Взаємодія буде увімкнена';

  @override
  String get enableRainModeSubtitle => 'Взаємодія буде вимкнена';

  @override
  String get refreshAudioSources => 'Оновити аудіоджерела';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аудіоджерел оновлено',
      one: '1 аудіоджерело оновлено',
      zero: 'Немає оновлених аудіоджерел',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Налаштування';

  @override
  String get signOut => 'Вийти';

  @override
  String get cancel => 'Скасувати';

  @override
  String get signOutConfirmation => 'Ви впевнені, що хочете вийти?';

  @override
  String get broadcaster => 'Ведучий';

  @override
  String get moderators => 'Модератори';

  @override
  String get viewers => 'Глядачі';

  @override
  String get communityVips => 'VIP-спільноти';

  @override
  String get searchViewers => 'Пошук глядачів';

  @override
  String get reconnecting => 'Перепідключення...';

  @override
  String get twitchBadges => 'Значки Twitch';

  @override
  String get selectAll => 'Вибрати все';

  @override
  String get quickLinks => 'Швидкі посилання';

  @override
  String get swipeToDeleteQuickLinks =>
      'Проведіть вліво або вправо, щоб видалити швидке посилання';

  @override
  String get quickLinksLabelHint => 'Мітка';

  @override
  String get invalidUrlErrorText => 'Це не схоже на дійсний URL';

  @override
  String get duplicateUrlErrorText => 'Це посилання вже існує';

  @override
  String get or => 'або';

  @override
  String get clearCookies => 'Очистити куки';

  @override
  String get disabled => 'Вимкнено';

  @override
  String get twitchActivityFeed => 'Стрічка активності Twitch';

  @override
  String get signInToEnable => 'Ви повинні увійти в систему, щоб увімкнути це';

  @override
  String get customUrl => 'Користувацький URL';

  @override
  String get preview => 'Попередній перегляд';

  @override
  String get audioSources => 'Аудіоджерела';

  @override
  String get enableOffStreamSwitchTitle =>
      'Увімкнути поза потоком (використовує більше батареї)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Аудіо буде відтворюватися, навіть коли ви офлайн';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Аудіо буде відтворюватися тільки коли ви в ефірі';

  @override
  String get iosOggWarningTitle => 'Гей! Слухай!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS не підтримує медіафайли *.ogg, які є файлами за замовчуванням у Streamlabs. Переконайтеся, що ваші аудіоджерела використовують інший формат, інакше вони не будуть відтворюватися.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Налаштуйте свою стрічку активності';

  @override
  String get audioSourcesSubtitle =>
      'Додайте веб-джерела для звукових сповіщень';

  @override
  String get quickLinksSubtitle =>
      'Додайте ярлики для часто використовуваних інструментів';

  @override
  String get chatHistory => 'Історія чату';

  @override
  String get chatHistorySubtitle => 'Змініть зовнішній вигляд чату';

  @override
  String get textToSpeechSubtitle => 'Змініть налаштування тексту в мову';

  @override
  String get events => 'Події';

  @override
  String get eventsSubtitle => 'Налаштуйте події Twitch';

  @override
  String get thirdPartyServices => 'Сторонні сервіси';

  @override
  String get thirdPartyServicesSubtitle =>
      'Підключіться до стороннього сервісу';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> підписався на вас';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> і <b>$displayNameTwo</b> підписалися на вас';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b> і ще $numOthersString підписалися на вас';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Увімкнути звук для $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Вимкнути звук для $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Тимчасове вимкнення для $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Заблокувати $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Розблокувати $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Переглянути профіль $displayName';
  }

  @override
  String get copyMessage => 'Копіювати повідомлення';

  @override
  String get deleteMessage => 'Видалити повідомлення';

  @override
  String get longScrollNotification =>
      'Ви прокручуєте досить далеко, чи не так?';

  @override
  String get stfu => 'заткнись';

  @override
  String get globalEmotes => 'Глобальні емоції';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString підписників',
      one: '1 підписник',
      zero: '0 підписників',
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
      other: '$countString глядачів',
      one: '1 глядач',
      zero: '0 глядачів',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Привіт! Ми раді, що вам подобається використовувати попередній перегляд потоку, але майте на увазі, що він використовує багато батареї. Читання чату без нього продовжить час роботи батареї.';

  @override
  String get okay => 'ОК';

  @override
  String get streamPreviewLoading => 'Завантаження (або потік офлайн)...';

  @override
  String get copiedToClipboard => 'Скопійовано в буфер обміну';

  @override
  String get audioSourcesRequirePermissions =>
      'Аудіоджерела вимагають дозволів';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Дозвольте RealtimeChat малювати поверх інших додатків, щоб використовувати аудіоджерела.';

  @override
  String get audioSourcesRemoveButton => 'Видалити аудіоджерела';

  @override
  String get audioSourcesOpenSettingsButton => 'Відкрити налаштування';

  @override
  String get flashOn => 'Увімкнути спалах';

  @override
  String get flashOff => 'Вимкнути спалах';

  @override
  String get durationOneSecond => '1 секунда';

  @override
  String get durationOneMinute => '1 хвилина';

  @override
  String get durationTenMinutes => '10 хвилин';

  @override
  String get durationOneHour => '1 година';

  @override
  String get durationSixHours => '6 годин';

  @override
  String get durationOneDay => '1 день';

  @override
  String get durationTwoDays => '2 дні';

  @override
  String get durationOneWeek => '1 тиждень';

  @override
  String get durationTwoWeeks => '2 тижні';

  @override
  String get durationOneSecondTimeoutPrompt =>
      'Тимчасове вимкнення на 1 секунду';

  @override
  String get durationOneMinuteTimeoutPrompt =>
      'Тимчасове вимкнення на 1 хвилину';

  @override
  String get durationTenMinutesTimeoutPrompt =>
      'Тимчасове вимкнення на 10 хвилин';

  @override
  String get durationOneHourTimeoutPrompt => 'Тимчасове вимкнення на 1 годину';

  @override
  String get durationSixHoursTimeoutPrompt => 'Тимчасове вимкнення на 6 годин';

  @override
  String get durationOneDayTimeoutPrompt => 'Тимчасове вимкнення на 1 день';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Тимчасове вимкнення на 2 дні';

  @override
  String get durationOneWeekTimeoutPrompt => 'Тимчасове вимкнення на 1 тиждень';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Тимчасове вимкнення на 2 тижні';

  @override
  String get errorFetchingViewerList =>
      'Не вдалося отримати список глядачів для цього каналу';

  @override
  String get eventsTitle => 'Події';

  @override
  String get followEventConfigTitle => 'Подія підписки';

  @override
  String get customizeYourFollowEvent => 'Налаштуйте свою подію підписки';

  @override
  String get subscribeEventConfigTitle => 'Подія підписки';

  @override
  String get customizeYourSubscriptionEvent => 'Налаштуйте свою подію підписки';

  @override
  String get cheerEventConfigTitle => 'Подія підтримки';

  @override
  String get customizeYourCheerEvent => 'Налаштуйте свою подію підтримки';

  @override
  String get raidEventConfigTitle => 'Подія рейду';

  @override
  String get customizeYourRaidEvent => 'Налаштуйте свою подію рейду';

  @override
  String get hostEventConfigTitle => 'Подія хостингу';

  @override
  String get customizeYourHostEvent => 'Налаштуйте свою подію хостингу';

  @override
  String get hypetrainEventConfigTitle => 'Подія hypetrain';

  @override
  String get customizeYourHypetrainEvent => 'Налаштуйте свою подію hypetrain';

  @override
  String get pollEventConfigTitle => 'Подія опитування';

  @override
  String get customizeYourPollEvent => 'Налаштуйте свою подію опитування';

  @override
  String get predictionEventConfigTitle => 'Подія передбачення';

  @override
  String get customizeYourPredictionEvent =>
      'Налаштуйте свою подію передбачення';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'Подія обміну балів каналу';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Налаштуйте свою подію обміну балів каналу';

  @override
  String get outgoingRaidEventConfigTitle => 'Подія вихідного рейду';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Налаштуйте свою подію вихідного рейду';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b> проводить рейд з <b>$viewerCountString</b> глядачами!';
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

    return 'Залишилося $secondsString секунд';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> провів рейд!';
  }

  @override
  String get raidingEventJoin => 'Приєднатися';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Рейд <b>$displayName</b> було скасовано.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> підписався на рівень $tier!';
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

    return '<b>$gifterUserName</b> подарував $totalString підписок рівня $tier, всього $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> підписався на рівень $tier на $cumulativeMonthsString місяців!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> дав чайові в розмірі <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Анонім дав чайові в розмірі <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> дав чайові в розмірі <b>$formattedAmount</b> на StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> дав чайові в розмірі <b>$formattedAmount</b> на Streamlabs.';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> обміняв <b>$rewardName</b> за <b>$rewardCostString</b> балів. $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> обміняв <b>$rewardName</b> за <b>$rewardCostString</b> балів.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> підтримав <b>$bitsString</b> бітами. $cheerMessage';
  }

  @override
  String get anonymous => 'Анонім';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> хостить з групою з <b>$viewersString</b> глядачів.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hypetrain на рівні <b>$level</b> в процесі! Завершено на <b>$progressPercent%</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hypetrain на рівні <b>$levelString</b> завершено успішно.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hypetrain на рівні <b>$levelString</b> завершено невдало.';
  }

  @override
  String get sampleMessage =>
      'Це зразок повідомлення для перетворення тексту в мову.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author сказав: $text';
  }

  @override
  String get textToSpeechEnabled => 'Синтез мовлення ввімкнено';

  @override
  String get textToSpeechDisabled => 'Синтез мовлення вимкнено';

  @override
  String get alertsEnabled => 'Alerts only';

  @override
  String get sidebarActions => 'Sidebar Actions';
}
