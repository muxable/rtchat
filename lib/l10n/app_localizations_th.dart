// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'package:rtchat/l10n/app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get sendAMessage => 'ส่งข้อความ...';

  @override
  String get writeSomething => 'เขียนอะไรสักหน่อย...';

  @override
  String get speakToTheCrowds => 'พูดคุยกับผู้ชม...';

  @override
  String get shareYourThoughts => 'แบ่งปันความคิดของคุณ...';

  @override
  String get saySomethingYouLittleBitch => 'พูดอะไรหน่อยสิ เจ้าตัวแสบ...';

  @override
  String get search => 'ค้นหา';

  @override
  String get notSignedIn => 'ยังไม่ได้ลงชื่อเข้าใช้';

  @override
  String get searchChannels => 'ค้นหา';

  @override
  String get raidAChannel => 'เรด';

  @override
  String get noMessagesEmptyState => 'ที่นี่เงียบเหงาจัง';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ข้อความใหม่ $count ข้อความ',
      one: 'ข้อความใหม่ 1 ข้อความ',
      zero: 'ไม่มีข้อความใหม่',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'ลงชื่อเข้าใช้ด้วย Twitch';

  @override
  String get signInError => 'เกิดข้อผิดพลาดขณะลงชื่อเข้าใช้ โปรดลองอีกครั้ง';

  @override
  String get continueAsGuest => 'ดำเนินการต่อในฐานะผู้เยี่ยมชม';

  @override
  String get signInToSendMessages => 'ลงชื่อเข้าใช้เพื่อส่งข้อความ';

  @override
  String get currentViewers => 'ผู้ชมปัจจุบัน';

  @override
  String get textToSpeech => 'แปลงข้อความเป็นเสียงพูด';

  @override
  String get streamPreview => 'ตัวอย่างสตรีม';

  @override
  String get activityFeed => 'ฟีดกิจกรรม';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'สตรีมออนไลน์เมื่อ $dateString เวลา $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'สตรีมออฟไลน์เมื่อ $dateString เวลา $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'ล้างแชทเมื่อ $dateString เวลา $timeString';
  }

  @override
  String get configureQuickLinks => 'ตั้งค่าลิงก์ด่วน';

  @override
  String get disableRainMode => 'ปิดโหมดกันฝน';

  @override
  String get enableRainMode => 'เปิดโหมดกันฝน';

  @override
  String get disableRainModeSubtitle => 'จะเปิดใช้งานการโต้ตอบ';

  @override
  String get enableRainModeSubtitle => 'จะปิดใช้งานการโต้ตอบ';

  @override
  String get refreshAudioSources => 'รีเฟรชแหล่งเสียง';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รีเฟรชแหล่งเสียง $count แหล่งแล้ว',
      one: 'รีเฟรชแหล่งเสียง 1 แหล่งแล้ว',
      zero: 'ไม่มีแหล่งเสียงที่รีเฟรช',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get signOut => 'ออกจากระบบ';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get signOutConfirmation => 'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?';

  @override
  String get broadcaster => 'สตรีมเมอร์';

  @override
  String get moderators => 'ผู้ดูแล';

  @override
  String get viewers => 'ผู้ชม';

  @override
  String get communityVips => 'VIP ของชุมชน';

  @override
  String get searchViewers => 'ค้นหาผู้ชม';

  @override
  String get reconnecting => 'กำลังเชื่อมต่อใหม่...';

  @override
  String get twitchBadges => 'ตราสัญลักษณ์ Twitch';

  @override
  String get selectAll => 'เลือกทั้งหมด';

  @override
  String get quickLinks => 'ลิงก์ด่วน';

  @override
  String get swipeToDeleteQuickLinks => 'ปัดซ้ายหรือขวาเพื่อลบลิงก์ด่วน';

  @override
  String get quickLinksLabelHint => 'ป้ายกำกับ';

  @override
  String get invalidUrlErrorText => 'ดูเหมือนจะไม่ใช่ URL ที่ถูกต้อง';

  @override
  String get duplicateUrlErrorText => 'มีลิงก์นี้อยู่แล้ว';

  @override
  String get or => 'หรือ';

  @override
  String get clearCookies => 'ล้างคุกกี้';

  @override
  String get disabled => 'ปิดใช้งาน';

  @override
  String get twitchActivityFeed => 'ฟีดกิจกรรม Twitch';

  @override
  String get signInToEnable => 'คุณต้องลงชื่อเข้าใช้เพื่อเปิดใช้งานฟีเจอร์นี้';

  @override
  String get customUrl => 'URL ที่กำหนดเอง';

  @override
  String get preview => 'ตัวอย่าง';

  @override
  String get audioSources => 'แหล่งเสียง';

  @override
  String get enableOffStreamSwitchTitle =>
      'เปิดใช้งานขณะไม่ได้สตรีม (ใช้แบตเตอรี่มากขึ้น)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'เสียงจะเล่นแม้ในขณะที่คุณออฟไลน์';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'เสียงจะเล่นเฉพาะเมื่อคุณไลฟ์สดเท่านั้น';

  @override
  String get iosOggWarningTitle => 'เดี๋ยวก่อน! ฟังทางนี้!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS ไม่รองรับไฟล์มีเดีย *.ogg ซึ่งเป็นไฟล์เริ่มต้นบน Streamlabs โปรดตรวจสอบให้แน่ใจว่าแหล่งเสียงของคุณใช้รูปแบบอื่น มิฉะนั้นเสียงจะไม่เล่น';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'ปรับแต่งฟีดกิจกรรมของคุณ';

  @override
  String get audioSourcesSubtitle => 'เพิ่มแหล่งเว็บสำหรับเสียงแจ้งเตือน';

  @override
  String get quickLinksSubtitle => 'เพิ่มทางลัดไปยังเครื่องมือที่ใช้บ่อย';

  @override
  String get chatHistory => 'ประวัติแชท';

  @override
  String get chatHistorySubtitle => 'เปลี่ยนรูปลักษณ์ของแชท';

  @override
  String get textToSpeechSubtitle => 'เปลี่ยนการตั้งค่าแปลงข้อความเป็นเสียงพูด';

  @override
  String get events => 'อีเวนต์';

  @override
  String get eventsSubtitle => 'ตั้งค่าอีเวนต์ของ Twitch';

  @override
  String get thirdPartyServices => 'บริการจากภายนอก';

  @override
  String get thirdPartyServicesSubtitle => 'เชื่อมต่อกับบริการจากภายนอก';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> กำลังติดตามคุณ';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> และ <b>$displayNameTwo</b> กำลังติดตามคุณ';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> และอีก $numOthersString คนกำลังติดตามคุณ';
  }

  @override
  String unmuteUser(String displayName) {
    return 'เลิกปิดเสียง $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'ปิดเสียง $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'ไทม์เอาต์ $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'แบน $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'ปลดแบน $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'ดูโปรไฟล์ของ $displayName';
  }

  @override
  String get copyMessage => 'คัดลอกข้อความ';

  @override
  String get deleteMessage => 'ลบข้อความ';

  @override
  String get longScrollNotification => 'คุณเลื่อนมาไกลเหมือนกันนะ ว่าไหม?';

  @override
  String get stfu => 'หุบปาก';

  @override
  String get globalEmotes => 'อิโมตส่วนกลาง';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ผู้ติดตาม $countString คน',
      one: 'ผู้ติดตาม 1 คน',
      zero: 'ผู้ติดตาม 0 คน',
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
      other: 'ผู้ชม $countString คน',
      one: 'ผู้ชม 1 คน',
      zero: 'ผู้ชม 0 คน',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'สวัสดี! ดีใจที่คุณชอบใช้ตัวอย่างสตรีม แต่ขอแจ้งให้ทราบว่าฟีเจอร์นี้ใช้แบตเตอรี่ค่อนข้างมาก การอ่านแชทโดยไม่เปิดตัวอย่างสตรีมจะช่วยยืดอายุแบตเตอรี่ของคุณได้';

  @override
  String get okay => 'ตกลง';

  @override
  String get streamPreviewLoading => 'กำลังโหลด (หรือสตรีมออฟไลน์อยู่)...';

  @override
  String get copiedToClipboard => 'คัดลอกไปยังคลิปบอร์ดแล้ว';

  @override
  String get audioSourcesRequirePermissions =>
      'แหล่งเสียงต้องการสิทธิ์การเข้าถึง';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'อนุญาตให้ RealtimeChat แสดงผลทับแอปอื่นเพื่อใช้งานแหล่งเสียง';

  @override
  String get audioSourcesRemoveButton => 'นำแหล่งเสียงออก';

  @override
  String get audioSourcesOpenSettingsButton => 'เปิดการตั้งค่า';

  @override
  String get flashOn => 'เปิดแฟลช';

  @override
  String get flashOff => 'ปิดแฟลช';

  @override
  String get durationOneSecond => '1 วินาที';

  @override
  String get durationOneMinute => '1 นาที';

  @override
  String get durationTenMinutes => '10 นาที';

  @override
  String get durationOneHour => '1 ชั่วโมง';

  @override
  String get durationSixHours => '6 ชั่วโมง';

  @override
  String get durationOneDay => '1 วัน';

  @override
  String get durationTwoDays => '2 วัน';

  @override
  String get durationOneWeek => '1 สัปดาห์';

  @override
  String get durationTwoWeeks => '2 สัปดาห์';

  @override
  String get durationOneSecondTimeoutPrompt => 'ไทม์เอาต์เป็นเวลา 1 วินาที';

  @override
  String get durationOneMinuteTimeoutPrompt => 'ไทม์เอาต์เป็นเวลา 1 นาที';

  @override
  String get durationTenMinutesTimeoutPrompt => 'ไทม์เอาต์เป็นเวลา 10 นาที';

  @override
  String get durationOneHourTimeoutPrompt => 'ไทม์เอาต์เป็นเวลา 1 ชั่วโมง';

  @override
  String get durationSixHoursTimeoutPrompt => 'ไทม์เอาต์เป็นเวลา 6 ชั่วโมง';

  @override
  String get durationOneDayTimeoutPrompt => 'ไทม์เอาต์เป็นเวลา 1 วัน';

  @override
  String get durationTwoDaysTimeoutPrompt => 'ไทม์เอาต์เป็นเวลา 2 วัน';

  @override
  String get durationOneWeekTimeoutPrompt => 'ไทม์เอาต์เป็นเวลา 1 สัปดาห์';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'ไทม์เอาต์เป็นเวลา 2 สัปดาห์';

  @override
  String get errorFetchingViewerList =>
      'เราไม่สามารถดึงรายชื่อผู้ชมสำหรับช่องนี้ได้';

  @override
  String get eventsTitle => 'อีเวนต์';

  @override
  String get followEventConfigTitle => 'อีเวนต์การติดตาม';

  @override
  String get customizeYourFollowEvent => 'ปรับแต่งอีเวนต์การติดตามของคุณ';

  @override
  String get subscribeEventConfigTitle => 'อีเวนต์การซับสไครบ์';

  @override
  String get customizeYourSubscriptionEvent =>
      'ปรับแต่งอีเวนต์การซับสไครบ์ของคุณ';

  @override
  String get cheerEventConfigTitle => 'อีเวนต์การเชียร์';

  @override
  String get customizeYourCheerEvent => 'ปรับแต่งอีเวนต์การเชียร์ของคุณ';

  @override
  String get raidEventConfigTitle => 'อีเวนต์การเรด';

  @override
  String get customizeYourRaidEvent => 'ปรับแต่งอีเวนต์การเรดของคุณ';

  @override
  String get hostEventConfigTitle => 'อีเวนต์การโฮสต์';

  @override
  String get customizeYourHostEvent => 'ปรับแต่งอีเวนต์การโฮสต์ของคุณ';

  @override
  String get hypetrainEventConfigTitle => 'อีเวนต์ Hype Train';

  @override
  String get customizeYourHypetrainEvent => 'ปรับแต่งอีเวนต์ Hype Train ของคุณ';

  @override
  String get pollEventConfigTitle => 'อีเวนต์โพล';

  @override
  String get customizeYourPollEvent => 'ปรับแต่งอีเวนต์โพลของคุณ';

  @override
  String get predictionEventConfigTitle => 'อีเวนต์การทายผล';

  @override
  String get customizeYourPredictionEvent => 'ปรับแต่งอีเวนต์การทายผลของคุณ';

  @override
  String get channelPointRedemptionEventConfigTitle => 'อีเวนต์การแลกแต้มช่อง';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'ปรับแต่งอีเวนต์การแลกแต้มช่องของคุณ';

  @override
  String get outgoingRaidEventConfigTitle => 'อีเวนต์การเรดขาออก';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'ปรับแต่งอีเวนต์การเรดขาออกของคุณ';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> กำลังเรดพร้อมผู้ชม <b>$viewerCountString</b> คน!';
  }

  @override
  String get shoutout => 'แนะนำช่อง';

  @override
  String raidingEventRaiding(String displayName) {
    return 'กำลังเรด <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString วินาที';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> เรดแล้ว!';
  }

  @override
  String get raidingEventJoin => 'เข้าร่วม';

  @override
  String raidingEventCanceled(String displayName) {
    return 'ยกเลิกการเรด <b>$displayName</b> แล้ว';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> ได้ซับสไครบ์ระดับ Tier $tier!';
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

    return '<b>$gifterUserName</b> ได้มอบซับระดับ Tier $tier จำนวน $totalString ซับ รวมทั้งหมด $cumulativeTotalString ซับ!';
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

    return '<b>$subscriberUserName</b> ได้ซับสไครบ์ระดับ Tier $tier เป็นเวลา $cumulativeMonthsString เดือนแล้ว!';
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

    return '<b>$subscriberUserName</b> ได้ซับสไครบ์ระดับ Tier $tier ล่วงหน้า $durationMonthsString เดือน รวมทั้งหมด $cumulativeMonthsString เดือน!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> ให้ทิป <b>$value $currency</b>';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'ผู้ไม่ประสงค์ออกนามให้ทิป <b>$value $currency</b>';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ให้ทิป <b>$formattedAmount</b> บน StreamElements';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> ให้ทิป <b>$formattedAmount</b> บน Streamlabs';
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

    return '<b>$redeemerUsername</b> แลก <b>$rewardName</b> ด้วย <b>$rewardCostString</b> แต้ม $userInput';
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

    return '<b>$redeemerUsername</b> แลก <b>$rewardName</b> ด้วย <b>$rewardCostString</b> แต้ม';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> เชียร์ <b>$bitsString</b> บิต $cheerMessage';
  }

  @override
  String get anonymous => 'ผู้ไม่ประสงค์ออกนาม';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> กำลังโฮสต์พร้อมผู้ชม <b>$viewersString</b> คน';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train เลเวล <b>$level</b> กำลังดำเนินอยู่! สำเร็จแล้ว <b>$progressPercent%</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train เลเวล <b>$levelString</b> สำเร็จแล้ว';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train เลเวล <b>$levelString</b> ล้มเหลว';
  }

  @override
  String get sampleMessage =>
      'นี่คือข้อความตัวอย่างสำหรับการแปลงข้อความเป็นเสียงพูด';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author พูดว่า: $text';
  }

  @override
  String get textToSpeechEnabled => 'เปิดใช้งานการแปลงข้อความเป็นเสียงพูดแล้ว';

  @override
  String get textToSpeechDisabled => 'ปิดใช้งานการแปลงข้อความเป็นเสียงพูดแล้ว';

  @override
  String get alertsEnabled => 'เฉพาะการแจ้งเตือน';

  @override
  String get pinDuration => 'ระยะเวลาปักหมุด';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds วินาที',
      one: '1 วินาที',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes นาที',
      one: '1 นาที',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'เปิดใช้งานอีเวนต์';

  @override
  String get showEventInChatHistory => 'แสดงอีเวนต์ในประวัติแชท';

  @override
  String get enableShoutouts => 'เปิดใช้งานการแนะนำช่อง';

  @override
  String get enableShoutoutsSubtitle => 'ส่งลิงก์ไปยังช่องที่เรดในแชท';

  @override
  String get raidConfigurationTitle => 'การตั้งค่าการเรด';

  @override
  String get cheerConfigurationTitle => 'การตั้งค่าการเชียร์';

  @override
  String get followConfigurationTitle => 'การตั้งค่าการติดตาม';

  @override
  String get outgoingRaidConfigurationTitle => 'การตั้งค่าการเรดขาออก';

  @override
  String get hostConfigurationTitle => 'การตั้งค่าการโฮสต์';

  @override
  String get channelPointConfigurationTitle => 'การตั้งค่าแต้มช่อง';

  @override
  String get pollConfigurationTitle => 'การตั้งค่าโพล';

  @override
  String get hypetrainConfigurationTitle => 'การตั้งค่า Hype Train';

  @override
  String get subscriptionConfigurationTitle => 'การตั้งค่าการซับสไครบ์';

  @override
  String get predictionConfigurationTitle => 'การตั้งค่าการทายผล';

  @override
  String get unfulfilledRewardsPinDuration =>
      'ระยะเวลาปักหมุดเพิ่มเติมสำหรับรางวัลที่ยังไม่ได้ดำเนินการ';

  @override
  String get pollPinDuration => 'ระยะเวลาปักหมุดหลังจากสรุปผลแล้ว';

  @override
  String get hypetrainPinDuration =>
      'ระยะเวลาปักหมุดหลังจาก Hype Train สิ้นสุดลง';

  @override
  String get enableGiftedSubscriptions => 'เปิดใช้งานการแสดงซับของขวัญรายบุคคล';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'แสดงทุกซับสไครบ์ที่ได้รับเป็นของขวัญ';

  @override
  String get settingsBackupTitle => 'สำรองและกู้คืนการตั้งค่า';

  @override
  String get cloudBackup => 'การสำรองข้อมูลบนคลาวด์';

  @override
  String get lastBackupNever => 'สำรองข้อมูลล่าสุด: ไม่เคย';

  @override
  String get backUp => 'สำรองข้อมูล';

  @override
  String get restore => 'กู้คืน';

  @override
  String get localBackup => 'การสำรองข้อมูลในเครื่อง';

  @override
  String get exportSettings => 'ส่งออก';

  @override
  String get importSettings => 'นำเข้า';

  @override
  String get showViewerAndFollowerCount => 'แสดงจำนวนผู้ชมและผู้ติดตาม';

  @override
  String get screenOrientation => 'การวางแนวหน้าจอ';

  @override
  String get appTheme => 'ธีมของแอป';

  @override
  String get systemDefault => 'ตามระบบ';

  @override
  String get portrait => 'แนวตั้ง';

  @override
  String get landscape => 'แนวนอน';

  @override
  String get lightTheme => 'สว่าง';

  @override
  String get darkTheme => 'มืด';

  @override
  String get openSourceTitle => 'RealtimeChat เป็นโอเพนซอร์ส';

  @override
  String get openSourceSubtitle => 'พบกับเราได้บน GitHub!';

  @override
  String get discordSubtitle => 'เข้าร่วม Discord ของ Muxable!';

  @override
  String get earlyTestersThanks =>
      'ขอบคุณผู้ทดสอบกลุ่มแรกทุกคนที่ส่งรายงานบั๊กเข้ามา!';

  @override
  String get discoModeEnabled => '🕺 เปิดโหมดดิสโก้แล้ว! :D';

  @override
  String get discoModeDisabled => '🕺 ปิดโหมดดิสโก้แล้ว D:';

  @override
  String get playSampleMessage => 'เล่นข้อความตัวอย่าง';

  @override
  String get textToSpeechRate => 'ความเร็วในการอ่านออกเสียง';

  @override
  String get textToSpeechPitch => 'ระดับเสียงในการอ่านออกเสียง';

  @override
  String get muteBots => 'ปิดเสียงอ่านข้อความจากบอท';

  @override
  String get muteEmotes => 'ปิดเสียงอ่านอิโมตทั้งหมด';

  @override
  String get muteViewerNames => 'ปิดเสียงอ่านชื่อผู้ชม';

  @override
  String get subscribersOnly => 'เฉพาะซับสไครเบอร์เท่านั้น';

  @override
  String get fontSize => 'ขนาดตัวอักษร';

  @override
  String get usernameContrastBoost => 'เพิ่มความคมชัดของสีชื่อผู้ใช้';

  @override
  String get twitchBadgeSettings => 'การตั้งค่าตราสัญลักษณ์ Twitch';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'ควบคุมว่าจะให้แสดงตราสัญลักษณ์ใดบ้าง';

  @override
  String get showDeletedMessages => 'แสดงข้อความที่ถูกลบ';

  @override
  String get deletedMessagesGreyedOut => 'ข้อความที่ถูกลบจะแสดงเป็นสีเทา';

  @override
  String get deletedMessagesRemoved => 'ข้อความที่ถูกลบจะถูกนำออก';

  @override
  String get showLoginNames => 'แสดงชื่อล็อกอิน';

  @override
  String get loginNamesShown => 'ชื่อล็อกอินจะแสดงหากไม่ตรงกับชื่อที่แสดง';

  @override
  String get loginNamesHidden => 'ชื่อล็อกอินจะถูกซ่อนไว้';

  @override
  String get compactMessages => 'ย่อข้อความให้กระชับ';

  @override
  String get dontCompactMessages => 'ไม่ต้องย่อข้อความ';

  @override
  String get dontCompactMessagesSubtitle =>
      'ข้อความจะแสดงตามเดิมโดยไม่มีการเปลี่ยนแปลง';

  @override
  String get compactIndividualMessages => 'ย่อข้อความแต่ละรายการ';

  @override
  String get compactIndividualMessagesSubtitle =>
      'ข้อความที่ซ้ำกันภายในข้อความจะถูกย่อให้สั้นลง';

  @override
  String get announcementPinDuration => 'ระยะเวลาปักหมุดประกาศ';

  @override
  String get idleMessageAlertDuration => 'ระยะเวลาแจ้งเตือนเมื่อแชทนิ่ง';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'หากไม่มีข้อความใดๆ ในช่วงเวลานี้และมีข้อความใหม่เข้ามา จะมีเสียงแจ้งเตือนดังขึ้น';

  @override
  String get realtimeCashSubtitle => 'เชื่อมต่อกระเป๋าเงิน ETH หรือ MATIC';

  @override
  String get walletAddress => 'ที่อยู่กระเป๋าเงิน';

  @override
  String get streamlabsSubtitle => 'ดูยอดโดเนท Streamlabs ของคุณ';

  @override
  String get streamElementsSubtitle => 'ดูยอดโดเนท StreamElements ของคุณ';

  @override
  String get thirdPartyAuthError =>
      'อืม ไม่สำเร็จแฮะ ลองอีกครั้ง หรือถามใน Discord ดีไหม?';

  @override
  String get companionAuthBrowserTooOld =>
      'เบราว์เซอร์ของคุณเก่าเกินไปที่จะรองรับการลงชื่อเข้าใช้โดยตรง สแกนคิวอาร์โค้ดนี้ด้วยโทรศัพท์ของคุณเพื่อลงชื่อเข้าใช้บนอุปกรณ์อื่น';

  @override
  String get companionAuthScanQrCode =>
      'สแกนคิวอาร์โค้ดนี้ด้วยโทรศัพท์ของคุณเพื่อลงชื่อเข้าใช้บนอุปกรณ์อื่น';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> ได้ซับสไครบ์!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> ได้ซับสไครบ์ต่อเป็นเวลา $monthsString เดือน!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> ได้มอบซับเป็นของขวัญ $countString ซับ!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> ส่ง $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'ลงชื่อเข้าใช้ด้วย Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'มีข้อความมากเกินไป ปิดใช้งานการแปลงข้อความเป็นเสียงพูดแล้ว';

  @override
  String get turnOffTextToSpeech => 'ปิด';

  @override
  String get addToChat => 'เพิ่มในแชท';

  @override
  String get inChat => 'ในแชท';

  @override
  String get removeFromChat => 'นำออกจากแชท';

  @override
  String cantChatWithAccount(String provider) {
    return 'บัญชี $provider ของคุณไม่สามารถแชทที่นี่ได้';
  }

  @override
  String get cantChatWithAccounts => 'บัญชีของคุณไม่สามารถแชทที่นี่ได้';

  @override
  String sendAMessageTo(String channel) {
    return 'ส่งข้อความถึง $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'แทนที่ $channel';
  }

  @override
  String get voicePacks => 'แพ็กเสียง';

  @override
  String get voicePacksDescription =>
      'แพ็กเสียงจะอ่านแชทด้วยเสียงที่เป็นธรรมชาติซึ่งทำงานบนอุปกรณ์ของคุณแบบออฟไลน์เมื่อดาวน์โหลดแล้ว เสียงเหล่านี้สร้างขึ้นโดย AI ไม่ได้บันทึกจากคนจริง';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices เสียง',
      one: '1 เสียง',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ภาษา',
      one: '1 ภาษา',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'สัญญาอนุญาตของโมเดลนี้ (OpenRAIL-M) ห้ามนำไปใช้ในทางที่เป็นอันตราย เช่น การแอบอ้างเป็นบุคคลอื่นหรือการเผยแพร่ข้อมูลเท็จ และข้อจำกัดเหล่านี้มีผลบังคับใช้กับคุณด้วย';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'ลบ $pack หรือไม่? การดำเนินการนี้จะเพิ่มพื้นที่ว่าง $size';
  }

  @override
  String get voicePackDownload => 'ดาวน์โหลด';

  @override
  String get voicePackUpdate => 'อัปเดต';

  @override
  String get voicePackWaitingForWifi => 'กำลังรอ Wi-Fi';

  @override
  String get voicePackUseMobileData => 'ใช้ข้อมูลมือถือ';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'กำลังดาวน์โหลด: $downloaded จาก $total';
  }

  @override
  String get voicePackInstalling => 'กำลังติดตั้ง';

  @override
  String voicePackInstallFailed(String pack) {
    return 'ไม่สามารถติดตั้ง $pack ได้ โปรดตรวจสอบการเชื่อมต่อของคุณแล้วลองอีกครั้ง';
  }

  @override
  String get voices => 'เสียงพูด';

  @override
  String get perViewerVoice => 'แยกเสียงตามผู้ชม';

  @override
  String get perViewerVoiceSubtitle =>
      'ผู้ชมแต่ละคนจะมีเสียงของตัวเอง เสียงที่คุณเลือกจะใช้สำหรับอ่านการแจ้งเตือน หรืออ่านทั้งหมดเมื่อปิดตัวเลือกนี้';

  @override
  String get streamLanguage => 'ภาษาของสตรีม';

  @override
  String get ttsEngineNeural => 'เสียง Neural (บนอุปกรณ์)';

  @override
  String get ttsEngineSystem => 'เสียงของระบบ';

  @override
  String languageUnsupported(String language) {
    return 'แพ็กเสียงของคุณไม่รองรับภาษา$language ระบบจะใช้เสียงของระบบแทน';
  }

  @override
  String get neuralFallbackLowMemory =>
      'อุปกรณ์นี้มีหน่วยความจำไม่เพียงพอสำหรับเสียง Neural จึงอ่านแชทด้วยเสียงของระบบแทน';

  @override
  String get neuralFallbackLoadFailed =>
      'ไม่สามารถโหลดเสียง Neural ได้ จึงอ่านแชทด้วยเสียงของระบบแทน';

  @override
  String get accounts => 'บัญชี';

  @override
  String get accountsSubtitle => 'ลงชื่อเข้าใช้ในแต่ละแพลตฟอร์มที่คุณสตรีม';

  @override
  String addProviderAccount(String provider) {
    return 'เพิ่มบัญชี $provider';
  }

  @override
  String signInWithProvider(String provider) {
    return 'ลงชื่อเข้าใช้ด้วย $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'ออกจากระบบ $channel บน $provider หรือไม่?';
  }

  @override
  String get signOutOfAll => 'ออกจากระบบทุกบัญชี';
}
