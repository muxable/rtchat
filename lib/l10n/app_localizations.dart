import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('sv'),
    Locale('uk'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// Message input field placeholder text
  ///
  /// In en, this message translates to:
  /// **'Send a message...'**
  String get sendAMessage;

  /// Message input field placeholder text
  ///
  /// In en, this message translates to:
  /// **'Write something...'**
  String get writeSomething;

  /// Message input field placeholder text
  ///
  /// In en, this message translates to:
  /// **'Speak to the crowds...'**
  String get speakToTheCrowds;

  /// Message input field placeholder text
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts...'**
  String get shareYourThoughts;

  /// Message input field placeholder text
  ///
  /// In en, this message translates to:
  /// **'Say something, you little bitch...'**
  String get saySomethingYouLittleBitch;

  /// Placeholder text for search bar
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Label for unauthenticated user
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// Header for a page that lets the user search channels
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchChannels;

  /// Header for a page that lets the raid channels
  ///
  /// In en, this message translates to:
  /// **'Raid'**
  String get raidAChannel;

  /// Empty state placeholder when there are no messages
  ///
  /// In en, this message translates to:
  /// **'It\'s quiet in here.'**
  String get noMessagesEmptyState;

  /// No description provided for @newMessageCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{No new messages} =1{1 new message} other{{count} new messages}}'**
  String newMessageCount(num count);

  /// Button label to allow a user to sign in with Twitch
  ///
  /// In en, this message translates to:
  /// **'Sign in with Twitch'**
  String get signInWithTwitch;

  /// Error message that shows when signing in fails
  ///
  /// In en, this message translates to:
  /// **'An error occurred when signing in. Please try again.'**
  String get signInError;

  /// Button label to allow a user to use the app without signing in
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// Text label to indicate that signing in is required to send messages
  ///
  /// In en, this message translates to:
  /// **'Sign in to send messages'**
  String get signInToSendMessages;

  /// Tooltip text for a button that shows the current viewers
  ///
  /// In en, this message translates to:
  /// **'Current viewers'**
  String get currentViewers;

  /// Tooltip text for a button that enables text to speech
  ///
  /// In en, this message translates to:
  /// **'Text to speech'**
  String get textToSpeech;

  /// Tooltip text for a button that shows the stream preview
  ///
  /// In en, this message translates to:
  /// **'Stream preview'**
  String get streamPreview;

  /// Header for the activity feed settings page and tooltip text for a button that shows the activity feed
  ///
  /// In en, this message translates to:
  /// **'Activity feed'**
  String get activityFeed;

  /// Event label to indicate that the stream is online
  ///
  /// In en, this message translates to:
  /// **'Stream online at {date}, {time}'**
  String streamOnline(DateTime date, DateTime time);

  /// Event label to indicate that the stream is offline
  ///
  /// In en, this message translates to:
  /// **'Stream offline at {date}, {time}'**
  String streamOffline(DateTime date, DateTime time);

  /// Event label to indicate that the chat was cleared
  ///
  /// In en, this message translates to:
  /// **'Chat cleared at {date}, {time}'**
  String chatCleared(DateTime date, DateTime time);

  /// Button label that shows the quick links configuration
  ///
  /// In en, this message translates to:
  /// **'Configure quick links'**
  String get configureQuickLinks;

  /// Button label that disables rain mode
  ///
  /// In en, this message translates to:
  /// **'Disable rain mode'**
  String get disableRainMode;

  /// Button label that enables rain mode
  ///
  /// In en, this message translates to:
  /// **'Enable rain mode'**
  String get enableRainMode;

  /// Subtitle for the button that disables rain mode, indicating that interaction will be enabled
  ///
  /// In en, this message translates to:
  /// **'Interaction will be enabled'**
  String get disableRainModeSubtitle;

  /// Subtitle for the button that enables rain mode, indicating that interaction will be disabled
  ///
  /// In en, this message translates to:
  /// **'Interaction will be disabled'**
  String get enableRainModeSubtitle;

  /// Button label that refreshes the audio sources
  ///
  /// In en, this message translates to:
  /// **'Refresh audio sources'**
  String get refreshAudioSources;

  /// No description provided for @refreshAudioSourcesCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{No audio sources refreshed} =1{1 audio source refreshed} other{{count} audio sources refreshed}}'**
  String refreshAudioSourcesCount(num count);

  /// Header for the settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Button label that signs the user out
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Button label that cancels an action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirmation message that shows when the user wants to sign out
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmation;

  /// Label for the broadcaster
  ///
  /// In en, this message translates to:
  /// **'Broadcaster'**
  String get broadcaster;

  /// Label for the moderators
  ///
  /// In en, this message translates to:
  /// **'Moderators'**
  String get moderators;

  /// Label for the viewers
  ///
  /// In en, this message translates to:
  /// **'Viewers'**
  String get viewers;

  /// Label for the community VIPs
  ///
  /// In en, this message translates to:
  /// **'Community VIPs'**
  String get communityVips;

  /// Header for the search bar that lets the user search viewers
  ///
  /// In en, this message translates to:
  /// **'Search Viewers'**
  String get searchViewers;

  /// Text label that shows when the app is reconnecting
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// Header for the Twitch badges page
  ///
  /// In en, this message translates to:
  /// **'Twitch badges'**
  String get twitchBadges;

  /// Button label that selects all badges
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// Header for the quick links page
  ///
  /// In en, this message translates to:
  /// **'Quick links'**
  String get quickLinks;

  /// Text label that shows when the user can swipe to delete a quick link
  ///
  /// In en, this message translates to:
  /// **'Swipe left or right to delete quick link'**
  String get swipeToDeleteQuickLinks;

  /// Hint text for the quick link label
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get quickLinksLabelHint;

  /// Error message that shows when the URL is invalid
  ///
  /// In en, this message translates to:
  /// **'This doesn\'t look like a valid URL'**
  String get invalidUrlErrorText;

  /// Error message that shows when the URL already exists
  ///
  /// In en, this message translates to:
  /// **'This link already exists'**
  String get duplicateUrlErrorText;

  /// Text label that separates two options
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// Button label that clears the cookies
  ///
  /// In en, this message translates to:
  /// **'Clear cookies'**
  String get clearCookies;

  /// Option label to disable a feature
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// Option label to use the default Twitch activity feed
  ///
  /// In en, this message translates to:
  /// **'Twitch activity feed'**
  String get twitchActivityFeed;

  /// Error message that shows when the user must be signed in to enable a feature
  ///
  /// In en, this message translates to:
  /// **'You must be signed in to enable this'**
  String get signInToEnable;

  /// Option label to use a custom URL
  ///
  /// In en, this message translates to:
  /// **'Custom URL'**
  String get customUrl;

  /// Section header for the activity feed preview
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// Header for the audio sources page
  ///
  /// In en, this message translates to:
  /// **'Audio sources'**
  String get audioSources;

  /// Option label to enable the off-stream tile
  ///
  /// In en, this message translates to:
  /// **'Enable off-stream (uses more battery)'**
  String get enableOffStreamSwitchTitle;

  /// Subtitle for the option to enable the off-stream tile, indicating that audio will also play when the user is offline
  ///
  /// In en, this message translates to:
  /// **'Audio will also play when you\'re offline'**
  String get enableOffStreamSwitchEnabledSubtitle;

  /// No description provided for @enableOffStreamSwitchDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Audio will only play when you\'re live'**
  String get enableOffStreamSwitchDisabledSubtitle;

  /// Title for the warning that shows when the user is on iOS and the audio source is OGG
  ///
  /// In en, this message translates to:
  /// **'Hey! Listen!'**
  String get iosOggWarningTitle;

  /// Message for the warning that shows when the user is on iOS and the audio source is OGG
  ///
  /// In en, this message translates to:
  /// **'iOS doesn\'t support *.ogg media files, which are the default files on Streamlabs. Ensure your audio sources use another format, otherwise they won\'t play.'**
  String get iosOggWarningSubtitle;

  /// Label for the URL
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get url;

  /// Subtitle for the activity feed settings page
  ///
  /// In en, this message translates to:
  /// **'Customize your activity feed'**
  String get activityFeedSubtitle;

  /// Subtitle for the audio sources page
  ///
  /// In en, this message translates to:
  /// **'Add web sources for alert sounds'**
  String get audioSourcesSubtitle;

  /// Subtitle for the quick links page
  ///
  /// In en, this message translates to:
  /// **'Add shortcuts to commonly used tools'**
  String get quickLinksSubtitle;

  /// Header for the chat history page
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get chatHistory;

  /// Subtitle for the chat history page
  ///
  /// In en, this message translates to:
  /// **'Change the chat appearance'**
  String get chatHistorySubtitle;

  /// Subtitle for the text to speech page
  ///
  /// In en, this message translates to:
  /// **'Change text to speech settings'**
  String get textToSpeechSubtitle;

  /// Header for the events page
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// Subtitle for the events page
  ///
  /// In en, this message translates to:
  /// **'Configure Twitch events'**
  String get eventsSubtitle;

  /// Header for the third-party services page
  ///
  /// In en, this message translates to:
  /// **'Third-party services'**
  String get thirdPartyServices;

  /// Subtitle for the third-party services page
  ///
  /// In en, this message translates to:
  /// **'Connect to a third-party service'**
  String get thirdPartyServicesSubtitle;

  /// Text label that shows when a user follows the streamer
  ///
  /// In en, this message translates to:
  /// **'<b>{displayName}</b> is following you'**
  String followingEvent(String displayName);

  /// Text label that shows when two users follow the streamer
  ///
  /// In en, this message translates to:
  /// **'<b>{displayName}</b> and <b>{displayNameTwo}</b> are following you'**
  String followingEvent2(String displayName, String displayNameTwo);

  /// Text label that shows when three or more users follow the streamer
  ///
  /// In en, this message translates to:
  /// **'<b>{displayName}</b>, <b>{displayNameTwo}</b>, and {numOthers} others are following you'**
  String followingEvent3(
      String displayName, String displayNameTwo, int numOthers);

  /// Unmute option shown when long pressing on a chat message
  ///
  /// In en, this message translates to:
  /// **'Unmute {displayName}'**
  String unmuteUser(String displayName);

  /// Mute option shown when long pressing on a chat message
  ///
  /// In en, this message translates to:
  /// **'Mute {displayName}'**
  String muteUser(String displayName);

  /// Timeout option shown when long pressing on a chat message
  ///
  /// In en, this message translates to:
  /// **'Timeout {displayName}'**
  String timeoutUser(String displayName);

  /// Ban option shown when long pressing on a chat message
  ///
  /// In en, this message translates to:
  /// **'Ban {displayName}'**
  String banUser(String displayName);

  /// Unban option shown when long pressing on a chat message
  ///
  /// In en, this message translates to:
  /// **'Unban {displayName}'**
  String unbanUser(String displayName);

  /// Unban option shown when long pressing on a chat message
  ///
  /// In en, this message translates to:
  /// **'View {displayName}\'s profile'**
  String viewProfile(String displayName);

  /// Copy option shown when long pressing on a chat message
  ///
  /// In en, this message translates to:
  /// **'Copy Message'**
  String get copyMessage;

  /// Delete option shown when long pressing on a chat message
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get deleteMessage;

  /// Notification shown when the user scrolls very far back in the chat history
  ///
  /// In en, this message translates to:
  /// **'You\'re scrolling kind of far, don\'t you think?'**
  String get longScrollNotification;

  /// Text label for the stfu button
  ///
  /// In en, this message translates to:
  /// **'stfu'**
  String get stfu;

  /// Text label for the global emotes category header
  ///
  /// In en, this message translates to:
  /// **'Global Emotes'**
  String get globalEmotes;

  /// Text label for the followers count
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{0 followers} =1{1 follower} other{{count} followers}}'**
  String followerCount(int count);

  /// Text label for the viewers count
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{0 viewers} =1{1 viewer} other{{count} viewers}}'**
  String viewerCount(int count);

  /// Notification shown when the user leaves the stream preview open for a long time
  ///
  /// In en, this message translates to:
  /// **'Hey there! Glad you like using stream preview but heads up it uses a lot of battery. Reading chat without it will extend your battery life.'**
  String get streamPreviewMessage;

  /// Okay button text
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// Text label shown when the stream preview is loading
  ///
  /// In en, this message translates to:
  /// **'Loading (or stream is offline)...'**
  String get streamPreviewLoading;

  /// Notification shown when a message is copied to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// Alert title prompting the user to grant permissions to use audio sources
  ///
  /// In en, this message translates to:
  /// **'Audio sources require permissions'**
  String get audioSourcesRequirePermissions;

  /// Alert message prompting the user to grant permissions to use audio sources
  ///
  /// In en, this message translates to:
  /// **'Approve RealtimeChat to draw over other apps to use audio sources.'**
  String get audioSourcesRequirePermissionsMessage;

  /// Button text for removing audio sources
  ///
  /// In en, this message translates to:
  /// **'Remove audio sources'**
  String get audioSourcesRemoveButton;

  /// Button text for opening settings
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get audioSourcesOpenSettingsButton;

  /// Text label for the camera flash enable button.
  ///
  /// In en, this message translates to:
  /// **'Flash on'**
  String get flashOn;

  /// Text label for the camera flash disable button.
  ///
  /// In en, this message translates to:
  /// **'Flash off'**
  String get flashOff;

  /// Text label for a one second duration
  ///
  /// In en, this message translates to:
  /// **'1 second'**
  String get durationOneSecond;

  /// Text label for a one minute duration
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get durationOneMinute;

  /// Text label for a ten minute duration
  ///
  /// In en, this message translates to:
  /// **'10 minutes'**
  String get durationTenMinutes;

  /// Text label for a one hour duration
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get durationOneHour;

  /// Text label for a six hour duration
  ///
  /// In en, this message translates to:
  /// **'6 hours'**
  String get durationSixHours;

  /// Text label for a one day duration
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get durationOneDay;

  /// Text label for a two day duration
  ///
  /// In en, this message translates to:
  /// **'2 days'**
  String get durationTwoDays;

  /// Text label for a one week duration
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get durationOneWeek;

  /// Text label for a two week duration
  ///
  /// In en, this message translates to:
  /// **'2 weeks'**
  String get durationTwoWeeks;

  /// Button label to timeout for a one second duration
  ///
  /// In en, this message translates to:
  /// **'Timeout for 1 second'**
  String get durationOneSecondTimeoutPrompt;

  /// Button label to timeout for a one minute duration
  ///
  /// In en, this message translates to:
  /// **'Timeout for 1 minute'**
  String get durationOneMinuteTimeoutPrompt;

  /// Button label to timeout for a ten minute duration
  ///
  /// In en, this message translates to:
  /// **'Timeout for 10 minutes'**
  String get durationTenMinutesTimeoutPrompt;

  /// Button label to timeout for a one hour duration
  ///
  /// In en, this message translates to:
  /// **'Timeout for 1 hour'**
  String get durationOneHourTimeoutPrompt;

  /// Button label to timeout for a six hour duration
  ///
  /// In en, this message translates to:
  /// **'Timeout for 6 hours'**
  String get durationSixHoursTimeoutPrompt;

  /// Button label to timeout for a one day duration
  ///
  /// In en, this message translates to:
  /// **'Timeout for 1 day'**
  String get durationOneDayTimeoutPrompt;

  /// Button label to timeout for a two day duration
  ///
  /// In en, this message translates to:
  /// **'Timeout for 2 days'**
  String get durationTwoDaysTimeoutPrompt;

  /// Button label to timeout for a one week duration
  ///
  /// In en, this message translates to:
  /// **'Timeout for 1 week'**
  String get durationOneWeekTimeoutPrompt;

  /// Button label to timeout for a two week duration
  ///
  /// In en, this message translates to:
  /// **'Timeout for 2 weeks'**
  String get durationTwoWeeksTimeoutPrompt;

  /// Error message if unable to fetch list
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t fetch the viewer list for this channel'**
  String get errorFetchingViewerList;

  /// Title for the events settings screen
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// Title for the follow event configuration
  ///
  /// In en, this message translates to:
  /// **'Follow Event'**
  String get followEventConfigTitle;

  /// Subtitle for the follow event configuration
  ///
  /// In en, this message translates to:
  /// **'Customize your follow event'**
  String get customizeYourFollowEvent;

  /// Title for the subscribe event configuration
  ///
  /// In en, this message translates to:
  /// **'Subscribe Event'**
  String get subscribeEventConfigTitle;

  /// Subtitle for the subscribe event configuration
  ///
  /// In en, this message translates to:
  /// **'Customize your subscription event'**
  String get customizeYourSubscriptionEvent;

  /// Title for the cheer event configuration
  ///
  /// In en, this message translates to:
  /// **'Cheer Event'**
  String get cheerEventConfigTitle;

  /// Subtitle for the cheer event configuration
  ///
  /// In en, this message translates to:
  /// **'Customize your cheer event'**
  String get customizeYourCheerEvent;

  /// Title for the raid event configuration
  ///
  /// In en, this message translates to:
  /// **'Raid Event'**
  String get raidEventConfigTitle;

  /// Subtitle for the raid event configuration
  ///
  /// In en, this message translates to:
  /// **'Customize your raid event'**
  String get customizeYourRaidEvent;

  /// Title for the host event configuration
  ///
  /// In en, this message translates to:
  /// **'Host Event'**
  String get hostEventConfigTitle;

  /// Subtitle for the host event configuration
  ///
  /// In en, this message translates to:
  /// **'Customize your host event'**
  String get customizeYourHostEvent;

  /// Title for the hypetrain event configuration
  ///
  /// In en, this message translates to:
  /// **'Hype Train Event'**
  String get hypetrainEventConfigTitle;

  /// Subtitle for the hypetrain event configuration
  ///
  /// In en, this message translates to:
  /// **'Customize your hype train event'**
  String get customizeYourHypetrainEvent;

  /// Title for the poll event configuration
  ///
  /// In en, this message translates to:
  /// **'Poll Event'**
  String get pollEventConfigTitle;

  /// Subtitle for the poll event configuration
  ///
  /// In en, this message translates to:
  /// **'Customize your poll event'**
  String get customizeYourPollEvent;

  /// Title for the prediction event configuration
  ///
  /// In en, this message translates to:
  /// **'Prediction Event'**
  String get predictionEventConfigTitle;

  /// Subtitle for the prediction event configuration
  ///
  /// In en, this message translates to:
  /// **'Customize your prediction event'**
  String get customizeYourPredictionEvent;

  /// Title for the channel point redemption event configuration
  ///
  /// In en, this message translates to:
  /// **'Channel Point Redemption Event'**
  String get channelPointRedemptionEventConfigTitle;

  /// Subtitle for the channel point redemption event configuration
  ///
  /// In en, this message translates to:
  /// **'Customize your channel point redemption event'**
  String get customizeYourChannelPointRedemptionEvent;

  /// Title for the outgoing raid event configuration
  ///
  /// In en, this message translates to:
  /// **'Outgoing Raid Event'**
  String get outgoingRaidEventConfigTitle;

  /// Subtitle for the outgoing raid event configuration
  ///
  /// In en, this message translates to:
  /// **'Customize your outgoing raid event'**
  String get customizeYourOutgoingRaidEvent;

  /// Message displayed when a raid event occurs
  ///
  /// In en, this message translates to:
  /// **'<b>{displayName}</b> is raiding with <b>{viewerCount}</b> viewers!'**
  String raidEventMessage(String displayName, int viewerCount);

  /// Button text for the shoutout action in a raid event
  ///
  /// In en, this message translates to:
  /// **'Shoutout'**
  String get shoutout;

  /// Message displayed when a raiding event is in progress
  ///
  /// In en, this message translates to:
  /// **'Raiding <b>{displayName}</b>...'**
  String raidingEventRaiding(String displayName);

  /// Message displaying the time remaining for a raiding event
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String raidingEventTimeRemaining(int seconds);

  /// Message displayed when a raiding event has completed successfully
  ///
  /// In en, this message translates to:
  /// **'<b>{displayName}</b> has raided!'**
  String raidingEventRaided(String displayName);

  /// Button text to join the raid in a raiding event
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get raidingEventJoin;

  /// Message displayed when a raiding event is canceled
  ///
  /// In en, this message translates to:
  /// **'<b>{displayName}</b>\'s raid was canceled.'**
  String raidingEventCanceled(String displayName);

  /// Message displayed when a subscription event occurs
  ///
  /// In en, this message translates to:
  /// **'<b>{subscriberUserName}</b> has subscribed at Tier {tier}!'**
  String subscriptionEvent(String subscriberUserName, String tier);

  /// Message displayed when a subscription gift event occurs
  ///
  /// In en, this message translates to:
  /// **'<b>{gifterUserName}</b> has gifted {total} Tier {tier} subs, totaling {cumulativeTotal}!'**
  String subscriptionGiftEvent(
      String gifterUserName, int total, String tier, int cumulativeTotal);

  /// Message displayed when a subscription message event occurs
  ///
  /// In en, this message translates to:
  /// **'<b>{subscriberUserName}</b> has subscribed for {cumulativeMonths} months at Tier {tier}!'**
  String subscriptionMessageEvent(
      String subscriberUserName, int cumulativeMonths, String tier);

  /// Message displayed when a RealtimeCash tip is made with a donor name
  ///
  /// In en, this message translates to:
  /// **'<b>{donor}</b> tipped <b>{value} {currency}</b>.'**
  String realtimeCashTipWithDonor(String donor, String value, String currency);

  /// Message displayed when a RealtimeCash tip is made anonymously
  ///
  /// In en, this message translates to:
  /// **'Anonymous tipped <b>{value} {currency}</b>.'**
  String realtimeCashTipAnonymous(String value, String currency);

  /// Message displayed when a StreamElements tip event occurs
  ///
  /// In en, this message translates to:
  /// **'<b>{name}</b> tipped <b>{formattedAmount}</b> on StreamElements.'**
  String streamElementsTipEventMessage(String name, String formattedAmount);

  /// Message displayed when a Streamlabs tip event occurs
  ///
  /// In en, this message translates to:
  /// **'<b>{name}</b> tipped <b>{formattedAmount}</b> on Streamlabs.'**
  String streamlabsTipEventMessage(String name, String formattedAmount);

  /// Message displayed when a channel point redemption event occurs with user input
  ///
  /// In en, this message translates to:
  /// **'<b>{redeemerUsername}</b> redeemed <b>{rewardName}</b> for <b>{rewardCost}</b> points. {userInput}'**
  String channelPointRedemptionWithUserInput(String redeemerUsername,
      String rewardName, int rewardCost, String userInput);

  /// Message displayed when a channel point redemption event occurs without user input
  ///
  /// In en, this message translates to:
  /// **'<b>{redeemerUsername}</b> redeemed <b>{rewardName}</b> for <b>{rewardCost}</b> points.'**
  String channelPointRedemptionWithoutUserInput(
      String redeemerUsername, String rewardName, int rewardCost);

  /// Message displayed when a cheer event occurs
  ///
  /// In en, this message translates to:
  /// **'<b>{name}</b> cheered <b>{bits}</b> bits. {cheerMessage}'**
  String cheerEventMessage(String name, int bits, String cheerMessage);

  /// Username of an anonymous user
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// Message displayed when a host event occurs
  ///
  /// In en, this message translates to:
  /// **'<b>{fromDisplayName}</b> is hosting with a party of <b>{viewers}</b>.'**
  String hostEventMessage(String fromDisplayName, int viewers);

  /// Message displayed when a hype train event is in progress
  ///
  /// In en, this message translates to:
  /// **'Hype Train level <b>{level}</b> in progress! <b>{progressPercent}%</b> completed!'**
  String hypeTrainEventProgress(String level, String progressPercent);

  /// Message displayed when a hype train event ends successfully
  ///
  /// In en, this message translates to:
  /// **'Hype Train level <b>{level}</b> succeeded.'**
  String hypeTrainEventEndedSuccessful(int level);

  /// Message displayed when a hype train event ends unsuccessfully
  ///
  /// In en, this message translates to:
  /// **'Hype Train level <b>{level}</b> failed.'**
  String hypeTrainEventEndedUnsuccessful(int level);

  /// Sample message for text to speech
  ///
  /// In en, this message translates to:
  /// **'This is a sample message for text to speech.'**
  String get sampleMessage;

  /// Message for an action performed by the author
  ///
  /// In en, this message translates to:
  /// **'{author} {text}'**
  String actionMessage(String author, String text);

  /// Message for something said by the author
  ///
  /// In en, this message translates to:
  /// **'{author} said: {text}'**
  String saidMessage(String author, String text);

  /// Message indicating that text to speech has been enabled
  ///
  /// In en, this message translates to:
  /// **'Text to speech enabled'**
  String get textToSpeechEnabled;

  /// Message indicating that text to speech has been disabled
  ///
  /// In en, this message translates to:
  /// **'Text to speech disabled'**
  String get textToSpeechDisabled;

  /// Message indicating that alerts have been enabled
  ///
  /// In en, this message translates to:
  /// **'Alerts only'**
  String get alertsEnabled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'bn',
        'de',
        'en',
        'es',
        'fr',
        'it',
        'ja',
        'ko',
        'nl',
        'pl',
        'pt',
        'ru',
        'sv',
        'uk',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
