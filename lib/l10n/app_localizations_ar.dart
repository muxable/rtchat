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
  String get alertsEnabled => 'Alerts only';
}
