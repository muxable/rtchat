// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get sendAMessage => '发送消息...';

  @override
  String get writeSomething => '说些设么...';

  @override
  String get speakToTheCrowds => '对大众发布...';

  @override
  String get shareYourThoughts => '分享你的意见...';

  @override
  String get saySomethingYouLittleBitch => ' 说点什么，你这个小婊子...';

  @override
  String get search => '搜索';

  @override
  String get notSignedIn => '未登录';

  @override
  String get searchChannels => '搜索';

  @override
  String get raidAChannel => '袭击';

  @override
  String get noMessagesEmptyState => '太安静了';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則新訊息',
      one: '1 則新訊息',
      zero: '沒有新訊息',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Twitch 登录';

  @override
  String get signInError => '登录时出错。请重试。';

  @override
  String get continueAsGuest => '以访客继续';

  @override
  String get signInToSendMessages => '登录后发送消息';

  @override
  String get currentViewers => '当前观众';

  @override
  String get textToSpeech => '文字转语音';

  @override
  String get streamPreview => '串流预览';

  @override
  String get activityFeed => '活动提要';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString，$timeString 上线';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString，$timeString 下线';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString删除聊天记录';
  }

  @override
  String get configureQuickLinks => '配置快速链接';

  @override
  String get disableRainMode => '关闭下雨模式';

  @override
  String get enableRainMode => '启用下雨模式';

  @override
  String get disableRainModeSubtitle => '开通交互功能';

  @override
  String get enableRainModeSubtitle => '交互功能会被禁用';

  @override
  String get refreshAudioSources => '刷新音源';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 音訊來源已刷新',
      one: '1 個音訊來源已刷新',
      zero: '沒有刷新音訊來源',
    );
    return '$_temp0';
  }

  @override
  String get settings => '设置';

  @override
  String get signOut => '登出';

  @override
  String get cancel => '取消';

  @override
  String get signOutConfirmation => '您确定要退出吗';

  @override
  String get broadcaster => '直播员';

  @override
  String get moderators => '主持人';

  @override
  String get viewers => '观众';

  @override
  String get communityVips => '社区贵宾';

  @override
  String get searchViewers => '搜索观众';

  @override
  String get reconnecting => '正在重新连接...';

  @override
  String get twitchBadges => 'Twitch徽章';

  @override
  String get selectAll => '全选';

  @override
  String get quickLinks => '快速链接';

  @override
  String get swipeToDeleteQuickLinks => '向左或向右滑动以删除快速链接';

  @override
  String get quickLinksLabelHint => '标签';

  @override
  String get invalidUrlErrorText => '这看起来不像是有效的网址';

  @override
  String get duplicateUrlErrorText => '此链接已存在';

  @override
  String get or => '或者';

  @override
  String get clearCookies => '清除Cookies';

  @override
  String get disabled => '禁用';

  @override
  String get twitchActivityFeed => 'Twitch活动提要';

  @override
  String get signInToEnable => '您必须登录才能启用此功能';

  @override
  String get customUrl => '自定义网址';

  @override
  String get preview => '预览1';

  @override
  String get audioSources => '音源';

  @override
  String get enableOffStreamSwitchTitle => '启用离线（使用更多电池）';

  @override
  String get enableOffStreamSwitchEnabledSubtitle => '离线时也会播放音频';

  @override
  String get enableOffStreamSwitchDisabledSubtitle => '音频只会在您直播时播放';

  @override
  String get iosOggWarningTitle => '嘿！听着！';

  @override
  String get iosOggWarningSubtitle =>
      'iOS 不支持 *.ogg 媒体文件，这是 Streamlabs 上的默认文件。确保您的音频源使用其他格式，否则无法播放';

  @override
  String get url => '网址';

  @override
  String get activityFeedSubtitle => '自定义您的活动提要';

  @override
  String get audioSourcesSubtitle => '警报声音添加网络来源';

  @override
  String get quickLinksSubtitle => '为常用工具添加快捷方式';

  @override
  String get chatHistory => '聊天记录';

  @override
  String get chatHistorySubtitle => '更改聊天外观';

  @override
  String get textToSpeechSubtitle => '更改文字转语音设置';

  @override
  String get events => '事件';

  @override
  String get eventsSubtitle => '配置 Twitch 事件';

  @override
  String get thirdPartyServices => '第三方服务';

  @override
  String get thirdPartyServicesSubtitle => '连接到第三方服务';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> 正在關注你';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> 和 <b>$displayNameTwo</b> 正在關注你';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>, <b>$displayNameTwo</b>, 和 $numOthersString 其他人正在關注你';
  }

  @override
  String unmuteUser(String displayName) {
    return '取消静音$displayName';
  }

  @override
  String muteUser(String displayName) {
    return '将$displayName静音';
  }

  @override
  String timeoutUser(String displayName) {
    return '暂停$displayName';
  }

  @override
  String banUser(String displayName) {
    return '禁$displayName';
  }

  @override
  String unbanUser(String displayName) {
    return '解封$displayName';
  }

  @override
  String viewProfile(String displayName) {
    return '查看$displayName 的个人资料';
  }

  @override
  String get copyMessage => '复制消息';

  @override
  String get deleteMessage => '删除消息';

  @override
  String get longScrollNotification => '你滚动有点远，你不觉得吗？';

  @override
  String get stfu => '闭嘴';

  @override
  String get globalEmotes => '全球表情';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 追隨者',
      one: '1 追隨者',
      zero: '0 追隨者',
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
      other: '$countString 觀眾',
      one: '1 觀眾',
      zero: '0 觀眾',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      '很高兴您喜欢使用我们的预览，但请注意它会消耗大量电池。只阅读聊天会延长你的电池寿命。';

  @override
  String get okay => '好的';

  @override
  String get streamPreviewLoading => '正在加载（或以离线）...';

  @override
  String get copiedToClipboard => '复制到剪贴板';

  @override
  String get audioSourcesRequirePermissions => '音频源需要权限';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      '允许 RealtimeChat 覆盖其他应用程序以使用音频源';

  @override
  String get audioSourcesRemoveButton => '删除音频源';

  @override
  String get audioSourcesOpenSettingsButton => '打开设置';

  @override
  String get flashOn => '打开闪光灯';

  @override
  String get flashOff => '关闭闪光灯';

  @override
  String get durationOneSecond => '1秒';

  @override
  String get durationOneMinute => '1分钟';

  @override
  String get durationTenMinutes => '10分钟';

  @override
  String get durationOneHour => '1小时';

  @override
  String get durationSixHours => '6个小时';

  @override
  String get durationOneDay => '1天';

  @override
  String get durationTwoDays => '2天';

  @override
  String get durationOneWeek => '1周';

  @override
  String get durationTwoWeeks => '2週';

  @override
  String get durationOneSecondTimeoutPrompt => '暂停1秒钟';

  @override
  String get durationOneMinuteTimeoutPrompt => '暂停1分钟';

  @override
  String get durationTenMinutesTimeoutPrompt => '暂停10分钟';

  @override
  String get durationOneHourTimeoutPrompt => '暂停1小时';

  @override
  String get durationSixHoursTimeoutPrompt => '暂停6小时';

  @override
  String get durationOneDayTimeoutPrompt => '暂停1天';

  @override
  String get durationTwoDaysTimeoutPrompt => '暂停2天';

  @override
  String get durationOneWeekTimeoutPrompt => '暂停1周';

  @override
  String get durationTwoWeeksTimeoutPrompt => '暂停2周';

  @override
  String get errorFetchingViewerList => '我们无法获取此频道的观众列表';

  @override
  String get eventsTitle => '事件';

  @override
  String get followEventConfigTitle => '关注事件';

  @override
  String get customizeYourFollowEvent => '自定义您的关注事件';

  @override
  String get subscribeEventConfigTitle => '订阅事件';

  @override
  String get customizeYourSubscriptionEvent => '自定义您的订阅事件';

  @override
  String get cheerEventConfigTitle => '欢呼事件';

  @override
  String get customizeYourCheerEvent => '自定义您的欢呼事件';

  @override
  String get raidEventConfigTitle => '突袭事件';

  @override
  String get customizeYourRaidEvent => '自定义您的突袭事件';

  @override
  String get hostEventConfigTitle => '主持事件';

  @override
  String get customizeYourHostEvent => '自定义您的主持事件';

  @override
  String get hypetrainEventConfigTitle => '热潮列车事件';

  @override
  String get customizeYourHypetrainEvent => '自定义您的热潮列车事件';

  @override
  String get pollEventConfigTitle => '投票事件';

  @override
  String get customizeYourPollEvent => '自定义您的投票事件';

  @override
  String get predictionEventConfigTitle => '预测事件';

  @override
  String get customizeYourPredictionEvent => '自定义您的预测事件';

  @override
  String get channelPointRedemptionEventConfigTitle => '频道积分兑换事件';

  @override
  String get customizeYourChannelPointRedemptionEvent => '自定义您的频道积分兑换事件';

  @override
  String get outgoingRaidEventConfigTitle => '外发突袭事件';

  @override
  String get customizeYourOutgoingRaidEvent => '自定义您的外发突袭事件';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b> 正在进行突袭，带着 <b>$viewerCountString</b> 位观众！';
  }

  @override
  String get shoutout => '大喊';

  @override
  String raidingEventRaiding(String displayName) {
    return '正在突袭 <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString秒';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> 已经突袭了！';
  }

  @override
  String get raidingEventJoin => '加入';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> 的突袭被取消了。';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> 已订阅第 $tier 层！';
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

    return '<b>$gifterUserName</b> 已赠送 $totalString 个第 $tier 层订阅，总计 $cumulativeTotalString 个！';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> 已订阅 $cumulativeMonthsString 个月的第 $tier 层！';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> 小费 <b>$value $currency</b>。';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return '匿名酬金 <b>$value $currency</b>。';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> 在 StreamElements 上打赏了 <b>$formattedAmount</b>。';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> 在 Streamlabs 上打赏了 <b>$formattedAmount</b>。';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> 兑换了 <b>$rewardName</b>，花费了 <b>$rewardCostString</b> 点数。$userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> 兑换了 <b>$rewardName</b>，花费了 <b>$rewardCostString</b> 点数。';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> 欢呼了 <b>$bitsString</b> 点。$cheerMessage';
  }

  @override
  String get anonymous => '匿名';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> 正在主持，带着 <b>$viewersString</b> 位观众。';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return '热潮列车等級 <b>$level</b> 進行中！已完成 <b>$progressPercent%</b>！';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return '热潮列车等級 <b>$levelString</b> 成功。';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return '热潮列车等級 <b>$levelString</b> 失敗。';
  }

  @override
  String get sampleMessage => '這是文字轉語音的訊息範例。';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author 說: $text';
  }

  @override
  String get textToSpeechEnabled => '已啟用文字轉語音';

  @override
  String get textToSpeechDisabled => '文字轉語音已停用';

  @override
  String get alertsEnabled => 'Alerts only';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get sendAMessage => '發送訊息...';

  @override
  String get writeSomething => '寫點什麼...';

  @override
  String get speakToTheCrowds => '對眾人說...';

  @override
  String get shareYourThoughts => '分享你的想法...';

  @override
  String get saySomethingYouLittleBitch => '說些什麼，你這小婊子...';

  @override
  String get search => '搜尋';

  @override
  String get notSignedIn => '未登入';

  @override
  String get searchChannels => '搜尋';

  @override
  String get raidAChannel => '揪團';

  @override
  String get noMessagesEmptyState => '這裡很寧靜。';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則新訊息',
      one: '1 則新訊息',
      zero: '沒有新訊息',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => '使用 Twitch 登入';

  @override
  String get signInError => '登入時發生錯誤。請重試。';

  @override
  String get continueAsGuest => '繼續作為訪客';

  @override
  String get signInToSendMessages => '登入以發送訊息';

  @override
  String get currentViewers => '目前觀眾數';

  @override
  String get textToSpeech => '文字轉語音';

  @override
  String get streamPreview => '直播預覽';

  @override
  String get activityFeed => '活動動態';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '自 $dateString $timeString 開始直播';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '自 $dateString $timeString 結束直播';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '於 $dateString $timeString 清除聊天';
  }

  @override
  String get configureQuickLinks => '設定快速連結';

  @override
  String get disableRainMode => '關閉下雨模式';

  @override
  String get enableRainMode => '啟用下雨模式';

  @override
  String get disableRainModeSubtitle => '互動將被啟用';

  @override
  String get enableRainModeSubtitle => '互動將被停用';

  @override
  String get refreshAudioSources => '重新整理音訊來源';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個音訊來源重新整理',
      one: '重新整理 1 個音訊來源',
      zero: '沒有重新整理音訊來源',
    );
    return '$_temp0';
  }

  @override
  String get settings => '設定';

  @override
  String get signOut => '登出';

  @override
  String get cancel => '取消';

  @override
  String get signOutConfirmation => '您確定要登出嗎？';

  @override
  String get broadcaster => '主播';

  @override
  String get moderators => '管理員';

  @override
  String get viewers => '觀眾';

  @override
  String get communityVips => '社群 VIP';

  @override
  String get searchViewers => '搜尋觀眾';

  @override
  String get reconnecting => '重新連線中...';

  @override
  String get twitchBadges => 'Twitch 徽章';

  @override
  String get selectAll => '全選';

  @override
  String get quickLinks => '快速連結';

  @override
  String get swipeToDeleteQuickLinks => '向左或向右滑動以刪除快速連結';

  @override
  String get quickLinksLabelHint => '標籤';

  @override
  String get invalidUrlErrorText => '這似乎不是有效的網址';

  @override
  String get duplicateUrlErrorText => '此連結已存在';

  @override
  String get or => '或';

  @override
  String get clearCookies => '清除 Cookies';

  @override
  String get disabled => '停用';

  @override
  String get twitchActivityFeed => 'Twitch 活動動態';

  @override
  String get signInToEnable => '您必須登入以啟用此功能';

  @override
  String get customUrl => '自訂網址';

  @override
  String get preview => '預覽';

  @override
  String get audioSources => '音訊來源';

  @override
  String get enableOffStreamSwitchTitle => '啟用離線模式（耗更多電池）';

  @override
  String get enableOffStreamSwitchEnabledSubtitle => '離線時音訊也會播放';

  @override
  String get enableOffStreamSwitchDisabledSubtitle => '只有直播時音訊會播放';

  @override
  String get iosOggWarningTitle => '嘿！聽著！';

  @override
  String get iosOggWarningSubtitle =>
      'iOS 不支援 *.ogg 媒體檔案，而這是 Streamlabs 的預設檔案。確保您的音訊來源使用不同的格式，否則它們將無法播放。';

  @override
  String get url => '網址';

  @override
  String get activityFeedSubtitle => '自訂您的活動動態';

  @override
  String get audioSourcesSubtitle => '新增網頁來源以作為警示音';

  @override
  String get quickLinksSubtitle => '新增常用工具的快速連結';

  @override
  String get chatHistory => '聊天歷史';

  @override
  String get chatHistorySubtitle => '變更聊天外觀';

  @override
  String get textToSpeechSubtitle => '變更文字轉語音設定';

  @override
  String get events => '事件';

  @override
  String get eventsSubtitle => '設定 Twitch 事件';

  @override
  String get thirdPartyServices => '第三方服務';

  @override
  String get thirdPartyServicesSubtitle => '連結至第三方服務';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> 追隨了您';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> 和 <b>$displayNameTwo</b> 追隨了您';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>、<b>$displayNameTwo</b>，以及其他 $numOthersString 位追隨了您';
  }

  @override
  String unmuteUser(String displayName) {
    return '解除靜音 $displayName';
  }

  @override
  String muteUser(String displayName) {
    return '靜音 $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return '封鎖 $displayName';
  }

  @override
  String banUser(String displayName) {
    return '封鎖 $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return '解封 $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return '查看 $displayName 的個人資料';
  }

  @override
  String get copyMessage => '複製訊息';

  @override
  String get deleteMessage => '刪除訊息';

  @override
  String get longScrollNotification => '您滾動了相當多，不是嗎？';

  @override
  String get stfu => '閉嘴，該死';

  @override
  String get globalEmotes => '全域表情符號';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 位追隨者',
      one: '1 位追隨者',
      zero: '0 位追隨者',
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
      other: '$countString 位觀眾',
      one: '1 位觀眾',
      zero: '0 位觀眾',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      '嗨！很高興您喜歡使用直播預覽，但請注意它會消耗相當多的電池。在沒有它的情況下閱讀聊天將延長電池壽命。';

  @override
  String get okay => '好的';

  @override
  String get streamPreviewLoading => '正在載入（或直播已離線）...';

  @override
  String get copiedToClipboard => '已複製';

  @override
  String get audioSourcesRequirePermissions => '音訊來源需要權限';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      '授予 RealtimeChat 權限，以在其他應用程式之上顯示，以使用音訊來源。';

  @override
  String get audioSourcesRemoveButton => '移除音訊來源';

  @override
  String get audioSourcesOpenSettingsButton => '開啟設定';

  @override
  String get flashOn => '開啟閃光燈';

  @override
  String get flashOff => '關閉閃光燈';

  @override
  String get durationOneSecond => '1秒';

  @override
  String get durationOneMinute => '1分鐘';

  @override
  String get durationTenMinutes => '10分鐘';

  @override
  String get durationOneHour => '1小時';

  @override
  String get durationSixHours => '6小時';

  @override
  String get durationOneDay => '1天';

  @override
  String get durationTwoDays => '2天';

  @override
  String get durationOneWeek => '1週';

  @override
  String get durationTwoWeeks => '2週';

  @override
  String get durationOneSecondTimeoutPrompt => '封鎖1秒鐘';

  @override
  String get durationOneMinuteTimeoutPrompt => '封鎖1分鐘';

  @override
  String get durationTenMinutesTimeoutPrompt => '封鎖10分鐘';

  @override
  String get durationOneHourTimeoutPrompt => '封鎖1小時';

  @override
  String get durationSixHoursTimeoutPrompt => '封鎖6小時';

  @override
  String get durationOneDayTimeoutPrompt => '封鎖1天';

  @override
  String get durationTwoDaysTimeoutPrompt => '封鎖2天';

  @override
  String get durationOneWeekTimeoutPrompt => '封鎖1週';

  @override
  String get durationTwoWeeksTimeoutPrompt => '封鎖2週';

  @override
  String get errorFetchingViewerList => '我們無法獲取此頻道的觀眾列表';

  @override
  String get eventsTitle => '事件';

  @override
  String get followEventConfigTitle => '追隨事件';

  @override
  String get customizeYourFollowEvent => '自訂您的追隨事件';

  @override
  String get subscribeEventConfigTitle => '訂閱事件';

  @override
  String get customizeYourSubscriptionEvent => '自訂您的訂閱事件';

  @override
  String get cheerEventConfigTitle => '歡呼事件';

  @override
  String get customizeYourCheerEvent => '自訂您的歡呼事件';

  @override
  String get raidEventConfigTitle => '突襲事件';

  @override
  String get customizeYourRaidEvent => '自訂您的突襲事件';

  @override
  String get hostEventConfigTitle => '主持事件';

  @override
  String get customizeYourHostEvent => '自訂您的主持事件';

  @override
  String get hypetrainEventConfigTitle => '熱潮列車事件';

  @override
  String get customizeYourHypetrainEvent => '自訂您的熱潮列車事件';

  @override
  String get pollEventConfigTitle => '投票事件';

  @override
  String get customizeYourPollEvent => '自訂您的投票事件';

  @override
  String get predictionEventConfigTitle => '預測事件';

  @override
  String get customizeYourPredictionEvent => '自訂您的預測事件';

  @override
  String get channelPointRedemptionEventConfigTitle => '頻道點數兌換事件';

  @override
  String get customizeYourChannelPointRedemptionEvent => '自訂您的頻道點數兌換事件';

  @override
  String get outgoingRaidEventConfigTitle => '外發突襲事件';

  @override
  String get customizeYourOutgoingRaidEvent => '自訂您的外發突襲事件';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b> 正在進行突襲，帶著 <b>$viewerCountString</b> 位觀眾！';
  }

  @override
  String get shoutout => '大喊';

  @override
  String raidingEventRaiding(String displayName) {
    return '正在突襲 <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '剩餘 $secondsString 秒';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> 已經突襲！';
  }

  @override
  String get raidingEventJoin => '加入';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b> 的突襲已取消。';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> 已訂閱 $tier 級！';
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

    return '<b>$gifterUserName</b> 已贈送 $totalString 個 $tier 級訂閱，總計 $cumulativeTotalString 個！';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b> 已訂閱 $tier 級 $cumulativeMonthsString 個月！';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> 賞錢 <b>$value $currency</b>。';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return '匿名小費 <b>$value $currency</b>。';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> 在 StreamElements 上打賞了 <b>$formattedAmount</b>。';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> 在 Streamlabs 上打賞了 <b>$formattedAmount</b>。';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> 兌換了 <b>$rewardName</b>，花費了 <b>$rewardCostString</b> 點數。$userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> 兌換了 <b>$rewardName</b>，花費了 <b>$rewardCostString</b> 點數。';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> 歡呼了 <b>$bitsString</b> 點。$cheerMessage';
  }

  @override
  String get anonymous => '匿名';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> 正在主持，帶著 <b>$viewersString</b> 位觀眾。';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return '熱潮列車等級 <b>$level</b> 進行中！已完成 <b>$progressPercent%</b>！';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return '熱潮列車等級 <b>$levelString</b> 成功。';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return '熱潮列車等級 <b>$levelString</b> 失敗。';
  }

  @override
  String get sampleMessage => '这是文字转语音的信息示例。';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author 說：$text';
  }

  @override
  String get textToSpeechEnabled => '已启用文本转语音';

  @override
  String get textToSpeechDisabled => '已禁用文本转语音';
}
