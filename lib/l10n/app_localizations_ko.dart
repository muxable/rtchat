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
  String get alertsEnabled => 'Alerts only';

  @override
  String get sidebarActions => 'Sidebar Actions';
}
