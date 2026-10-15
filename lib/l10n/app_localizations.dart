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

  /// Message displayed when a subscriber pays for multiple months at once
  ///
  /// In en, this message translates to:
  /// **'<b>{subscriberUserName}</b> has subscribed at Tier {tier} for {durationMonths} months in advance, {cumulativeMonths} months in total!'**
  String subscriptionMessageMultiMonthEvent(String subscriberUserName,
      String tier, int durationMonths, int cumulativeMonths);

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

  /// Label for the slider controlling how long an event stays pinned
  ///
  /// In en, this message translates to:
  /// **'Pin Duration'**
  String get pinDuration;

  /// A duration in seconds
  ///
  /// In en, this message translates to:
  /// **'{seconds,plural, =1{1 second} other{{seconds} seconds}}'**
  String durationSeconds(int seconds);

  /// A duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes,plural, =1{1 minute} other{{minutes} minutes}}'**
  String durationMinutes(int minutes);

  /// Title of the switch that enables an event type
  ///
  /// In en, this message translates to:
  /// **'Enable event'**
  String get enableEvent;

  /// Subtitle of the switch that enables an event type
  ///
  /// In en, this message translates to:
  /// **'Show event in chat history'**
  String get showEventInChatHistory;

  /// Title of the switch that enables the shoutout button on raids
  ///
  /// In en, this message translates to:
  /// **'Enable shoutouts'**
  String get enableShoutouts;

  /// Subtitle of the switch that enables the shoutout button on raids
  ///
  /// In en, this message translates to:
  /// **'Send a link to the raiding channel to chat'**
  String get enableShoutoutsSubtitle;

  /// Title of the raid event settings screen
  ///
  /// In en, this message translates to:
  /// **'Raid Configuration'**
  String get raidConfigurationTitle;

  /// Title of the cheer event settings screen
  ///
  /// In en, this message translates to:
  /// **'Cheer Configuration'**
  String get cheerConfigurationTitle;

  /// Title of the follow event settings screen
  ///
  /// In en, this message translates to:
  /// **'Follow Configuration'**
  String get followConfigurationTitle;

  /// Title of the outgoing raid event settings screen
  ///
  /// In en, this message translates to:
  /// **'Outgoing Raid Configuration'**
  String get outgoingRaidConfigurationTitle;

  /// Title of the host event settings screen
  ///
  /// In en, this message translates to:
  /// **'Host Configuration'**
  String get hostConfigurationTitle;

  /// Title of the channel point event settings screen
  ///
  /// In en, this message translates to:
  /// **'Channel Point Configuration'**
  String get channelPointConfigurationTitle;

  /// Title of the poll event settings screen
  ///
  /// In en, this message translates to:
  /// **'Poll Configuration'**
  String get pollConfigurationTitle;

  /// Title of the hype train event settings screen
  ///
  /// In en, this message translates to:
  /// **'Hypetrain Configuration'**
  String get hypetrainConfigurationTitle;

  /// Title of the subscription event settings screen
  ///
  /// In en, this message translates to:
  /// **'Subscription Configuration'**
  String get subscriptionConfigurationTitle;

  /// Title of the prediction event settings screen
  ///
  /// In en, this message translates to:
  /// **'Prediction Configuration'**
  String get predictionConfigurationTitle;

  /// Label for the slider adding pin time to unfulfilled channel point rewards
  ///
  /// In en, this message translates to:
  /// **'Additional Pin Duration for Unfulfilled Rewards'**
  String get unfulfilledRewardsPinDuration;

  /// Label for the slider controlling how long a finished poll stays pinned
  ///
  /// In en, this message translates to:
  /// **'Pin duration after the result is finalized'**
  String get pollPinDuration;

  /// Label for the slider controlling how long a finished hype train stays pinned
  ///
  /// In en, this message translates to:
  /// **'Pin duration after hypetrain is over'**
  String get hypetrainPinDuration;

  /// Title of the switch that shows each gifted subscription
  ///
  /// In en, this message translates to:
  /// **'Enable individual gifted subscriptions'**
  String get enableGiftedSubscriptions;

  /// Subtitle of the switch that shows each gifted subscription
  ///
  /// In en, this message translates to:
  /// **'Show every subscription that is gifted'**
  String get enableGiftedSubscriptionsSubtitle;

  /// Title of the settings backup screen
  ///
  /// In en, this message translates to:
  /// **'Settings backup and restore'**
  String get settingsBackupTitle;

  /// Heading for cloud backup options
  ///
  /// In en, this message translates to:
  /// **'Cloud backup'**
  String get cloudBackup;

  /// Shown when no backup has been made
  ///
  /// In en, this message translates to:
  /// **'Last backup: never'**
  String get lastBackupNever;

  /// Button that backs up settings
  ///
  /// In en, this message translates to:
  /// **'Back up'**
  String get backUp;

  /// Button that restores settings from a backup
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// Heading for local backup options
  ///
  /// In en, this message translates to:
  /// **'Local backup'**
  String get localBackup;

  /// Button that exports settings to a file
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportSettings;

  /// Button that imports settings from a file
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importSettings;

  /// Switch that shows viewer and follower counts in the header
  ///
  /// In en, this message translates to:
  /// **'Show viewer and follower count'**
  String get showViewerAndFollowerCount;

  /// Heading for the screen orientation setting
  ///
  /// In en, this message translates to:
  /// **'Screen orientation'**
  String get screenOrientation;

  /// Heading for the app theme setting
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get appTheme;

  /// Option to follow the system setting
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemDefault;

  /// Portrait screen orientation option
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get portrait;

  /// Landscape screen orientation option
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get landscape;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// Title of the link to the source code
  ///
  /// In en, this message translates to:
  /// **'RealtimeChat is open source'**
  String get openSourceTitle;

  /// Subtitle of the link to the source code
  ///
  /// In en, this message translates to:
  /// **'Find us on GitHub!'**
  String get openSourceSubtitle;

  /// Subtitle of the link to the Discord server
  ///
  /// In en, this message translates to:
  /// **'Join the Muxable Discord!'**
  String get discordSubtitle;

  /// Heading above the list of early testers
  ///
  /// In en, this message translates to:
  /// **'Thanks to all the early testers who sent bug reports!'**
  String get earlyTestersThanks;

  /// Shown when the disco mode easter egg is enabled
  ///
  /// In en, this message translates to:
  /// **'🕺 Disco mode enabled! :D'**
  String get discoModeEnabled;

  /// Shown when the disco mode easter egg is disabled
  ///
  /// In en, this message translates to:
  /// **'🕺 Disco mode disabled D:'**
  String get discoModeDisabled;

  /// Button that plays a sample text to speech message
  ///
  /// In en, this message translates to:
  /// **'Play sample message'**
  String get playSampleMessage;

  /// Label for the text to speech rate slider
  ///
  /// In en, this message translates to:
  /// **'Text to Speech Rate'**
  String get textToSpeechRate;

  /// Label for the text to speech pitch slider
  ///
  /// In en, this message translates to:
  /// **'Text to Speech Pitch'**
  String get textToSpeechPitch;

  /// Switch that skips messages from bots
  ///
  /// In en, this message translates to:
  /// **'Mute text to speech for bots'**
  String get muteBots;

  /// Switch that skips emotes
  ///
  /// In en, this message translates to:
  /// **'Mute all emotes in text to speech'**
  String get muteEmotes;

  /// Switch that skips reading viewer names
  ///
  /// In en, this message translates to:
  /// **'Mute viewer names in text to speech'**
  String get muteViewerNames;

  /// Switch that only reads messages from subscribers
  ///
  /// In en, this message translates to:
  /// **'Subscribers only'**
  String get subscribersOnly;

  /// Label for the chat font size slider
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// Label for the slider that brightens username colors
  ///
  /// In en, this message translates to:
  /// **'Username contrast boost'**
  String get usernameContrastBoost;

  /// Title of the link to badge settings
  ///
  /// In en, this message translates to:
  /// **'Twitch badge settings'**
  String get twitchBadgeSettings;

  /// Subtitle of the link to badge settings
  ///
  /// In en, this message translates to:
  /// **'Control which badges are visible'**
  String get twitchBadgeSettingsSubtitle;

  /// Switch that keeps deleted messages visible
  ///
  /// In en, this message translates to:
  /// **'Show deleted messages'**
  String get showDeletedMessages;

  /// Subtitle when deleted messages are shown
  ///
  /// In en, this message translates to:
  /// **'Deleted messages will be greyed out'**
  String get deletedMessagesGreyedOut;

  /// Subtitle when deleted messages are hidden
  ///
  /// In en, this message translates to:
  /// **'Deleted messages will be removed'**
  String get deletedMessagesRemoved;

  /// Switch that shows login names next to display names
  ///
  /// In en, this message translates to:
  /// **'Show login names'**
  String get showLoginNames;

  /// Subtitle when login names are shown
  ///
  /// In en, this message translates to:
  /// **'Login names will be shown if they are different from the display name'**
  String get loginNamesShown;

  /// Subtitle when login names are hidden
  ///
  /// In en, this message translates to:
  /// **'Login names will be hidden'**
  String get loginNamesHidden;

  /// Heading for message compaction options
  ///
  /// In en, this message translates to:
  /// **'Compact messages'**
  String get compactMessages;

  /// Option that leaves messages unchanged
  ///
  /// In en, this message translates to:
  /// **'Don\'t compact messages'**
  String get dontCompactMessages;

  /// Subtitle of the option that leaves messages unchanged
  ///
  /// In en, this message translates to:
  /// **'Messages are shown unchanged'**
  String get dontCompactMessagesSubtitle;

  /// Option that shortens repetitive text within a message
  ///
  /// In en, this message translates to:
  /// **'Compact individual messages'**
  String get compactIndividualMessages;

  /// Subtitle of the option that shortens repetitive text
  ///
  /// In en, this message translates to:
  /// **'Repetitive text in messages is shortened'**
  String get compactIndividualMessagesSubtitle;

  /// Label for the slider controlling how long announcements stay pinned
  ///
  /// In en, this message translates to:
  /// **'Announcement pin duration'**
  String get announcementPinDuration;

  /// Heading for the idle chat alert setting
  ///
  /// In en, this message translates to:
  /// **'Idle message alert duration'**
  String get idleMessageAlertDuration;

  /// Explanation of the idle chat alert setting
  ///
  /// In en, this message translates to:
  /// **'If there aren\'t any messages for this amount of time and a new one comes in, an alert sound will play.'**
  String get idleMessageAlertDurationSubtitle;

  /// Subtitle of the RealtimeCash integration
  ///
  /// In en, this message translates to:
  /// **'Connect an ETH or MATIC wallet'**
  String get realtimeCashSubtitle;

  /// Hint for the crypto wallet address field
  ///
  /// In en, this message translates to:
  /// **'Wallet address'**
  String get walletAddress;

  /// Subtitle of the Streamlabs integration
  ///
  /// In en, this message translates to:
  /// **'See your Streamlabs donations'**
  String get streamlabsSubtitle;

  /// Subtitle of the StreamElements integration
  ///
  /// In en, this message translates to:
  /// **'See your StreamElements donations'**
  String get streamElementsSubtitle;

  /// Shown when connecting a third-party service fails
  ///
  /// In en, this message translates to:
  /// **'Hmm, that didn\'t work. Try again, or ask on Discord?'**
  String get thirdPartyAuthError;

  /// Shown when the browser can't sign in directly
  ///
  /// In en, this message translates to:
  /// **'Your browser is too old to support signing in directly. Scan this QR code with your phone to sign in on another device.'**
  String get companionAuthBrowserTooOld;

  /// Instructions for signing in with a QR code
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code with your phone to sign in on another device.'**
  String get companionAuthScanQrCode;

  /// A new Kick subscription
  ///
  /// In en, this message translates to:
  /// **'<b>{subscriberName}</b> has subscribed!'**
  String kickSubscriptionEvent(String subscriberName);

  /// A renewed Kick subscription
  ///
  /// In en, this message translates to:
  /// **'<b>{subscriberName}</b> has resubscribed for {months} months!'**
  String kickResubscriptionEvent(String subscriberName, int months);

  /// Gifted Kick subscriptions
  ///
  /// In en, this message translates to:
  /// **'<b>{gifterName}</b> has gifted {count} subs!'**
  String kickGiftedSubscriptionsEvent(String gifterName, int count);

  /// Kicks (Kick's virtual currency) sent to the streamer
  ///
  /// In en, this message translates to:
  /// **'<b>{senderName}</b> sent {amount} Kicks!'**
  String kicksGiftedEvent(String senderName, int amount);

  /// Button to sign in with a Kick account
  ///
  /// In en, this message translates to:
  /// **'Sign in with Kick'**
  String get signInWithKick;

  /// Spoken when text to speech turns itself off because too many messages are waiting to be read
  ///
  /// In en, this message translates to:
  /// **'There are too many messages. Text to speech disabled'**
  String get textToSpeechTooManyMessages;

  /// Button in the text to speech notification that turns text to speech off
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get turnOffTextToSpeech;

  /// Button to add a channel to the default channels
  ///
  /// In en, this message translates to:
  /// **'Add channel'**
  String get addChannel;

  /// Button on a channel search result that adds the channel to the channels shown in chat
  ///
  /// In en, this message translates to:
  /// **'Add to chat'**
  String get addToChat;

  /// Title of the settings page for the channels the app opens with
  ///
  /// In en, this message translates to:
  /// **'Default channels'**
  String get defaultChannels;

  /// Explains what the default channels are
  ///
  /// In en, this message translates to:
  /// **'The channels shown when the app opens'**
  String get defaultChannelsSubtitle;

  /// Button on the default channels page that saves the channels currently shown as the default channels
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Button on the default channels page that clears the picked default channels, so the app opens the signed-in user's own channel, and closes the page
  ///
  /// In en, this message translates to:
  /// **'Reset to my channel'**
  String get resetToMyChannel;

  /// Heading in the channel search sheet for the channels currently shown in chat
  ///
  /// In en, this message translates to:
  /// **'In chat'**
  String get inChat;

  /// Button that removes a channel from the channels shown in chat
  ///
  /// In en, this message translates to:
  /// **'Remove from chat'**
  String get removeFromChat;

  /// Hint in the disabled message input when none of the channels shown are on the platform of the signed-in account
  ///
  /// In en, this message translates to:
  /// **'Your {provider} account can\'t chat here'**
  String cantChatWithAccount(String provider);

  /// Shown while swiping a channel search result whose platform already has a channel in chat: adding it replaces that channel
  ///
  /// In en, this message translates to:
  /// **'Replace {channel}'**
  String replaceChannel(String channel);

  /// Shown while swiping a default channel away to remove it from the default channels
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeChannel;

  /// Title of the screen that lists the neural voice packs that can be downloaded, and of the row in the text to speech settings that opens it
  ///
  /// In en, this message translates to:
  /// **'Voice packs'**
  String get voicePacks;

  /// Introduction at the top of the voice packs screen; it must say that the voices are generated by AI
  ///
  /// In en, this message translates to:
  /// **'Voice packs read chat with natural-sounding voices that run on your device, offline once downloaded. The voices are machine-generated by AI, not recorded by a person.'**
  String get voicePacksDescription;

  /// Under a voice pack's name: how many voices it has and its size (the download size, or the space it takes once installed)
  ///
  /// In en, this message translates to:
  /// **'{voices, plural, =1{1 voice} other{{voices} voices}} · {size}'**
  String voicePackDetails(int voices, String size);

  /// The languages a voice pack speaks: how many, then their names, separated by commas
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 language} other{{count} languages}}: {languages}'**
  String voicePackLanguages(int count, String languages);

  /// Use restrictions of a voice pack's license, which must be passed on to users; keep OpenRAIL-M as is
  ///
  /// In en, this message translates to:
  /// **'This model\'s license (OpenRAIL-M) forbids harmful uses, such as impersonating people or spreading disinformation, and these restrictions apply to you too.'**
  String get voicePackOpenRailNotice;

  /// Confirmation before deleting a voice pack
  ///
  /// In en, this message translates to:
  /// **'Delete {pack}? This frees {size}.'**
  String voicePackDeleteConfirm(String pack, String size);

  /// Button that downloads and installs a voice pack, or tries again after a failed download
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get voicePackDownload;

  /// Button that downloads a newer version of an installed voice pack
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get voicePackUpdate;

  /// A voice pack download waits for a Wi-Fi connection to start
  ///
  /// In en, this message translates to:
  /// **'Waiting for Wi-Fi'**
  String get voicePackWaitingForWifi;

  /// Button that downloads a voice pack over mobile data instead of waiting for Wi-Fi
  ///
  /// In en, this message translates to:
  /// **'Use mobile data'**
  String get voicePackUseMobileData;

  /// Progress of a voice pack download
  ///
  /// In en, this message translates to:
  /// **'Downloading: {downloaded} of {total}'**
  String voicePackDownloading(String downloaded, String total);

  /// A downloaded voice pack is being checked and installed
  ///
  /// In en, this message translates to:
  /// **'Installing'**
  String get voicePackInstalling;

  /// A voice pack failed to download or install
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t install {pack}. Check your connection and try again.'**
  String voicePackInstallFailed(String pack);
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
