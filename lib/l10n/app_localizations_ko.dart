// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get sendAMessage => '메시지 보내기...';

  @override
  String get writeSomething => '무언가를 쓰세요...';

  @override
  String get speakToTheCrowds => '군중에게 말하세요...';

  @override
  String get shareYourThoughts => '생각을 공유하세요...';

  @override
  String get saySomethingYouLittleBitch => '뭐라고 말해봐, 이 작은 개자식아...';

  @override
  String get search => '검색';

  @override
  String get notSignedIn => '로그인되지 않음';

  @override
  String get searchChannels => '채널 검색';

  @override
  String get raidAChannel => '채널 습격';

  @override
  String get noMessagesEmptyState => '메시지가 없습니다';

  @override
  String newMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개의 새 메시지',
      one: '새 메시지 1개',
      zero: '새 메시지가 없습니다',
    );
    return '$_temp0';
  }

  @override
  String get signInWithTwitch => 'Twitch로 로그인';

  @override
  String get signInError => '로그인 중 오류가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get continueAsGuest => '게스트로 계속';

  @override
  String get signInToSendMessages => '메시지를 보내려면 로그인하세요';

  @override
  String get currentViewers => '현재 시청자';

  @override
  String get textToSpeech => '텍스트를 음성으로';

  @override
  String get streamPreview => '스트림 미리보기';

  @override
  String get activityFeed => '활동 피드';

  @override
  String streamOnline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString에 온라인 스트림';
  }

  @override
  String streamOffline(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString에 오프라인 스트림';
  }

  @override
  String chatCleared(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat =
        intl.DateFormat.yMMMMEEEEd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.jms(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$dateString, $timeString에 채팅이 지워졌습니다';
  }

  @override
  String get configureQuickLinks => '빠른 링크 구성';

  @override
  String get disableRainMode => '비 모드 비활성화';

  @override
  String get enableRainMode => '비 모드 활성화';

  @override
  String get disableRainModeSubtitle => '상호작용이 활성화됩니다';

  @override
  String get enableRainModeSubtitle => '상호작용이 비활성화됩니다';

  @override
  String get refreshAudioSources => '오디오 소스 새로 고침';

  @override
  String refreshAudioSourcesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개의 오디오 소스 새로 고침됨',
      one: '새로 고침된 오디오 소스 1개',
      zero: '새로 고침된 오디오 소스 없음',
    );
    return '$_temp0';
  }

  @override
  String get settings => '설정';

  @override
  String get signOut => '로그아웃';

  @override
  String get cancel => '취소';

  @override
  String get signOutConfirmation => '로그아웃하시겠습니까?';

  @override
  String get broadcaster => '방송인';

  @override
  String get moderators => '관리자';

  @override
  String get viewers => '시청자';

  @override
  String get communityVips => '커뮤니티 VIP';

  @override
  String get searchViewers => '시청자 검색';

  @override
  String get reconnecting => '재연결 중...';

  @override
  String get twitchBadges => 'Twitch 배지';

  @override
  String get selectAll => '모두 선택';

  @override
  String get quickLinks => '빠른 링크';

  @override
  String get swipeToDeleteQuickLinks => '빠른 링크를 삭제하려면 왼쪽 또는 오른쪽으로 스와이프하세요';

  @override
  String get quickLinksLabelHint => '레이블';

  @override
  String get invalidUrlErrorText => '유효한 URL이 아닌 것 같습니다';

  @override
  String get duplicateUrlErrorText => '이 링크는 이미 존재합니다';

  @override
  String get or => '또는';

  @override
  String get clearCookies => '쿠키 지우기';

  @override
  String get disabled => '비활성화됨';

  @override
  String get twitchActivityFeed => 'Twitch 활동 피드';

  @override
  String get signInToEnable => '이 기능을 활성화하려면 로그인해야 합니다';

  @override
  String get customUrl => '사용자 정의 URL';

  @override
  String get preview => '미리보기';

  @override
  String get audioSources => '오디오 소스';

  @override
  String get enableOffStreamSwitchTitle => '오프 스트림 활성화 (배터리 소모 증가)';

  @override
  String get enableOffStreamSwitchEnabledSubtitle => '오프라인일 때도 오디오가 재생됩니다';

  @override
  String get enableOffStreamSwitchDisabledSubtitle => '라이브일 때만 오디오가 재생됩니다';

  @override
  String get iosOggWarningTitle => '이봐! 들어봐!';

  @override
  String get iosOggWarningSubtitle =>
      'iOS는 Streamlabs의 기본 파일인 *.ogg 미디어 파일을 지원하지 않습니다. 오디오 소스가 다른 형식을 사용하도록 설정하지 않으면 재생되지 않습니다.';

  @override
  String get url => 'URL';

  @override
  String get activityFeedSubtitle => '활동 피드를 사용자 정의하세요';

  @override
  String get audioSourcesSubtitle => '알림 소리를 위한 웹 소스를 추가하세요';

  @override
  String get quickLinksSubtitle => '자주 사용하는 도구에 대한 바로가기를 추가하세요';

  @override
  String get chatHistory => '채팅 기록';

  @override
  String get chatHistorySubtitle => '채팅 모양 변경';

  @override
  String get textToSpeechSubtitle => '텍스트를 음성으로 설정 변경';

  @override
  String get events => '이벤트';

  @override
  String get eventsSubtitle => 'Twitch 이벤트 구성';

  @override
  String get thirdPartyServices => '타사 서비스';

  @override
  String get thirdPartyServicesSubtitle => '타사 서비스에 연결';

  @override
  String followingEvent(String displayName) {
    return '<b>$displayName</b>님이 팔로우합니다';
  }

  @override
  String followingEvent2(String displayName, String displayNameTwo) {
    return '<b>$displayName</b>님과 <b>$displayNameTwo</b>님이 팔로우합니다';
  }

  @override
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers) {
    final intl.NumberFormat numOthersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numOthersString = numOthersNumberFormat.format(numOthers);

    return '<b>$displayName</b>님, <b>$displayNameTwo</b>님, 그리고 $numOthersString명이 팔로우합니다';
  }

  @override
  String unmuteUser(String displayName) {
    return '$displayName님의 음소거 해제';
  }

  @override
  String muteUser(String displayName) {
    return '$displayName님 음소거';
  }

  @override
  String timeoutUser(String displayName) {
    return '$displayName님 타임아웃';
  }

  @override
  String banUser(String displayName) {
    return '$displayName님 차단';
  }

  @override
  String unbanUser(String displayName) {
    return '$displayName님 차단 해제';
  }

  @override
  String viewProfile(String displayName) {
    return '$displayName님의 프로필 보기';
  }

  @override
  String get copyMessage => '메시지 복사';

  @override
  String get deleteMessage => '메시지 삭제';

  @override
  String get longScrollNotification => '꽤 멀리 스크롤하고 있네요, 그렇지 않나요?';

  @override
  String get stfu => '조용히 해';

  @override
  String get globalEmotes => '글로벌 이모티콘';

  @override
  String followerCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '팔로워 $countString명',
      one: '팔로워 1명',
      zero: '팔로워 0명',
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
      other: '시청자 $countString명',
      one: '시청자 1명',
      zero: '시청자 0명',
    );
    return '$_temp0';
  }

  @override
  String get streamPreviewMessage =>
      '안녕하세요! 스트림 미리보기를 사용하는 것을 좋아해 주셔서 감사합니다. 하지만 배터리를 많이 소모한다는 점을 유의하세요. 미리보기 없이 채팅을 읽으면 배터리 수명이 연장됩니다.';

  @override
  String get okay => '확인';

  @override
  String get streamPreviewLoading => '로딩 중 (또는 스트림이 오프라인입니다)...';

  @override
  String get copiedToClipboard => '클립보드에 복사됨';

  @override
  String get audioSourcesRequirePermissions => '오디오 소스에는 권한이 필요합니다';

  @override
  String get audioSourcesRequirePermissionsMessage =>
      '오디오 소스를 사용하려면 RealtimeChat이 다른 앱 위에 그릴 수 있도록 승인하세요.';

  @override
  String get audioSourcesRemoveButton => '오디오 소스 제거';

  @override
  String get audioSourcesOpenSettingsButton => '설정 열기';

  @override
  String get flashOn => '플래시 켜기';

  @override
  String get flashOff => '플래시 끄기';

  @override
  String get durationOneSecond => '1초';

  @override
  String get durationOneMinute => '1분';

  @override
  String get durationTenMinutes => '10분';

  @override
  String get durationOneHour => '1시간';

  @override
  String get durationSixHours => '6시간';

  @override
  String get durationOneDay => '1일';

  @override
  String get durationTwoDays => '2일';

  @override
  String get durationOneWeek => '1주';

  @override
  String get durationTwoWeeks => '2주';

  @override
  String get durationOneSecondTimeoutPrompt => '1초 동안 타임아웃';

  @override
  String get durationOneMinuteTimeoutPrompt => '1분 동안 타임아웃';

  @override
  String get durationTenMinutesTimeoutPrompt => '10분 동안 타임아웃';

  @override
  String get durationOneHourTimeoutPrompt => '1시간 동안 타임아웃';

  @override
  String get durationSixHoursTimeoutPrompt => '6시간 동안 타임아웃';

  @override
  String get durationOneDayTimeoutPrompt => '1일 동안 타임아웃';

  @override
  String get durationTwoDaysTimeoutPrompt => '2일 동안 타임아웃';

  @override
  String get durationOneWeekTimeoutPrompt => '1주 동안 타임아웃';

  @override
  String get durationTwoWeeksTimeoutPrompt => '2주 동안 타임아웃';

  @override
  String get errorFetchingViewerList => '이 채널의 시청자 목록을 가져올 수 없습니다';

  @override
  String get eventsTitle => '이벤트';

  @override
  String get followEventConfigTitle => '팔로우 이벤트';

  @override
  String get customizeYourFollowEvent => '팔로우 이벤트를 사용자 정의하세요';

  @override
  String get subscribeEventConfigTitle => '구독 이벤트';

  @override
  String get customizeYourSubscriptionEvent => '구독 이벤트를 사용자 정의하세요';

  @override
  String get cheerEventConfigTitle => '응원 이벤트';

  @override
  String get customizeYourCheerEvent => '응원 이벤트를 사용자 정의하세요';

  @override
  String get raidEventConfigTitle => '습격 이벤트';

  @override
  String get customizeYourRaidEvent => '습격 이벤트를 사용자 정의하세요';

  @override
  String get hostEventConfigTitle => '호스트 이벤트';

  @override
  String get customizeYourHostEvent => '호스트 이벤트를 사용자 정의하세요';

  @override
  String get hypetrainEventConfigTitle => '하이프 트레인 이벤트';

  @override
  String get customizeYourHypetrainEvent => '하이프 트레인 이벤트를 사용자 정의하세요';

  @override
  String get pollEventConfigTitle => '투표 이벤트';

  @override
  String get customizeYourPollEvent => '투표 이벤트를 사용자 정의하세요';

  @override
  String get predictionEventConfigTitle => '예측 이벤트';

  @override
  String get customizeYourPredictionEvent => '예측 이벤트를 사용자 정의하세요';

  @override
  String get channelPointRedemptionEventConfigTitle => '채널 포인트 교환 이벤트';

  @override
  String get customizeYourChannelPointRedemptionEvent =>
      '채널 포인트 교환 이벤트를 사용자 정의하세요';

  @override
  String get outgoingRaidEventConfigTitle => '나가는 습격 이벤트';

  @override
  String get customizeYourOutgoingRaidEvent => '나가는 습격 이벤트를 사용자 정의하세요';

  @override
  String raidEventMessage(String displayName, int viewerCount) {
    final intl.NumberFormat viewerCountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewerCountString =
        viewerCountNumberFormat.format(viewerCount);

    return '<b>$displayName</b>님이 <b>$viewerCountString</b>명의 시청자와 함께 습격 중입니다!';
  }

  @override
  String get shoutout => '감사합니다';

  @override
  String raidingEventRaiding(String displayName) {
    return '<b>$displayName</b>님을 습격 중...';
  }

  @override
  String raidingEventTimeRemaining(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '남은 시간 $secondsString초';
  }

  @override
  String raidingEventRaided(String displayName) {
    return '<b>$displayName</b>님이 습격했습니다!';
  }

  @override
  String get raidingEventJoin => '참여';

  @override
  String raidingEventCanceled(String displayName) {
    return '<b>$displayName</b>님의 습격이 취소되었습니다.';
  }

  @override
  String subscriptionEvent(String subscriberUserName, String tier) {
    return '<b>$subscriberUserName</b>님이 티어 $tier에 구독했습니다!';
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

    return '<b>$gifterUserName</b>님이 티어 $tier 구독 $totalString개를 선물하여 총 $cumulativeTotalString개가 되었습니다!';
  }

  @override
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier) {
    final intl.NumberFormat cumulativeMonthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String cumulativeMonthsString =
        cumulativeMonthsNumberFormat.format(cumulativeMonths);

    return '<b>$subscriberUserName</b>님이 티어 $tier에 $cumulativeMonthsString개월 동안 구독했습니다!';
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

    return '<b>$subscriberUserName</b>님이 티어 $tier로 $durationMonthsString개월을 미리 구독했습니다. 총 $cumulativeMonthsString개월!';
  }

  @override
  String realtimeCashTipWithDonor(String donor, String value, String currency) {
    return '<b>$donor</b> 팁을 주었다 <b>$value $currency</b>.';
  }

  @override
  String realtimeCashTipAnonymous(String value, String currency) {
    return '익명 팁을 했습니다 <b>$value $currency</b>.';
  }

  @override
  String streamElementsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b>님이 StreamElements에서 <b>$formattedAmount</b>를 팁으로 주었습니다.';
  }

  @override
  String streamlabsTipEventMessage(String name, String formattedAmount) {
    return '<b>$name</b>님이 Streamlabs에서 <b>$formattedAmount</b>를 팁으로 주었습니다.';
  }

  @override
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b>님이 <b>$rewardName</b>을(를) <b>$rewardCostString</b> 포인트로 교환했습니다. $userInput';
  }

  @override
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost) {
    final intl.NumberFormat rewardCostNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rewardCostString = rewardCostNumberFormat.format(rewardCost);

    return '<b>$redeemerUsername</b>님이 <b>$rewardName</b>을(를) <b>$rewardCostString</b> 포인트로 교환했습니다.';
  }

  @override
  String cheerEventMessage(String name, int bits, String cheerMessage) {
    final intl.NumberFormat bitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String bitsString = bitsNumberFormat.format(bits);

    return '<b>$name</b>님이 <b>$bitsString</b> 비트를 응원했습니다. $cheerMessage';
  }

  @override
  String get anonymous => '익명';

  @override
  String hostEventMessage(String fromDisplayName, int viewers) {
    final intl.NumberFormat viewersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String viewersString = viewersNumberFormat.format(viewers);

    return '<b>$fromDisplayName</b>님이 <b>$viewersString</b>명의 파티와 함께 호스팅 중입니다.';
  }

  @override
  String hypeTrainEventProgress(String level, String progressPercent) {
    return '하이프 트레인 레벨 <b>$level</b> 진행 중! <b>$progressPercent%</b> 완료!';
  }

  @override
  String hypeTrainEventEndedSuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return '하이프 트레인 레벨 <b>$levelString</b> 성공.';
  }

  @override
  String hypeTrainEventEndedUnsuccessful(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return '하이프 트레인 레벨 <b>$levelString</b> 실패.';
  }

  @override
  String get sampleMessage => '이것은 텍스트 음성 변환을 위한 샘플 메시지입니다.';

  @override
  String actionMessage(String author, String text) {
    return '$author $text';
  }

  @override
  String saidMessage(String author, String text) {
    return '$author 님이 말했습니다: $text';
  }

  @override
  String get textToSpeechEnabled => '텍스트 음성 변환 활성화됨';

  @override
  String get textToSpeechDisabled => '텍스트 음성 변환이 비활성화되었습니다';

  @override
  String get alertsEnabled => '알림만';

  @override
  String get pinDuration => '고정 시간';

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds초',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes분',
    );
    return '$_temp0';
  }

  @override
  String get enableEvent => '이벤트 사용';

  @override
  String get showEventInChatHistory => '채팅 기록에 이벤트 표시';

  @override
  String get enableShoutouts => '샤웃아웃 사용';

  @override
  String get enableShoutoutsSubtitle => '습격한 채널의 링크를 채팅에 보내기';

  @override
  String get raidConfigurationTitle => '습격 설정';

  @override
  String get cheerConfigurationTitle => '치어 설정';

  @override
  String get followConfigurationTitle => '팔로우 설정';

  @override
  String get outgoingRaidConfigurationTitle => '보내는 습격 설정';

  @override
  String get hostConfigurationTitle => '호스트 설정';

  @override
  String get channelPointConfigurationTitle => '채널 포인트 설정';

  @override
  String get pollConfigurationTitle => '투표 설정';

  @override
  String get hypetrainConfigurationTitle => '하이프 트레인 설정';

  @override
  String get subscriptionConfigurationTitle => '구독 설정';

  @override
  String get predictionConfigurationTitle => '예측 설정';

  @override
  String get unfulfilledRewardsPinDuration => '처리되지 않은 보상의 추가 고정 시간';

  @override
  String get pollPinDuration => '결과 확정 후 고정 시간';

  @override
  String get hypetrainPinDuration => '하이프 트레인 종료 후 고정 시간';

  @override
  String get enableGiftedSubscriptions => '선물 구독 개별 표시';

  @override
  String get enableGiftedSubscriptionsSubtitle => '선물된 모든 구독 표시';

  @override
  String get settingsBackupTitle => '설정 백업 및 복원';

  @override
  String get cloudBackup => '클라우드 백업';

  @override
  String get lastBackupNever => '마지막 백업: 없음';

  @override
  String get backUp => '백업';

  @override
  String get restore => '복원';

  @override
  String get localBackup => '로컬 백업';

  @override
  String get exportSettings => '내보내기';

  @override
  String get importSettings => '가져오기';

  @override
  String get showViewerAndFollowerCount => '시청자 및 팔로워 수 표시';

  @override
  String get screenOrientation => '화면 방향';

  @override
  String get appTheme => '앱 테마';

  @override
  String get systemDefault => '시스템';

  @override
  String get portrait => '세로';

  @override
  String get landscape => '가로';

  @override
  String get lightTheme => '라이트';

  @override
  String get darkTheme => '다크';

  @override
  String get openSourceTitle => 'RealtimeChat은 오픈 소스입니다';

  @override
  String get openSourceSubtitle => 'GitHub에서 만나요!';

  @override
  String get discordSubtitle => 'Muxable Discord에 참여하세요!';

  @override
  String get earlyTestersThanks => '버그를 제보해 주신 초기 테스터 여러분께 감사드립니다!';

  @override
  String get discoModeEnabled => '🕺 디스코 모드 켜짐! :D';

  @override
  String get discoModeDisabled => '🕺 디스코 모드 꺼짐 D:';

  @override
  String get cloudTts => '클라우드 TTS';

  @override
  String get languages => '언어';

  @override
  String get voices => '음성';

  @override
  String get perViewerVoice => '시청자별 음성';

  @override
  String get perViewerVoiceSubtitle => '목소리로 시청자 구별하기';

  @override
  String get randomVoice => '무작위';

  @override
  String get playSampleMessage => '샘플 메시지 재생';

  @override
  String get textToSpeechRate => '음성 속도';

  @override
  String get textToSpeechPitch => '음성 높낮이';

  @override
  String get unlockHighQualityVoices => '고품질 음성 잠금 해제';

  @override
  String get muteBots => '봇 메시지 음성 끄기';

  @override
  String get muteEmotes => '모든 이모트 음성 끄기';

  @override
  String get muteViewerNames => '시청자 이름 음성 끄기';

  @override
  String get subscribersOnly => '구독자 전용';

  @override
  String get storeNotAvailable => '스토어를 사용할 수 없음';

  @override
  String get unavailable => '사용할 수 없음';

  @override
  String get subscribe => '구독';

  @override
  String get pending => '대기 중';

  @override
  String get subscribed => '구독함';

  @override
  String get pleaseSignIn => '로그인하세요';

  @override
  String get searchLanguages => '언어 검색';

  @override
  String get closeSearch => '검색 닫기';

  @override
  String get playSample => '샘플 재생';

  @override
  String get fontSize => '글꼴 크기';

  @override
  String get usernameContrastBoost => '사용자 이름 대비 강화';

  @override
  String get twitchBadgeSettings => 'Twitch 배지 설정';

  @override
  String get twitchBadgeSettingsSubtitle => '표시할 배지 선택';

  @override
  String get showDeletedMessages => '삭제된 메시지 표시';

  @override
  String get deletedMessagesGreyedOut => '삭제된 메시지가 회색으로 표시됩니다';

  @override
  String get deletedMessagesRemoved => '삭제된 메시지가 제거됩니다';

  @override
  String get showLoginNames => '로그인 이름 표시';

  @override
  String get loginNamesShown => '표시 이름과 다르면 로그인 이름이 표시됩니다';

  @override
  String get loginNamesHidden => '로그인 이름이 숨겨집니다';

  @override
  String get compactMessages => '메시지 압축';

  @override
  String get dontCompactMessages => '메시지 압축 안 함';

  @override
  String get dontCompactMessagesSubtitle => '메시지가 그대로 표시됩니다';

  @override
  String get compactIndividualMessages => '개별 메시지 압축';

  @override
  String get compactIndividualMessagesSubtitle => '메시지의 반복되는 텍스트가 줄어듭니다';

  @override
  String get announcementPinDuration => '공지 고정 시간';

  @override
  String get idleMessageAlertDuration => '채팅 무응답 알림 시간';

  @override
  String get idleMessageAlertDurationSubtitle =>
      '이 시간 동안 메시지가 없다가 새 메시지가 오면 알림음이 재생됩니다.';

  @override
  String get realtimeCashSubtitle => 'ETH 또는 MATIC 지갑 연결';

  @override
  String get walletAddress => '지갑 주소';

  @override
  String get streamlabsSubtitle => 'Streamlabs 후원 보기';

  @override
  String get streamElementsSubtitle => 'StreamElements 후원 보기';

  @override
  String get thirdPartyAuthError =>
      '음, 제대로 되지 않았어요. 다시 시도하거나 Discord에 문의해 주세요.';

  @override
  String get companionAuthBrowserTooOld =>
      '브라우저가 너무 오래되어 바로 로그인할 수 없습니다. 휴대폰으로 이 QR 코드를 스캔하여 다른 기기에서 로그인하세요.';

  @override
  String get companionAuthScanQrCode => '휴대폰으로 이 QR 코드를 스캔하여 다른 기기에서 로그인하세요.';

  @override
  String kickSubscriptionEvent(String subscriberName) {
    return '<b>$subscriberName</b>님이 구독했습니다!';
  }

  @override
  String kickResubscriptionEvent(String subscriberName, int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '<b>$subscriberName</b>님이 $monthsString개월째 구독을 갱신했습니다!';
  }

  @override
  String kickGiftedSubscriptionsEvent(String gifterName, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '<b>$gifterName</b>님이 구독 $countString개를 선물했습니다!';
  }

  @override
  String kicksGiftedEvent(String senderName, int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '<b>$senderName</b>님이 $amountString Kicks를 보냈습니다!';
  }

  @override
  String get signInWithKick => 'Kick으로 로그인';

  @override
  String get textToSpeechTooManyMessages => '메시지가 너무 많습니다. 텍스트 음성 변환이 꺼졌습니다';

  @override
  String get turnOffTextToSpeech => '끄기';

  @override
  String get addChannel => '채널 추가';

  @override
  String get addToChat => '채팅에 추가';

  @override
  String get defaultChannels => '기본 채널';

  @override
  String get defaultChannelsSubtitle => '앱을 열 때 표시되는 채널';

  @override
  String get useCurrentChannels => '현재 채널 사용';

  @override
  String get inChat => '채팅에 표시 중';

  @override
  String get removeFromChat => '채팅에서 제거';

  @override
  String cantChatWithAccount(String provider) {
    return '$provider 계정으로는 여기서 채팅할 수 없습니다';
  }

  @override
  String replaceChannel(String channel) {
    return '$channel 대체';
  }

  @override
  String get searchSwipeHint => '탭하여 채널로 전환하거나 오른쪽으로 스와이프하여 추가하세요';

  @override
  String get swipeToRemoveHint => '왼쪽으로 스와이프하여 삭제';

  @override
  String get removeChannel => '삭제';
}
