// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'package:rtchat/l10n/app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get sendAMessage => 'Gửi tin nhắn...';

  @override
  String get writeSomething => 'Viết gì đó...';

  @override
  String get speakToTheCrowds => 'Trò chuyện với đám đông...';

  @override
  String get shareYourThoughts => 'Chia sẻ suy nghĩ của bạn...';

  @override
  String get saySomethingYouLittleBitch => 'Nói gì đi chứ, đồ nhãi ranh...';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get notSignedIn => 'Chưa đăng nhập';

  @override
  String get searchChannels => 'Tìm kiếm';

  @override
  String get raidAChannel => 'Raid kênh';

  @override
  String get noMessagesEmptyState => 'Ở đây yên ắng quá.';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tin nhắn mới',
      one: '1 tin nhắn mới',
      zero: 'Không có tin nhắn mới',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Đăng nhập bằng Twitch';

  @override
  String get signInError => 'Đã xảy ra lỗi khi đăng nhập. Vui lòng thử lại.';

  @override
  String get continueAsGuest => 'Tiếp tục với tư cách Khách';

  @override
  String get signInToSendMessages => 'Đăng nhập để gửi tin nhắn';

  @override
  String get currentViewers => 'Người xem hiện tại';

  @override
  String get textToSpeech => 'Chuyển văn bản thành giọng nói';

  @override
  String get streamPreview => 'Xem trước luồng phát';

  @override
  String get activityFeed => 'Bảng hoạt động';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Luồng phát trực tuyến lúc $dateString, $timeString';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Luồng phát ngoại tuyến lúc $dateString, $timeString';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMEEEEd(
      localeName,
    );
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Đã xóa trò chuyện lúc $dateString, $timeString';
  }

  @override
  String get configureQuickLinks => 'Cấu hình liên kết nhanh';

  @override
  String get disableRainMode => 'Tắt chế độ đi mưa';

  @override
  String get enableRainMode => 'Bật chế độ đi mưa';

  @override
  String get disableRainModeSubtitle => 'Sẽ bật tương tác';

  @override
  String get enableRainModeSubtitle => 'Sẽ tắt tương tác';

  @override
  String get refreshAudioSources => 'Làm mới nguồn âm thanh';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã làm mới $count nguồn âm thanh',
      one: 'Đã làm mới 1 nguồn âm thanh',
      zero: 'Không có nguồn âm thanh nào được làm mới',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Cài đặt';

  @override
  String get signOut => 'Đăng xuất';

  @override
  String get cancel => 'Hủy';

  @override
  String get signOutConfirmation => 'Bạn có chắc chắn muốn đăng xuất không?';

  @override
  String get broadcaster => 'Người phát sóng';

  @override
  String get moderators => 'Người điều hành';

  @override
  String get viewers => 'Người xem';

  @override
  String get communityVips => 'VIP của cộng đồng';

  @override
  String get searchViewers => 'Tìm kiếm người xem';

  @override
  String get reconnecting => 'Đang kết nối lại...';

  @override
  String get twitchBadges => 'Huy hiệu Twitch';

  @override
  String get selectAll => 'Chọn tất cả';

  @override
  String get quickLinks => 'Liên kết nhanh';

  @override
  String get swipeToDeleteQuickLinks =>
      'Vuốt sang trái hoặc phải để xóa liên kết nhanh';

  @override
  String get quickLinksLabelHint => 'Nhãn';

  @override
  String get invalidUrlErrorText => 'Đây có vẻ không phải là một URL hợp lệ';

  @override
  String get duplicateUrlErrorText => 'Liên kết này đã tồn tại';

  @override
  String get or => 'hoặc';

  @override
  String get clearCookies => 'Xóa cookie';

  @override
  String get disabled => 'Đã tắt';

  @override
  String get twitchActivityFeed => 'Bảng hoạt động Twitch';

  @override
  String get signInToEnable => 'Bạn phải đăng nhập để bật tính năng này';

  @override
  String get customUrl => 'URL tùy chỉnh';

  @override
  String get preview => 'Xem trước';

  @override
  String get audioSources => 'Nguồn âm thanh';

  @override
  String get enableOffStreamSwitchTitle =>
      'Bật khi không phát sóng (tốn pin hơn)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle =>
      'Âm thanh vẫn sẽ phát ngay cả khi bạn ngoại tuyến';

  @override
  String get enableOffStreamSwitchDisabledSubtitle =>
      'Âm thanh chỉ phát khi bạn đang phát trực tiếp';

  @override
  String get iosOggWarningTitle => 'Này! Chú ý nhé!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS không hỗ trợ tệp phương tiện *.ogg, vốn là định dạng mặc định trên Streamlabs. Hãy đảm bảo nguồn âm thanh của bạn sử dụng định dạng khác, nếu không chúng sẽ không phát được.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => 'Tùy chỉnh bảng hoạt động của bạn';

  @override
  String get audioSourcesSubtitle => 'Thêm nguồn web cho âm thanh thông báo';

  @override
  String get quickLinksSubtitle => 'Thêm lối tắt đến các công cụ thường dùng';

  @override
  String get chatHistory => 'Lịch sử trò chuyện';

  @override
  String get chatHistorySubtitle => 'Thay đổi giao diện trò chuyện';

  @override
  String get textToSpeechSubtitle =>
      'Thay đổi cài đặt chuyển văn bản thành giọng nói';

  @override
  String get events => 'Sự kiện';

  @override
  String get eventsSubtitle => 'Cấu hình sự kiện Twitch';

  @override
  String get thirdPartyServices => 'Dịch vụ bên thứ ba';

  @override
  String get thirdPartyServicesSubtitle => 'Kết nối với dịch vụ bên thứ ba';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b> đang theo dõi bạn';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b> và <b>$displayNameTwo</b> đang theo dõi bạn';
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

    return '<b>$displayName</b>, <b>$displayNameTwo</b> và $numOthersString người khác đang theo dõi bạn';
  }

  @override
  String unmuteUser(String displayName) {
    return 'Bỏ tắt tiếng $displayName';
  }

  @override
  String muteUser(String displayName) {
    return 'Tắt tiếng $displayName';
  }

  @override
  String timeoutUser(String displayName) {
    return 'Tạm cấm $displayName';
  }

  @override
  String banUser(String displayName) {
    return 'Cấm $displayName';
  }

  @override
  String unbanUser(String displayName) {
    return 'Bỏ cấm $displayName';
  }

  @override
  String viewProfile(String displayName) {
    return 'Xem hồ sơ của $displayName';
  }

  @override
  String get copyMessage => 'Sao chép tin nhắn';

  @override
  String get deleteMessage => 'Xóa tin nhắn';

  @override
  String get longScrollNotification =>
      'Bạn cuộn hơi bị xa rồi đấy, có thấy vậy không?';

  @override
  String get stfu => 'câm mồm';

  @override
  String get globalEmotes => 'Biểu cảm chung';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString người theo dõi',
      one: '1 người theo dõi',
      zero: '0 người theo dõi',
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
      other: '$countString người xem',
      one: '1 người xem',
      zero: '0 người xem',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      'Chào bạn! Rất vui vì bạn thích dùng tính năng xem trước luồng phát, nhưng lưu ý là nó khá tốn pin đấy. Đọc trò chuyện mà không bật xem trước sẽ giúp kéo dài thời lượng pin của bạn.';

  @override
  String get okay => 'OK';

  @override
  String get streamPreviewLoading =>
      'Đang tải (hoặc luồng phát đang ngoại tuyến)...';

  @override
  String get copiedToClipboard => 'Đã sao chép vào bộ nhớ tạm';

  @override
  String get audioSourcesRequirePermissions => 'Nguồn âm thanh cần cấp quyền';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      'Cấp quyền cho RealtimeChat hiển thị trên các ứng dụng khác để sử dụng nguồn âm thanh.';

  @override
  String get audioSourcesRemoveButton => 'Xóa nguồn âm thanh';

  @override
  String get audioSourcesOpenSettingsButton => 'Mở cài đặt';

  @override
  String get flashOn => 'Bật đèn flash';

  @override
  String get flashOff => 'Tắt đèn flash';

  @override
  String get durationOneSecond => '1 giây';

  @override
  String get durationOneMinute => '1 phút';

  @override
  String get durationTenMinutes => '10 phút';

  @override
  String get durationOneHour => '1 giờ';

  @override
  String get durationSixHours => '6 giờ';

  @override
  String get durationOneDay => '1 ngày';

  @override
  String get durationTwoDays => '2 ngày';

  @override
  String get durationOneWeek => '1 tuần';

  @override
  String get durationTwoWeeks => '2 tuần';

  @override
  String get durationOneSecondTimeoutPrompt => 'Tạm cấm trong 1 giây';

  @override
  String get durationOneMinuteTimeoutPrompt => 'Tạm cấm trong 1 phút';

  @override
  String get durationTenMinutesTimeoutPrompt => 'Tạm cấm trong 10 phút';

  @override
  String get durationOneHourTimeoutPrompt => 'Tạm cấm trong 1 giờ';

  @override
  String get durationSixHoursTimeoutPrompt => 'Tạm cấm trong 6 giờ';

  @override
  String get durationOneDayTimeoutPrompt => 'Tạm cấm trong 1 ngày';

  @override
  String get durationTwoDaysTimeoutPrompt => 'Tạm cấm trong 2 ngày';

  @override
  String get durationOneWeekTimeoutPrompt => 'Tạm cấm trong 1 tuần';

  @override
  String get durationTwoWeeksTimeoutPrompt => 'Tạm cấm trong 2 tuần';

  @override
  String get errorFetchingViewerList =>
      'Chúng tôi không thể tải danh sách người xem cho kênh này';

  @override
  String get eventsTitle => 'Sự kiện';

  @override
  String get followEventConfigTitle => 'Sự kiện theo dõi';

  @override
  String get customizeYourFollowEvent => 'Tùy chỉnh sự kiện theo dõi của bạn';

  @override
  String get subscribeEventConfigTitle => 'Sự kiện đăng ký theo dõi';

  @override
  String get customizeYourSubscriptionEvent =>
      'Tùy chỉnh sự kiện đăng ký theo dõi của bạn';

  @override
  String get cheerEventConfigTitle => 'Sự kiện cổ vũ';

  @override
  String get customizeYourCheerEvent => 'Tùy chỉnh sự kiện cổ vũ của bạn';

  @override
  String get raidEventConfigTitle => 'Sự kiện Raid';

  @override
  String get customizeYourRaidEvent => 'Tùy chỉnh sự kiện Raid của bạn';

  @override
  String get hostEventConfigTitle => 'Sự kiện Host';

  @override
  String get customizeYourHostEvent => 'Tùy chỉnh sự kiện Host của bạn';

  @override
  String get hypetrainEventConfigTitle => 'Sự kiện Hype Train';

  @override
  String get customizeYourHypetrainEvent =>
      'Tùy chỉnh sự kiện Hype Train của bạn';

  @override
  String get pollEventConfigTitle => 'Sự kiện bình chọn';

  @override
  String get customizeYourPollEvent => 'Tùy chỉnh sự kiện bình chọn của bạn';

  @override
  String get predictionEventConfigTitle => 'Sự kiện dự đoán';

  @override
  String get customizeYourPredictionEvent =>
      'Tùy chỉnh sự kiện dự đoán của bạn';

  @override
  String get channelPointRedemptionEventConfigTitle => 'Sự kiện đổi điểm kênh';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      'Tùy chỉnh sự kiện đổi điểm kênh của bạn';

  @override
  String get outgoingRaidEventConfigTitle => 'Sự kiện Raid đi';

  @override
  String get customizeYourOutgoingRaidEvent =>
      'Tùy chỉnh sự kiện Raid đi của bạn';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewerCountString = viewerCountNumberFormat.format(
      viewerCount,
    );

    return '<b>$displayName</b> đang raid cùng với <b>$viewerCountString</b> người xem!';
  }

  @override
  String get shoutout => 'Giới thiệu kênh';

  @override
  String raidingEventRaiding(String displayName) {
    return 'Đang raid <b>$displayName</b>...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString giây';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b> đã raid!';
  }

  @override
  String get raidingEventJoin => 'Tham gia';

  @override
  String raidingEventCanceled(String displayName) {
    return 'Đã hủy lượt raid <b>$displayName</b>.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b> đã đăng ký gói Cấp $tier!';
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

    return '<b>$gifterUserName</b> đã tặng $totalString gói đăng ký Cấp $tier, tổng cộng $cumulativeTotalString gói!';
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

    return '<b>$subscriberUserName</b> đã đăng ký gói Cấp $tier trong $cumulativeMonthsString tháng!';
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

    return '<b>$subscriberUserName</b> đã đăng ký trước gói Cấp $tier trong $durationMonthsString tháng, tổng cộng $cumulativeMonthsString tháng!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> đã ủng hộ <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return 'Người ẩn danh đã ủng hộ <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> đã ủng hộ <b>$formattedAmount</b> trên StreamElements.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b> đã ủng hộ <b>$formattedAmount</b> trên Streamlabs.';
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

    return '<b>$redeemerUsername</b> đã đổi <b>$rewardName</b> với giá <b>$rewardCostString</b> điểm. $userInput';
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

    return '<b>$redeemerUsername</b> đã đổi <b>$rewardName</b> với giá <b>$rewardCostString</b> điểm.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b> đã cổ vũ <b>$bitsString</b> bit. $cheerMessage';
  }

  @override
  String get anonymous => 'Ẩn danh';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b> đang host cùng nhóm <b>$viewersString</b> người xem.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return 'Hype Train cấp <b>$level</b> đang diễn ra! Đã hoàn thành <b>$progressPercent%</b>!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train cấp <b>$levelString</b> đã thành công.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return 'Hype Train cấp <b>$levelString</b> đã thất bại.';
  }

  @override
  String get sampleMessage =>
      'Đây là tin nhắn mẫu để chuyển văn bản thành giọng nói.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author nói: $text';
  }

  @override
  String get textToSpeechEnabled => 'Đã bật chuyển văn bản thành giọng nói';

  @override
  String get textToSpeechDisabled => 'Đã tắt chuyển văn bản thành giọng nói';

  @override
  String get alertsEnabled => 'Chỉ thông báo';

  @override
  String get pinDuration => 'Thời lượng ghim';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds giây',
      one: '1 giây',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes phút',
      one: '1 phút',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => 'Bật sự kiện';

  @override
  String get showEventInChatHistory =>
      'Hiển thị sự kiện trong lịch sử trò chuyện';

  @override
  String get enableShoutouts => 'Bật giới thiệu kênh';

  @override
  String get enableShoutoutsSubtitle =>
      'Gửi liên kết của kênh đang raid vào cuộc trò chuyện';

  @override
  String get raidConfigurationTitle => 'Cấu hình Raid';

  @override
  String get cheerConfigurationTitle => 'Cấu hình cổ vũ';

  @override
  String get followConfigurationTitle => 'Cấu hình theo dõi';

  @override
  String get outgoingRaidConfigurationTitle => 'Cấu hình Raid đi';

  @override
  String get hostConfigurationTitle => 'Cấu hình Host';

  @override
  String get channelPointConfigurationTitle => 'Cấu hình điểm kênh';

  @override
  String get pollConfigurationTitle => 'Cấu hình bình chọn';

  @override
  String get hypetrainConfigurationTitle => 'Cấu hình Hype Train';

  @override
  String get subscriptionConfigurationTitle => 'Cấu hình đăng ký theo dõi';

  @override
  String get predictionConfigurationTitle => 'Cấu hình dự đoán';

  @override
  String get unfulfilledRewardsPinDuration =>
      'Thời lượng ghim bổ sung cho phần thưởng chưa hoàn thành';

  @override
  String get pollPinDuration => 'Thời lượng ghim sau khi có kết quả cuối cùng';

  @override
  String get hypetrainPinDuration =>
      'Thời lượng ghim sau khi Hype Train kết thúc';

  @override
  String get enableGiftedSubscriptions =>
      'Bật hiển thị từng gói đăng ký được tặng';

  @override
  String get enableGiftedSubscriptionsSubtitle =>
      'Hiển thị mọi gói đăng ký được tặng';

  @override
  String get settingsBackupTitle => 'Sao lưu và khôi phục cài đặt';

  @override
  String get cloudBackup => 'Sao lưu đám mây';

  @override
  String get lastBackupNever => 'Lần sao lưu cuối: chưa từng';

  @override
  String get backUp => 'Sao lưu';

  @override
  String get restore => 'Khôi phục';

  @override
  String get localBackup => 'Sao lưu cục bộ';

  @override
  String get exportSettings => 'Xuất';

  @override
  String get importSettings => 'Nhập';

  @override
  String get showViewerAndFollowerCount =>
      'Hiển thị số người xem và người theo dõi';

  @override
  String get screenOrientation => 'Hướng màn hình';

  @override
  String get appTheme => 'Giao diện ứng dụng';

  @override
  String get systemDefault => 'Hệ thống';

  @override
  String get portrait => 'Dọc';

  @override
  String get landscape => 'Ngang';

  @override
  String get lightTheme => 'Sáng';

  @override
  String get darkTheme => 'Tối';

  @override
  String get openSourceTitle => 'RealtimeChat là mã nguồn mở';

  @override
  String get openSourceSubtitle => 'Tìm chúng tôi trên GitHub!';

  @override
  String get discordSubtitle => 'Tham gia Discord của Muxable!';

  @override
  String get earlyTestersThanks =>
      'Cảm ơn tất cả những người thử nghiệm đầu tiên đã gửi báo cáo lỗi!';

  @override
  String get discoModeEnabled => '🕺 Đã bật chế độ vũ trường! :D';

  @override
  String get discoModeDisabled => '🕺 Đã tắt chế độ vũ trường D:';

  @override
  String get playSampleMessage => 'Phát tin nhắn mẫu';

  @override
  String get textToSpeechRate => 'Tốc độ đọc văn bản';

  @override
  String get textToSpeechPitch => 'Cao độ giọng đọc';

  @override
  String get muteBots => 'Tắt đọc văn bản đối với bot';

  @override
  String get muteEmotes => 'Tắt đọc tất cả biểu cảm';

  @override
  String get muteViewerNames => 'Tắt đọc tên người xem';

  @override
  String get subscribersOnly => 'Chỉ người đăng ký theo dõi';

  @override
  String get fontSize => 'Cỡ chữ';

  @override
  String get usernameContrastBoost => 'Tăng độ tương phản tên người dùng';

  @override
  String get twitchBadgeSettings => 'Cài đặt huy hiệu Twitch';

  @override
  String get twitchBadgeSettingsSubtitle =>
      'Kiểm soát những huy hiệu nào được hiển thị';

  @override
  String get showDeletedMessages => 'Hiển thị tin nhắn đã xóa';

  @override
  String get deletedMessagesGreyedOut =>
      'Tin nhắn đã xóa sẽ bị làm mờ thành màu xám';

  @override
  String get deletedMessagesRemoved => 'Tin nhắn đã xóa sẽ bị gỡ bỏ';

  @override
  String get showLoginNames => 'Hiển thị tên đăng nhập';

  @override
  String get loginNamesShown =>
      'Tên đăng nhập sẽ hiển thị nếu khác với tên hiển thị';

  @override
  String get loginNamesHidden => 'Tên đăng nhập sẽ bị ẩn';

  @override
  String get compactMessages => 'Thu gọn tin nhắn';

  @override
  String get dontCompactMessages => 'Không thu gọn tin nhắn';

  @override
  String get dontCompactMessagesSubtitle => 'Tin nhắn được hiển thị nguyên vẹn';

  @override
  String get compactIndividualMessages => 'Thu gọn từng tin nhắn';

  @override
  String get compactIndividualMessagesSubtitle =>
      'Văn bản lặp lại trong tin nhắn sẽ được rút gọn';

  @override
  String get announcementPinDuration => 'Thời lượng ghim thông báo';

  @override
  String get idleMessageAlertDuration => 'Thời gian chờ cảnh báo tin nhắn mới';

  @override
  String get idleMessageAlertDurationSubtitle =>
      'Nếu không có tin nhắn nào trong khoảng thời gian này và có tin nhắn mới đến, âm thanh thông báo sẽ phát lên.';

  @override
  String get realtimeCashSubtitle => 'Kết nối ví ETH hoặc MATIC';

  @override
  String get walletAddress => 'Địa chỉ ví';

  @override
  String get streamlabsSubtitle => 'Xem khoản ủng hộ Streamlabs của bạn';

  @override
  String get streamElementsSubtitle =>
      'Xem khoản ủng hộ StreamElements của bạn';

  @override
  String get thirdPartyAuthError =>
      'Hmm, không được rồi. Hãy thử lại hoặc hỏi trên Discord nhé?';

  @override
  String get companionAuthBrowserTooOld =>
      'Trình duyệt của bạn quá cũ nên không hỗ trợ đăng nhập trực tiếp. Hãy quét mã QR này bằng điện thoại để đăng nhập trên thiết bị khác.';

  @override
  String get companionAuthScanQrCode =>
      'Quét mã QR này bằng điện thoại để đăng nhập trên thiết bị khác.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b> đã đăng ký theo dõi!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b> đã đăng ký lại trong $monthsString tháng!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b> đã tặng $countString gói đăng ký!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b> đã gửi $amountString Kicks!';
  }

  @override
  String get signInWithKick => 'Đăng nhập bằng Kick';

  @override
  String get textToSpeechTooManyMessages =>
      'Có quá nhiều tin nhắn. Đã tắt chuyển văn bản thành giọng nói';

  @override
  String get turnOffTextToSpeech => 'Tắt';

  @override
  String get addToChat => 'Thêm vào trò chuyện';

  @override
  String get inChat => 'Trong trò chuyện';

  @override
  String get removeFromChat => 'Xóa khỏi trò chuyện';

  @override
  String cantChatWithAccount(String provider) {
    return 'Tài khoản $provider của bạn không thể trò chuyện tại đây';
  }

  @override
  String get cantChatWithAccounts =>
      'Các tài khoản của bạn không thể trò chuyện tại đây';

  @override
  String sendAMessageTo(String channel) {
    return 'Gửi tin nhắn tới $channel...';
  }

  @override
  String replaceChannel(String channel) {
    return 'Thay thế $channel';
  }

  @override
  String get voicePacks => 'Gói giọng nói';

  @override
  String get voicePacksDescription =>
      'Gói giọng nói đọc nội dung trò chuyện bằng giọng đọc tự nhiên chạy ngay trên thiết bị của bạn, hoạt động ngoại tuyến sau khi tải xuống. Các giọng nói này do AI tạo tự động, không phải do người thật thu âm.';

  @override
  String voicePackDetails(int voices, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      voices,
      locale: localeName,
      other: '$voices giọng đọc',
      one: '1 giọng đọc',
    );
    return '$_temp0 · $size';
  }

  @override
  String voicePackLanguages(int count, String languages) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngôn ngữ',
      one: '1 ngôn ngữ',
    );
    return '$_temp0: $languages';
  }

  @override
  String get voicePackOpenRailNotice =>
      'Giấy phép của mô hình này (OpenRAIL-M) nghiêm cấm các mục đích sử dụng gây hại, chẳng hạn như mạo danh người khác hoặc phát tán thông tin sai lệch, và những hạn chế này cũng áp dụng cho bạn.';

  @override
  String voicePackDeleteConfirm(String pack, String size) {
    return 'Xóa $pack? Thao tác này sẽ giải phóng $size.';
  }

  @override
  String get voicePackDownload => 'Tải xuống';

  @override
  String get voicePackUpdate => 'Cập nhật';

  @override
  String get voicePackWaitingForWifi => 'Đang chờ Wi-Fi';

  @override
  String get voicePackUseMobileData => 'Dùng dữ liệu di động';

  @override
  String voicePackDownloading(String downloaded, String total) {
    return 'Đang tải xuống: $downloaded / $total';
  }

  @override
  String get voicePackInstalling => 'Đang cài đặt';

  @override
  String voicePackInstallFailed(String pack) {
    return 'Không thể cài đặt $pack. Hãy kiểm tra kết nối của bạn và thử lại.';
  }

  @override
  String get voices => 'Giọng đọc';

  @override
  String get perViewerVoice => 'Giọng đọc riêng cho từng người xem';

  @override
  String get perViewerVoiceSubtitle =>
      'Mỗi người xem sẽ có giọng đọc riêng. Giọng đọc bạn chọn sẽ dùng để đọc thông báo, hoặc đọc tất cả khi tắt tùy chọn này.';

  @override
  String get streamLanguage => 'Ngôn ngữ luồng phát';

  @override
  String get ttsEngineNeural => 'Giọng đọc AI (trên thiết bị)';

  @override
  String get ttsEngineSystem => 'Giọng đọc hệ thống';

  @override
  String languageUnsupported(String language) {
    return 'Gói giọng nói của bạn không hỗ trợ $language; giọng đọc hệ thống sẽ được sử dụng';
  }

  @override
  String get neuralFallbackLowMemory =>
      'Thiết bị này không đủ bộ nhớ cho giọng đọc AI nên nội dung trò chuyện sẽ được đọc bằng giọng đọc hệ thống.';

  @override
  String get neuralFallbackLoadFailed =>
      'Không thể tải giọng đọc AI nên nội dung trò chuyện sẽ được đọc bằng giọng đọc hệ thống.';

  @override
  String get accounts => 'Tài khoản';

  @override
  String get accountsSubtitle => 'Đăng nhập vào từng nền tảng mà bạn phát sóng';

  @override
  String addProviderAccount(String provider) {
    return 'Thêm tài khoản $provider';
  }

  @override
  String signInWithProvider(String provider) {
    return 'Đăng nhập bằng $provider';
  }

  @override
  String signOutOfAccount(String channel, String provider) {
    return 'Đăng xuất khỏi $channel trên $provider?';
  }

  @override
  String get signOutOfAll => 'Đăng xuất khỏi tất cả tài khoản';
}
