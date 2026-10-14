// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get sendAMessage => 'أرسل رسالة...';

  @override
  String get writeSomething => 'اكتب شيئًا...';

  @override
  String get speakToTheCrowds => 'تحدث إلى الجماهير...';

  @override
  String get shareYourThoughts => 'شارك أفكارك...';

  @override
  String get saySomethingYouLittleBitch => 'قل شيئًا، أيها الوغد الصغير...';

  @override
  String get search => 'بحث';

  @override
  String get notSignedIn => 'لم يتم تسجيل الدخول';

  @override
  String get searchChannels => 'ابحث عن القنوات';

  @override
  String get raidAChannel => 'اقتحم قناة';

  @override
  String get noMessagesEmptyState => 'لا توجد رسائل';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رسائل جديدة',
      one: 'رسالة جديدة واحدة',
      zero: 'لا توجد رسائل جديدة',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'تسجيل الدخول باستخدام تويتش';

  @override
  String get signInError =>
      'حدث خطأ أثناء تسجيل الدخول. يرجى المحاولة مرة أخرى.';

  @override
  String get continueAsGuest => 'متابعة كضيف';

  @override
  String get signInToSendMessages => 'تسجيل الدخول لإرسال الرسائل';

  @override
  String get currentViewers => 'المشاهدون الحاليون';

  @override
  String get textToSpeech => 'تحويل النص إلى كلام';

  @override
  String get streamPreview => 'معاينة البث';

  @override
  String get activityFeed => 'تغذية النشاط';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'البث متصل في $dateString، $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'البث غير متصل في $dateString، $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'تم مسح الدردشة في $dateString، $timeString';
  }

  @override
  String get configureQuickLinks => 'تكوين الروابط السريعة';

  @override
  String get disableRainMode => 'تعطيل وضع المطر';

  @override
  String get enableRainMode => 'تمكين وضع المطر';

  @override
  String get disableRainModeSubtitle => 'سيتم تمكين التفاعل';

  @override
  String get enableRainModeSubtitle => 'سيتم تعطيل التفاعل';

  @override
  String get refreshAudioSources => 'تحديث مصادر الصوت';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مصادر صوت محدثة',
      one: 'تم تحديث مصدر صوت واحد',
      zero: 'لم يتم تحديث مصادر الصوت',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'الإعدادات';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get cancel => 'إلغاء';

  @override
  String get signOutConfirmation => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get broadcaster => 'المذيع';

  @override
  String get moderators => 'المشرفون';

  @override
  String get viewers => 'المشاهدون';

  @override
  String get communityVips => 'كبار الشخصيات في المجتمع';

  @override
  String get searchViewers => 'ابحث عن المشاهدين';

  @override
  String get reconnecting => 'إعادة الاتصال...';

  @override
  String get twitchBadges => 'شارات تويتش';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get quickLinks => 'روابط سريعة';

  @override
  String get swipeToDeleteQuickLinks =>
      'اسحب لليسار أو اليمين لحذف الرابط السريع';

  @override
  String get quickLinksLabelHint => 'التسمية';

  @override
  String get invalidUrlErrorText => 'هذا لا يبدو كعنوان URL صالح';

  @override
  String get duplicateUrlErrorText => 'هذا الرابط موجود بالفعل';

  @override
  String get or => 'أو';

  @override
  String get clearCookies => 'مسح ملفات تعريف الارتباط';

  @override
  String get disabled => 'معطل';

  @override
  String get twitchActivityFeed => 'تغذية نشاط تويتش';

  @override
  String get signInToEnable => 'يجب أن تكون مسجلاً للدخول لتمكين هذا';

  @override
  String get customUrl => 'عنوان URL مخصص';

  @override
  String get preview => 'معاينة';

  @override
  String get audioSources => 'مصادر الصوت';

  @override
  String get enableOffStreamSwitchTitle =>
      'تمكين خارج البث (يستهلك المزيد من البطارية)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'سيتم تشغيل الصوت أيضًا عندما تكون غير متصل';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'سيتم تشغيل الصوت فقط عندما تكون متصلاً';

  @override
  String get iosOggWarningTitle => 'مرحبًا! استمع!';

  @override
  String get iosOggWarningSubtitle =>
      'نظام iOS لا يدعم ملفات الوسائط *.ogg، وهي الملفات الافتراضية في Streamlabs. تأكد من أن مصادر الصوت الخاصة بك تستخدم تنسيقًا آخر، وإلا فلن يتم تشغيلها.';

  @override
  String get url => 'عنوان URL';

  @override
  String get activityFeedSubtitle => 'تخصيص تغذية النشاط الخاصة بك';

  @override
  String get audioSourcesSubtitle => 'إضافة مصادر الويب لأصوات التنبيهات';

  @override
  String get quickLinksSubtitle => 'إضافة اختصارات للأدوات المستخدمة بشكل شائع';

  @override
  String get chatHistory => 'سجل الدردشة';

  @override
  String get chatHistorySubtitle => 'تغيير مظهر الدردشة';

  @override
  String get textToSpeechSubtitle => 'تغيير إعدادات تحويل النص إلى كلام';

  @override
  String get events => 'الأحداث';

  @override
  String get eventsSubtitle => 'تكوين أحداث تويتش';

  @override
  String get thirdPartyServices => 'خدمات الطرف الثالث';

  @override
  String get thirdPartyServicesSubtitle => 'الاتصال بخدمة طرف ثالث';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> يتابعك';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> و <b>$displayNameTwo</b> يتابعانك';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>، <b>$displayNameTwo</b>، و $numOthersString آخرين يتابعونك';
  }

  @override
  String unmuteUser(String displayName) {
    return 'إلغاء كتم $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'كتم $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'إيقاف مؤقت لـ $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'حظر $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'إلغاء حظر $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'عرض ملف $displayName الشخصي';
  }

  @override
  String get copyMessage => 'نسخ الرسالة';

  @override
  String get deleteMessage => 'حذف الرسالة';

  @override
  String get longScrollNotification =>
      'أنت تقوم بالتمرير بعيدًا، ألا تعتقد ذلك؟';

  @override
  String get stfu => 'اصمت';

  @override
  String get globalEmotes => 'الرموز التعبيرية العالمية';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString متابعين',
      one: '1 متابع',
      zero: '0 متابع',
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
      other: '$countString مشاهدين',
      one: '1 مشاهد',
      zero: '0 مشاهد',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'مرحبًا! نحن سعداء لأنك تحب استخدام معاينة البث، ولكن انتبه لأنها تستهلك الكثير من البطارية. قراءة الدردشة بدونها ستمدد عمر البطارية.';

  @override
  String get okay => 'حسنًا';

  @override
  String get streamPreviewLoading => 'جارٍ التحميل (أو البث غير متصل)...';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get audioSourcesRequirePermissions => 'مصادر الصوت تتطلب أذونات';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'وافق على أن يقوم RealtimeChat بالرسم فوق التطبيقات الأخرى لاستخدام مصادر الصوت.';

  @override
  String get audioSourcesRemoveButton => 'إزالة مصادر الصوت';

  @override
  String get audioSourcesOpenSettingsButton => 'فتح الإعدادات';

  @override
  String get flashOn => 'تشغيل الفلاش';

  @override
  String get flashOff => 'إيقاف الفلاش';

  @override
  String get durationOneSecond => '1 ثانية';

  @override
  String get durationOneMinute => '1 دقيقة';

  @override
  String get durationTenMinutes => '10 دقائق';

  @override
  String get durationOneHour => '1 ساعة';

  @override
  String get durationSixHours => '6 ساعات';

  @override
  String get durationOneDay => '1 يوم';

  @override
  String get durationTwoDays => '2 يومين';

  @override
  String get durationOneWeek => '1 أسبوع';

  @override
  String get durationTwoWeeks => '2 أسبوعين';

  @override
  String get durationOneSecondTimeoutPrompt => 'إيقاف مؤقت لمدة 1 ثانية';

  @override
  String get durationOneMinuteTimeoutPrompt => 'إيقاف مؤقت لمدة 1 دقيقة';

  @override
  String get durationTenMinutesTimeoutPrompt => 'إيقاف مؤقت لمدة 10 دقائق';

  @override
  String get durationOneHourTimeoutPrompt => 'إيقاف مؤقت لمدة 1 ساعة';

  @override
  String get durationSixHoursTimeoutPrompt => 'إيقاف مؤقت لمدة 6 ساعات';

  @override
  String get durationOneDayTimeoutPrompt => 'إيقاف مؤقت لمدة 1 يوم';

  @override
  String get durationTwoDaysTimeoutPrompt => 'إيقاف مؤقت لمدة 2 يومين';

  @override
  String get durationOneWeekTimeoutPrompt => 'إيقاف مؤقت لمدة 1 أسبوع';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'إيقاف مؤقت لمدة 2 أسبوعين';

  @override
  String get errorFetchingViewerList =>
      'لم نتمكن من جلب قائمة المشاهدين لهذه القناة';

  @override
  String get eventsTitle => 'الأحداث';

  @override
  String get followEventConfigTitle => 'حدث المتابعة';

  @override
  String get customizeYourFollowEvent => 'تخصيص حدث المتابعة الخاص بك';

  @override
  String get subscribeEventConfigTitle => 'حدث الاشتراك';

  @override
  String get customizeYourSubscriptionEvent => 'تخصيص حدث الاشتراك الخاص بك';

  @override
  String get cheerEventConfigTitle => 'حدث التشجيع';

  @override
  String get customizeYourCheerEvent => 'تخصيص حدث التشجيع الخاص بك';

  @override
  String get raidEventConfigTitle => 'حدث الغارة';

  @override
  String get customizeYourRaidEvent => 'تخصيص حدث الغارة الخاص بك';

  @override
  String get hostEventConfigTitle => 'حدث الاستضافة';

  @override
  String get customizeYourHostEvent => 'تخصيص حدث الاستضافة الخاص بك';

  @override
  String get hypetrainEventConfigTitle => 'حدث قطار الحماس';

  @override
  String get customizeYourHypetrainEvent => 'تخصيص حدث قطار الحماس الخاص بك';

  @override
  String get pollEventConfigTitle => 'حدث الاستطلاع';

  @override
  String get customizeYourPollEvent => 'تخصيص حدث الاستطلاع الخاص بك';

  @override
  String get predictionEventConfigTitle => 'حدث التنبؤ';

  @override
  String get customizeYourPredictionEvent => 'تخصيص حدث التنبؤ الخاص بك';

  @override
  String get channelPointRedemptionEventConfigTitle =>
      'حدث استرداد نقاط القناة';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'تخصيص حدث استرداد نقاط القناة الخاص بك';

  @override
  String get outgoingRaidEventConfigTitle => 'حدث الغارة الصادرة';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'تخصيص حدث الغارة الصادرة الخاص بك';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b> يقوم بغارة مع <b>$viewerCountString</b> مشاهدين!';
  }

  @override
  String get shoutout => 'شكرًا';

  @override
  String raidingEventRaiding(String displayName) {
    return 'غارة على <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'متبقي $secondsString ثواني';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> قام بغارة!';
  }

  @override
  String get raidingEventJoin => 'انضم';

  @override
  String raidingEventCanceled(String displayName) {
    return 'تم إلغاء غارة <b>$displayName</b>.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> اشترك في المستوى $tier!';
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

    return '<b>$gifterUserName</b> قدم $totalString اشتراكات في المستوى $tier، بإجمالي $cumulativeTotalString!';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> اشترك لمدة $cumulativeMonthsString أشهر في المستوى $tier!';
  }

  @override
  String subscriptionMessageMultiMonthEvent(String subscriberUserName,
      String tier, int durationMonths, int cumulativeMonths) {
    final intl.NumberFormat durationMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String durationMonthsString =
        durationMonthsNumberFormat.format(durationMonths);
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return 'اشترك <b>$subscriberUserName</b> في المستوى $tier لمدة $durationMonthsString شهر مقدمًا، $cumulativeMonthsString شهر إجمالًا!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> موهوب <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'أعطى غير معروف <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> قدم بقشيش بمبلغ <b>$formattedAmount</b> على StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> قدم بقشيش بمبلغ <b>$formattedAmount</b> على Streamlabs.';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> استرد <b>$rewardName</b> مقابل <b>$rewardCostString</b> نقاط. $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> استرد <b>$rewardName</b> مقابل <b>$rewardCostString</b> نقاط.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> شجع <b>$bitsString</b> بت. $cheerMessage';
  }

  @override
  String get anonymous => 'مجهول';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> يستضيف مع مجموعة من <b>$viewersString</b>.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'قطار الحماس في المستوى <b>$level</b> قيد التقدم! تم إكمال <b>$progressPercent%</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'تم نجاح قطار الحماس في المستوى <b>$levelString</b>.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'فشل قطار الحماس في المستوى <b>$levelString</b>.';
  }

  @override
  String get sampleMessage => 'هذه رسالة نموذجية لتحويل النص إلى كلام.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author قال: $text';
  }

  @override
  String get textToSpeechEnabled => ' تم تمكين تحويل النص إلى كلام';

  @override
  String get textToSpeechDisabled => '  تم تعطيل تحويل النص إلى كلام';

  @override
  String get alertsEnabled => 'التنبيهات فقط';

  @override
  String get pinDuration => 'مدة التثبيت';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds ثانية',
      many: '$seconds ثانية',
      few: '$seconds ثوانٍ',
      two: 'ثانيتان',
      one: 'ثانية واحدة',
      zero: '0 ثانية',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: '0 دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'تفعيل الحدث';

  @override
  String get showEventInChatHistory => 'عرض الحدث في سجل الدردشة';

  @override
  String get enableShoutouts => 'تفعيل الإشادات';

  @override
  String get enableShoutoutsSubtitle =>
      'إرسال رابط القناة المُغيرة إلى الدردشة';

  @override
  String get raidConfigurationTitle => 'إعدادات الغارات';

  @override
  String get cheerConfigurationTitle => 'إعدادات التشجيع';

  @override
  String get followConfigurationTitle => 'إعدادات المتابعة';

  @override
  String get outgoingRaidConfigurationTitle => 'إعدادات الغارات الصادرة';

  @override
  String get hostConfigurationTitle => 'إعدادات الاستضافة';

  @override
  String get channelPointConfigurationTitle => 'إعدادات نقاط القناة';

  @override
  String get pollConfigurationTitle => 'إعدادات الاستطلاعات';

  @override
  String get hypetrainConfigurationTitle => 'إعدادات قطار الحماس';

  @override
  String get subscriptionConfigurationTitle => 'إعدادات الاشتراكات';

  @override
  String get predictionConfigurationTitle => 'إعدادات التوقعات';

  @override
  String get unfulfilledRewardsPinDuration =>
      'مدة تثبيت إضافية للمكافآت غير المنفذة';

  @override
  String get pollPinDuration => 'مدة التثبيت بعد إعلان النتيجة النهائية';

  @override
  String get hypetrainPinDuration => 'مدة التثبيت بعد انتهاء قطار الحماس';

  @override
  String get enableGiftedSubscriptions => 'تفعيل الاشتراكات المُهداة الفردية';

  @override
  String get enableGiftedSubscriptionsSubtitle => 'عرض كل اشتراك مُهدى';

  @override
  String get settingsBackupTitle => 'نسخ الإعدادات احتياطيًا واستعادتها';

  @override
  String get cloudBackup => 'النسخ الاحتياطي السحابي';

  @override
  String get lastBackupNever => 'آخر نسخة احتياطية: أبدًا';

  @override
  String get backUp => 'نسخ احتياطي';

  @override
  String get restore => 'استعادة';

  @override
  String get localBackup => 'النسخ الاحتياطي المحلي';

  @override
  String get exportSettings => 'تصدير';

  @override
  String get importSettings => 'استيراد';

  @override
  String get showViewerAndFollowerCount => 'عرض عدد المشاهدين والمتابعين';

  @override
  String get screenOrientation => 'اتجاه الشاشة';

  @override
  String get appTheme => 'مظهر التطبيق';

  @override
  String get systemDefault => 'النظام';

  @override
  String get portrait => 'عمودي';

  @override
  String get landscape => 'أفقي';

  @override
  String get lightTheme => 'فاتح';

  @override
  String get darkTheme => 'داكن';

  @override
  String get openSourceTitle => 'RealtimeChat مفتوح المصدر';

  @override
  String get openSourceSubtitle => 'تجدنا على GitHub!';

  @override
  String get discordSubtitle => 'انضم إلى Discord الخاص بـ Muxable!';

  @override
  String get earlyTestersThanks =>
      'شكرًا لجميع المختبرين الأوائل الذين أرسلوا تقارير الأخطاء!';

  @override
  String get discoModeEnabled => '🕺 تم تفعيل وضع الديسكو! :D';

  @override
  String get discoModeDisabled => '🕺 تم إيقاف وضع الديسكو D:';

  @override
  String get playSampleMessage => 'تشغيل رسالة تجريبية';

  @override
  String get textToSpeechRate => 'سرعة تحويل النص إلى كلام';

  @override
  String get textToSpeechPitch => 'طبقة صوت تحويل النص إلى كلام';

  @override
  String get muteBots => 'كتم تحويل النص إلى كلام للبوتات';

  @override
  String get muteEmotes => 'كتم جميع الرموز التعبيرية في تحويل النص إلى كلام';

  @override
  String get muteViewerNames => 'كتم أسماء المشاهدين في تحويل النص إلى كلام';

  @override
  String get subscribersOnly => 'المشتركون فقط';

  @override
  String get fontSize => 'حجم الخط';

  @override
  String get usernameContrastBoost => 'تعزيز تباين أسماء المستخدمين';

  @override
  String get twitchBadgeSettings => 'إعدادات شارات Twitch';

  @override
  String get twitchBadgeSettingsSubtitle => 'تحكم في الشارات الظاهرة';

  @override
  String get showDeletedMessages => 'عرض الرسائل المحذوفة';

  @override
  String get deletedMessagesGreyedOut =>
      'ستظهر الرسائل المحذوفة باللون الرمادي';

  @override
  String get deletedMessagesRemoved => 'ستُزال الرسائل المحذوفة';

  @override
  String get showLoginNames => 'عرض أسماء تسجيل الدخول';

  @override
  String get loginNamesShown =>
      'ستظهر أسماء تسجيل الدخول إذا كانت مختلفة عن الاسم المعروض';

  @override
  String get loginNamesHidden => 'ستُخفى أسماء تسجيل الدخول';

  @override
  String get compactMessages => 'ضغط الرسائل';

  @override
  String get dontCompactMessages => 'عدم ضغط الرسائل';

  @override
  String get dontCompactMessagesSubtitle => 'تظهر الرسائل دون تغيير';

  @override
  String get compactIndividualMessages => 'ضغط الرسائل الفردية';

  @override
  String get compactIndividualMessagesSubtitle =>
      'يتم اختصار النص المكرر في الرسائل';

  @override
  String get announcementPinDuration => 'مدة تثبيت الإعلانات';

  @override
  String get idleMessageAlertDuration => 'مدة تنبيه خمول الدردشة';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'إذا لم تصل أي رسائل خلال هذه المدة ثم وصلت رسالة جديدة، فسيتم تشغيل صوت تنبيه.';

  @override
  String get realtimeCashSubtitle => 'اربط محفظة ETH أو MATIC';

  @override
  String get walletAddress => 'عنوان المحفظة';

  @override
  String get streamlabsSubtitle => 'اطلع على تبرعاتك في Streamlabs';

  @override
  String get streamElementsSubtitle => 'اطلع على تبرعاتك في StreamElements';

  @override
  String get thirdPartyAuthError =>
      'لم ينجح ذلك. حاول مرة أخرى أو اسأل على Discord؟';

  @override
  String get companionAuthBrowserTooOld =>
      'متصفحك قديم جدًا لتسجيل الدخول مباشرة. امسح رمز QR هذا بهاتفك لتسجيل الدخول على جهاز آخر.';

  @override
  String get companionAuthScanQrCode =>
      'امسح رمز QR هذا بهاتفك لتسجيل الدخول على جهاز آخر.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return 'اشترك <b>$subscriberName</b>!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return 'جدّد <b>$subscriberName</b> اشتراكه لمدة $monthsString شهرًا!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'أهدى <b>$gifterName</b> $countString اشتراكات!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'أرسل <b>$senderName</b> $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'تسجيل الدخول باستخدام Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'هناك رسائل كثيرة جدًا. تم تعطيل تحويل النص إلى كلام';

  @override
  String get turnOffTextToSpeech => 'إيقاف';

  @override
  String get addChannel => 'إضافة قناة';

  @override
  String get addToChat => 'إضافة إلى الدردشة';

  @override
  String get defaultChannels => 'القنوات الافتراضية';

  @override
  String get defaultChannelsSubtitle => 'القنوات المعروضة عند فتح التطبيق';

  @override
  String get save => 'حفظ';

  @override
  String get resetToMyChannel => 'إعادة التعيين إلى قناتي';

  @override
  String get inChat => 'في الدردشة';

  @override
  String get removeFromChat => 'إزالة من الدردشة';

  @override
  String cantChatWithAccount(String provider) {
    return 'لا يمكن لحساب $provider الخاص بك الدردشة هنا';
  }

  @override
  String replaceChannel(String channel) {
    return 'استبدال $channel';
  }

  @override
  String get removeChannel => 'إزالة';

  @override
  String get voicePacks => 'Voice packs';

  @override
  String get voicePacksDescription =>
      'Voice packs read chat with natural-sounding voices that run on your device, offline once downloaded. The voices are machine-generated by AI, not recorded by a person.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices voices',
      one: '1 voice',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count languages',
      one: '1 language',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'This model\'s license (OpenRAIL-M) forbids harmful uses, such as impersonating people or spreading disinformation, and these restrictions apply to you too.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Delete $pack? This frees $size.';
  }

  @override
  String get voicePackDownload => 'Download';

  @override
  String get voicePackUpdate => 'Update';

  @override
  String get voicePackWaitingForWifi => 'Waiting for Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Use mobile data';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Downloading: $downloaded of $total';
  }

  @override
  String get voicePackInstalling => 'Installing';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Couldn\'t install $pack. Check your connection and try again.';
  }

  @override
  String get voices => 'Voices';

  @override
  String get perViewerVoice => 'Per-viewer voice';

  @override
  String get perViewerVoiceSubtitle =>
      'Each viewer gets their own voice. The voice you pick reads alerts, or everything when this is off.';

  @override
  String get streamLanguage => 'Stream language';

  @override
  String get ttsEngineNeural => 'Neural voice (on-device)';

  @override
  String get ttsEngineSystem => 'System voice';

  @override
  String languageUnsupported(String language) {
    return '$language isn\'t supported by your voice packs; the system voice will be used';
  }

  @override
  String get neuralFallbackLowMemory =>
      'This device doesn\'t have enough memory for neural voices, so chat is read with the system voice.';

  @override
  String get neuralFallbackLoadFailed =>
      'The neural voice couldn\'t load, so chat is read with the system voice.';

  @override
  String youtubeSuperChatEvent(String name, String amount) {
    return 'أرسل <b>$name</b> Super Chat بقيمة $amount!';
  }

  @override
  String youtubeSuperStickerEvent(String name, String amount) {
    return 'أرسل <b>$name</b> Super Sticker بقيمة $amount!';
  }

  @override
  String youtubeNewMemberEvent(String name) {
    return 'أصبح <b>$name</b> عضوًا!';
  }

  @override
  String youtubeMemberUpgradeEvent(String name, String level) {
    return 'رقّى <b>$name</b> عضويته إلى $level!';
  }

  @override
  String youtubeMemberMilestoneEvent(String name, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$name</b> عضو منذ $monthsString أشهر!';
  }

  @override
  String youtubeMembershipGiftingEvent(String name, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أهدى <b>$name</b> $countString عضويات!',
      one: 'أهدى <b>$name</b> عضوية!',
    );
    return '$_temp0';
  }

  @override
  String youtubeGiftMembershipReceivedEvent(String name) {
    return 'تلقّى <b>$name</b> عضوية مُهداة!';
  }

  @override
  String youtubeGiftEvent(String name, String giftName, int jewels) {
    final intl.NumberFormat jewelsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String jewelsString = jewelsNumberFormat.format(jewels);

    return 'أرسل <b>$name</b> $giftName ($jewelsString Jewels)!';
  }

  @override
  String youtubePollEvent(String question) {
    return 'استطلاع: $question';
  }

  @override
  String get youtubeMembersOnlyModeOn => 'وضع الأعضاء فقط مفعّل';

  @override
  String get youtubeMembersOnlyModeOff => 'وضع الأعضاء فقط متوقف';

  @override
  String get youtubeChatEnded => 'انتهت الدردشة المباشرة';
}
