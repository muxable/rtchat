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
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString，$timeString 上线';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString，$timeString 下线';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
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
    String displayName,
    String displayNameTwo,
    int numOthers,
  ) {
    final intl.NumberFormat numOthersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

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
    final intl.NumberFormat secondsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
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

    return '<b>$gifterUserName</b> 已赠送 $totalString 个第 $tier 层订阅，总计 $cumulativeTotalString 个！';
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

    return '<b>$subscriberUserName</b> 已订阅 $cumulativeMonthsString 个月的第 $tier 层！';
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

    return '<b>$subscriberUserName</b> 以等级 $tier 预付订阅了 $durationMonthsString 个月，累计 $cumulativeMonthsString 个月！';
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
  String channelPointRedemptionWithUserInput(
    String redeemerUsername,
    String rewardName,
    int rewardCost,
    String userInput,
  ) {
    final intl.NumberFormat rewardCostNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> 兑换了 <b>$rewardName</b>，花费了 <b>$rewardCostString</b> 点数。$userInput';
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

    return '<b>$redeemerUsername</b> 兑换了 <b>$rewardName</b>，花费了 <b>$rewardCostString</b> 点数。';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> 欢呼了 <b>$bitsString</b> 点。$cheerMessage';
  }

  @override
  String get anonymous => '匿名';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> 正在主持，带着 <b>$viewersString</b> 位观众。';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return '热潮列车等級 <b>$level</b> 進行中！已完成 <b>$progressPercent%</b>！';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return '热潮列车等級 <b>$levelString</b> 成功。';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return '热潮列车等級 <b>$levelString</b> 失敗。';
  }

  @override
  String get sampleMessage => '这是文字转语音的信息示例。';

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
  String get alertsEnabled => '仅提醒';

  @override
  String get pinDuration => '置顶时长';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds 秒',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分钟',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => '启用事件';

  @override
  String get showEventInChatHistory => '在聊天记录中显示事件';

  @override
  String get enableShoutouts => '启用推荐';

  @override
  String get enableShoutoutsSubtitle => '在聊天中发送突袭频道的链接';

  @override
  String get raidConfigurationTitle => '突袭设置';

  @override
  String get cheerConfigurationTitle => 'Cheer 设置';

  @override
  String get followConfigurationTitle => '关注设置';

  @override
  String get outgoingRaidConfigurationTitle => '发起突袭设置';

  @override
  String get hostConfigurationTitle => '托管设置';

  @override
  String get channelPointConfigurationTitle => '频道点数设置';

  @override
  String get pollConfigurationTitle => '投票设置';

  @override
  String get hypetrainConfigurationTitle => '热力列车设置';

  @override
  String get subscriptionConfigurationTitle => '订阅设置';

  @override
  String get predictionConfigurationTitle => '预测设置';

  @override
  String get unfulfilledRewardsPinDuration => '未兑现奖励的额外置顶时长';

  @override
  String get pollPinDuration => '结果确定后的置顶时长';

  @override
  String get hypetrainPinDuration => '热力列车结束后的置顶时长';

  @override
  String get enableGiftedSubscriptions => '启用单独显示赠送订阅';

  @override
  String get enableGiftedSubscriptionsSubtitle => '显示每一个赠送的订阅';

  @override
  String get settingsBackupTitle => '设置备份与恢复';

  @override
  String get cloudBackup => '云端备份';

  @override
  String get lastBackupNever => '上次备份：从未';

  @override
  String get backUp => '备份';

  @override
  String get restore => '恢复';

  @override
  String get localBackup => '本地备份';

  @override
  String get exportSettings => '导出';

  @override
  String get importSettings => '导入';

  @override
  String get showViewerAndFollowerCount => '显示观众和关注者数量';

  @override
  String get screenOrientation => '屏幕方向';

  @override
  String get appTheme => '应用主题';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get portrait => '竖屏';

  @override
  String get landscape => '横屏';

  @override
  String get lightTheme => '浅色';

  @override
  String get darkTheme => '深色';

  @override
  String get openSourceTitle => 'RealtimeChat 是开源的';

  @override
  String get openSourceSubtitle => '在 GitHub 上找到我们！';

  @override
  String get discordSubtitle => '加入 Muxable 的 Discord！';

  @override
  String get earlyTestersThanks => '感谢所有提交错误报告的早期测试者！';

  @override
  String get discoModeEnabled => '🕺 迪斯科模式已开启！:D';

  @override
  String get discoModeDisabled => '🕺 迪斯科模式已关闭 D:';

  @override
  String get playSampleMessage => '播放示例消息';

  @override
  String get textToSpeechRate => '语音速度';

  @override
  String get textToSpeechPitch => '语音音调';

  @override
  String get muteBots => '静音机器人的语音朗读';

  @override
  String get muteEmotes => '静音所有表情的语音朗读';

  @override
  String get muteViewerNames => '静音观众名字的语音朗读';

  @override
  String get subscribersOnly => '仅限订阅者';

  @override
  String get fontSize => '字体大小';

  @override
  String get usernameContrastBoost => '用户名对比度增强';

  @override
  String get twitchBadgeSettings => 'Twitch 徽章设置';

  @override
  String get twitchBadgeSettingsSubtitle => '控制显示哪些徽章';

  @override
  String get showDeletedMessages => '显示已删除的消息';

  @override
  String get deletedMessagesGreyedOut => '已删除的消息将显示为灰色';

  @override
  String get deletedMessagesRemoved => '已删除的消息将被移除';

  @override
  String get showLoginNames => '显示登录名';

  @override
  String get loginNamesShown => '当登录名与显示名称不同时显示登录名';

  @override
  String get loginNamesHidden => '登录名将被隐藏';

  @override
  String get compactMessages => '精简消息';

  @override
  String get dontCompactMessages => '不精简消息';

  @override
  String get dontCompactMessagesSubtitle => '消息按原样显示';

  @override
  String get compactIndividualMessages => '精简单条消息';

  @override
  String get compactIndividualMessagesSubtitle => '消息中的重复文字将被缩短';

  @override
  String get announcementPinDuration => '公告置顶时长';

  @override
  String get idleMessageAlertDuration => '聊天空闲提醒时长';

  @override
  String get idleMessageAlertDurationSubtitle =>
      '如果在这段时间内没有消息，之后又收到新消息，将播放提示音。';

  @override
  String get realtimeCashSubtitle => '连接 ETH 或 MATIC 钱包';

  @override
  String get walletAddress => '钱包地址';

  @override
  String get streamlabsSubtitle => '查看你的 Streamlabs 捐赠';

  @override
  String get streamElementsSubtitle => '查看你的 StreamElements 捐赠';

  @override
  String get thirdPartyAuthError => '嗯，没有成功。再试一次，或者在 Discord 上提问？';

  @override
  String get companionAuthBrowserTooOld =>
      '你的浏览器版本过旧，无法直接登录。请用手机扫描此二维码，在其他设备上登录。';

  @override
  String get companionAuthScanQrCode => '请用手机扫描此二维码，在其他设备上登录。';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> 订阅了！';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> 续订了 $monthsString 个月！';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> 赠送了 $countString 个订阅！';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> 送出了 $amountString Kicks！';
  }

  @override
  String get signInWithKick => '使用 Kick 登录';

  @override
  String get textToSpeechTooManyMessages => '消息太多了。文字转语音已关闭';

  @override
  String get turnOffTextToSpeech => '关闭';

  @override
  String get addToChat => '添加到聊天';

  @override
  String get inChat => '聊天中';

  @override
  String get removeFromChat => '从聊天中移除';

  @override
  String cantChatWithAccount(String provider) {
    return '你的 $provider 账号无法在此聊天';
  }

  @override
  String get cantChatWithAccounts => '你的账号无法在此聊天';

  @override
  String sendAMessageTo(String channel) {
    return '向 $channel 发送消息...';
  }

  @override
  String replaceChannel(String channel) {
    return '替换 $channel';
  }

  @override
  String get voicePacks => '语音包';

  @override
  String get voicePacksDescription =>
      '语音包使用自然的声音朗读聊天内容，在你的设备上运行，下载后可离线使用。这些声音由 AI 生成，并非真人录制。';

  @override
  String voicePackDetails(int voices, String size) {
    return '$voices 种声音 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    return '$count 种语言：$languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      '此模型的许可证（OpenRAIL-M）禁止冒充他人或传播虚假信息等有害用途。这些限制也适用于你。';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return '删除 $pack？这将释放 $size 空间。';
  }

  @override
  String get voicePackDownload => '下载';

  @override
  String get voicePackUpdate => '更新';

  @override
  String get voicePackWaitingForWifi => '等待 Wi-Fi 连接';

  @override
  String get voicePackUseMobileData => '使用移动数据';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return '正在下载：$downloaded / $total';
  }

  @override
  String get voicePackInstalling => '正在安装';

  @override
  String voicePackInstallFailed(String pack) {
    return '无法安装 $pack。请检查网络连接并重试。';
  }

  @override
  String get voices => '声音';

  @override
  String get perViewerVoice => '为每位观众分配声音';

  @override
  String get perViewerVoiceSubtitle =>
      '每位观众都有独立的声音。你选择的声音用于朗读提醒；关闭此选项时，它会朗读所有内容。';

  @override
  String get streamLanguage => '直播语言';

  @override
  String get ttsEngineNeural => '神经网络语音（设备端）';

  @override
  String get ttsEngineSystem => '系统语音';

  @override
  String languageUnsupported(String language) {
    return '你的语音包不支持$language，将使用系统语音';
  }

  @override
  String get neuralFallbackLowMemory => '此设备没有足够的内存运行神经网络语音，因此将使用系统语音朗读聊天内容。';

  @override
  String get neuralFallbackLoadFailed => '无法加载神经网络语音，因此将使用系统语音朗读聊天内容。';

  @override
  String get accounts => '账号';

  @override
  String get accountsSubtitle => '登录你直播所用的各个平台';

  @override
  String addProviderAccount(String provider) {
    return '添加 $provider 账号';
  }

  @override
  String signInWithProvider(String provider) {
    return '使用 $provider 登录';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return '退出 $provider 上的 $channel 账号？';
  }

  @override
  String get signOutOfAll => '退出所有账号';
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
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '自 $dateString $timeString 開始直播';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '自 $dateString $timeString 結束直播';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
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
    String displayName,
    String displayNameTwo,
    int numOthers,
  ) {
    final intl.NumberFormat numOthersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

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
    final intl.NumberFormat secondsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
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

    return '<b>$gifterUserName</b> 已贈送 $totalString 個 $tier 級訂閱，總計 $cumulativeTotalString 個！';
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

    return '<b>$subscriberUserName</b> 已訂閱 $tier 級 $cumulativeMonthsString 個月！';
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

    return '<b>$subscriberUserName</b> 以層級 $tier 預付訂閱了 $durationMonthsString 個月，累計 $cumulativeMonthsString 個月！';
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
  String channelPointRedemptionWithUserInput(
    String redeemerUsername,
    String rewardName,
    int rewardCost,
    String userInput,
  ) {
    final intl.NumberFormat rewardCostNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b> 兌換了 <b>$rewardName</b>，花費了 <b>$rewardCostString</b> 點數。$userInput';
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

    return '<b>$redeemerUsername</b> 兌換了 <b>$rewardName</b>，花費了 <b>$rewardCostString</b> 點數。';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> 歡呼了 <b>$bitsString</b> 點。$cheerMessage';
  }

  @override
  String get anonymous => '匿名';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> 正在主持，帶著 <b>$viewersString</b> 位觀眾。';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return '熱潮列車等級 <b>$level</b> 進行中！已完成 <b>$progressPercent%</b>！';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return '熱潮列車等級 <b>$levelString</b> 成功。';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return '熱潮列車等級 <b>$levelString</b> 失敗。';
  }

  @override
  String get sampleMessage => '這是文字轉語音的訊息範例。';

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

  @override
  String get alertsEnabled => '僅提醒';

  @override
  String get pinDuration => '置頂時長';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds 秒',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分鐘',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => '啟用事件';

  @override
  String get showEventInChatHistory => '在聊天記錄中顯示事件';

  @override
  String get enableShoutouts => '啟用推薦';

  @override
  String get enableShoutoutsSubtitle => '在聊天中傳送突襲頻道的連結';

  @override
  String get raidConfigurationTitle => '突襲設定';

  @override
  String get cheerConfigurationTitle => 'Cheer 設定';

  @override
  String get followConfigurationTitle => '追隨設定';

  @override
  String get outgoingRaidConfigurationTitle => '發起突襲設定';

  @override
  String get hostConfigurationTitle => '主持設定';

  @override
  String get channelPointConfigurationTitle => '頻道點數設定';

  @override
  String get pollConfigurationTitle => '投票設定';

  @override
  String get hypetrainConfigurationTitle => '熱力列車設定';

  @override
  String get subscriptionConfigurationTitle => '訂閱設定';

  @override
  String get predictionConfigurationTitle => '預測設定';

  @override
  String get unfulfilledRewardsPinDuration => '未兌現獎勵的額外置頂時長';

  @override
  String get pollPinDuration => '結果確定後的置頂時長';

  @override
  String get hypetrainPinDuration => '熱力列車結束後的置頂時長';

  @override
  String get enableGiftedSubscriptions => '啟用個別顯示贈送訂閱';

  @override
  String get enableGiftedSubscriptionsSubtitle => '顯示每一個贈送的訂閱';

  @override
  String get settingsBackupTitle => '設定備份與還原';

  @override
  String get cloudBackup => '雲端備份';

  @override
  String get lastBackupNever => '上次備份：從未';

  @override
  String get backUp => '備份';

  @override
  String get restore => '還原';

  @override
  String get localBackup => '本機備份';

  @override
  String get exportSettings => '匯出';

  @override
  String get importSettings => '匯入';

  @override
  String get showViewerAndFollowerCount => '顯示觀眾與追隨者人數';

  @override
  String get screenOrientation => '螢幕方向';

  @override
  String get appTheme => '應用程式主題';

  @override
  String get systemDefault => '跟隨系統';

  @override
  String get portrait => '直向';

  @override
  String get landscape => '橫向';

  @override
  String get lightTheme => '淺色';

  @override
  String get darkTheme => '深色';

  @override
  String get openSourceTitle => 'RealtimeChat 是開源的';

  @override
  String get openSourceSubtitle => '在 GitHub 上找到我們！';

  @override
  String get discordSubtitle => '加入 Muxable 的 Discord！';

  @override
  String get earlyTestersThanks => '感謝所有回報錯誤的早期測試者！';

  @override
  String get discoModeEnabled => '🕺 迪斯可模式已開啟！:D';

  @override
  String get discoModeDisabled => '🕺 迪斯可模式已關閉 D:';

  @override
  String get playSampleMessage => '播放範例訊息';

  @override
  String get textToSpeechRate => '語音速度';

  @override
  String get textToSpeechPitch => '語音音調';

  @override
  String get muteBots => '靜音機器人的語音朗讀';

  @override
  String get muteEmotes => '靜音所有表情符號的語音朗讀';

  @override
  String get muteViewerNames => '靜音觀眾名稱的語音朗讀';

  @override
  String get subscribersOnly => '僅限訂閱者';

  @override
  String get fontSize => '字型大小';

  @override
  String get usernameContrastBoost => '使用者名稱對比度增強';

  @override
  String get twitchBadgeSettings => 'Twitch 徽章設定';

  @override
  String get twitchBadgeSettingsSubtitle => '控制要顯示哪些徽章';

  @override
  String get showDeletedMessages => '顯示已刪除的訊息';

  @override
  String get deletedMessagesGreyedOut => '已刪除的訊息將顯示為灰色';

  @override
  String get deletedMessagesRemoved => '已刪除的訊息將被移除';

  @override
  String get showLoginNames => '顯示登入名稱';

  @override
  String get loginNamesShown => '當登入名稱與顯示名稱不同時顯示登入名稱';

  @override
  String get loginNamesHidden => '登入名稱將被隱藏';

  @override
  String get compactMessages => '精簡訊息';

  @override
  String get dontCompactMessages => '不精簡訊息';

  @override
  String get dontCompactMessagesSubtitle => '訊息按原樣顯示';

  @override
  String get compactIndividualMessages => '精簡單則訊息';

  @override
  String get compactIndividualMessagesSubtitle => '訊息中的重複文字將被縮短';

  @override
  String get announcementPinDuration => '公告置頂時長';

  @override
  String get idleMessageAlertDuration => '聊天閒置提醒時長';

  @override
  String get idleMessageAlertDurationSubtitle =>
      '如果在這段時間內沒有訊息，之後又收到新訊息，將播放提示音。';

  @override
  String get realtimeCashSubtitle => '連結 ETH 或 MATIC 錢包';

  @override
  String get walletAddress => '錢包地址';

  @override
  String get streamlabsSubtitle => '查看你的 Streamlabs 斗內';

  @override
  String get streamElementsSubtitle => '查看你的 StreamElements 斗內';

  @override
  String get thirdPartyAuthError => '嗯，沒有成功。再試一次，或在 Discord 上提問？';

  @override
  String get companionAuthBrowserTooOld =>
      '你的瀏覽器版本過舊，無法直接登入。請用手機掃描此 QR 碼，在其他裝置上登入。';

  @override
  String get companionAuthScanQrCode => '請用手機掃描此 QR 碼，在其他裝置上登入。';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> 訂閱了！';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> 續訂了 $monthsString 個月！';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> 贈送了 $countString 個訂閱！';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> 送出了 $amountString Kicks！';
  }

  @override
  String get signInWithKick => '使用 Kick 登入';

  @override
  String get textToSpeechTooManyMessages => '訊息太多了。文字轉語音已關閉';

  @override
  String get turnOffTextToSpeech => '關閉';

  @override
  String get addToChat => '新增至聊天';

  @override
  String get inChat => '聊天中';

  @override
  String get removeFromChat => '從聊天中移除';

  @override
  String cantChatWithAccount(String provider) {
    return '你的 $provider 帳號無法在此聊天';
  }

  @override
  String get cantChatWithAccounts => '你的帳號無法在此聊天';

  @override
  String sendAMessageTo(String channel) {
    return '傳送訊息至 $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return '替換 $channel';
  }

  @override
  String get voicePacks => '語音包';

  @override
  String get voicePacksDescription =>
      '語音包使用自然的聲音朗讀聊天內容，在你的裝置上執行，下載後可離線使用。這些聲音由 AI 產生，並非真人錄製。';

  @override
  String voicePackDetails(int voices, String size) {
    return '$voices 種聲音 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    return '$count 種語言：$languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      '此模型的授權條款（OpenRAIL-M）禁止冒充他人或散播假訊息等有害用途。這些限制也適用於你。';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return '刪除 $pack？這將釋放 $size 空間。';
  }

  @override
  String get voicePackDownload => '下載';

  @override
  String get voicePackUpdate => '更新';

  @override
  String get voicePackWaitingForWifi => '等待 Wi-Fi 連線';

  @override
  String get voicePackUseMobileData => '使用行動數據';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return '下載中：$downloaded / $total';
  }

  @override
  String get voicePackInstalling => '安裝中';

  @override
  String voicePackInstallFailed(String pack) {
    return '無法安裝 $pack。請檢查網路連線後再試一次。';
  }

  @override
  String get voices => '聲音';

  @override
  String get perViewerVoice => '為每位觀眾分配聲音';

  @override
  String get perViewerVoiceSubtitle =>
      '每位觀眾都有獨立的聲音。你選擇的聲音用於朗讀通知；關閉此選項時，它會朗讀所有內容。';

  @override
  String get streamLanguage => '直播語言';

  @override
  String get ttsEngineNeural => '神經網路語音（裝置端）';

  @override
  String get ttsEngineSystem => '系統語音';

  @override
  String languageUnsupported(String language) {
    return '你的語音包不支援$language，將使用系統語音';
  }

  @override
  String get neuralFallbackLowMemory => '此裝置沒有足夠的記憶體執行神經網路語音，因此將使用系統語音朗讀聊天內容。';

  @override
  String get neuralFallbackLoadFailed => '無法載入神經網路語音，因此將使用系統語音朗讀聊天內容。';

  @override
  String get accounts => '帳號';

  @override
  String get accountsSubtitle => '登入你直播所用的各個平台';

  @override
  String addProviderAccount(String provider) {
    return '新增 $provider 帳號';
  }

  @override
  String signInWithProvider(String provider) {
    return '使用 $provider 登入';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return '登出 $provider 上的 $channel 帳號？';
  }

  @override
  String get signOutOfAll => '登出所有帳號';
}
