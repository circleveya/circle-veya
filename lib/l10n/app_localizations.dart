import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'CircleVeya'**
  String get appName;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @createActivity.
  ///
  /// In en, this message translates to:
  /// **'Create activity'**
  String get createActivity;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @myActivities.
  ///
  /// In en, this message translates to:
  /// **'My activities'**
  String get myActivities;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to discover activities.'**
  String get loginSubtitle;

  /// No description provided for @accountTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose whether to start as a private person or as an event profile (manager / business).'**
  String get accountTypeHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get nameRequired;

  /// No description provided for @nameMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 3 characters'**
  String get nameMinLength;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Circles'**
  String get groups;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @memories.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get memories;

  /// No description provided for @challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get searchHint;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @currentLocationGps.
  ///
  /// In en, this message translates to:
  /// **'Current location (GPS)'**
  String get currentLocationGps;

  /// No description provided for @searchPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'Search place (Zurich, Basel, Bern…)'**
  String get searchPlaceHint;

  /// No description provided for @applyLocation.
  ///
  /// In en, this message translates to:
  /// **'Apply location'**
  String get applyLocation;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @showAllCategories.
  ///
  /// In en, this message translates to:
  /// **'Show events in all categories.'**
  String get showAllCategories;

  /// No description provided for @when.
  ///
  /// In en, this message translates to:
  /// **'When?'**
  String get when;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @thisWeekend.
  ///
  /// In en, this message translates to:
  /// **'This weekend'**
  String get thisWeekend;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get pickDate;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @everywhere.
  ///
  /// In en, this message translates to:
  /// **'Everywhere'**
  String get everywhere;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareActivity.
  ///
  /// In en, this message translates to:
  /// **'Share activity'**
  String get shareActivity;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @copyLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To clipboard'**
  String get copyLinkSubtitle;

  /// No description provided for @copyAsText.
  ///
  /// In en, this message translates to:
  /// **'Copy as text'**
  String get copyAsText;

  /// No description provided for @copyAsTextSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Title + link'**
  String get copyAsTextSubtitle;

  /// No description provided for @shareToFriends.
  ///
  /// In en, this message translates to:
  /// **'Send to friends'**
  String get shareToFriends;

  /// No description provided for @shareToFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a friend – the event goes to your direct message.'**
  String get shareToFriendsHint;

  /// No description provided for @noFriendsToShare.
  ///
  /// In en, this message translates to:
  /// **'No friends to share with yet.'**
  String get noFriendsToShare;

  /// No description provided for @activitySentToFriend.
  ///
  /// In en, this message translates to:
  /// **'Sent to {username}'**
  String activitySentToFriend(String username);

  /// No description provided for @shareActivityToFriend.
  ///
  /// In en, this message translates to:
  /// **'Send to {username}'**
  String shareActivityToFriend(String username);

  /// No description provided for @shareActivityMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message (optional)'**
  String get shareActivityMessageHint;

  /// No description provided for @shareActivitySend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get shareActivitySend;

  /// No description provided for @privateProfileSetting.
  ///
  /// In en, this message translates to:
  /// **'Private profile'**
  String get privateProfileSetting;

  /// No description provided for @privateProfileSettingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only friends and acquaintances can see bio, activities, level and gallery.'**
  String get privateProfileSettingSubtitle;

  /// No description provided for @privateProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Private profile'**
  String get privateProfileTitle;

  /// No description provided for @privateProfileBody.
  ///
  /// In en, this message translates to:
  /// **'{username}\'s content is only visible to friends and acquaintances.'**
  String privateProfileBody(String username);

  /// No description provided for @profileNowPrivate.
  ///
  /// In en, this message translates to:
  /// **'Profile is now private'**
  String get profileNowPrivate;

  /// No description provided for @profileNowPublic.
  ///
  /// In en, this message translates to:
  /// **'Profile is now public'**
  String get profileNowPublic;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied – ready to send'**
  String get linkCopied;

  /// No description provided for @textCopied.
  ///
  /// In en, this message translates to:
  /// **'Text with link copied'**
  String get textCopied;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @expressInterest.
  ///
  /// In en, this message translates to:
  /// **'Express interest'**
  String get expressInterest;

  /// No description provided for @withFriendsToEvent.
  ///
  /// In en, this message translates to:
  /// **'Go with friends'**
  String get withFriendsToEvent;

  /// No description provided for @toEventSource.
  ///
  /// In en, this message translates to:
  /// **'To event source'**
  String get toEventSource;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String participants(int count);

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host: {name}'**
  String host(String name);

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get accountType;

  /// No description provided for @privatePerson.
  ///
  /// In en, this message translates to:
  /// **'Private person'**
  String get privatePerson;

  /// No description provided for @eventProfile.
  ///
  /// In en, this message translates to:
  /// **'Event profile'**
  String get eventProfile;

  /// No description provided for @createEventProfile.
  ///
  /// In en, this message translates to:
  /// **'Create event profile'**
  String get createEventProfile;

  /// No description provided for @privatePersonDesc.
  ///
  /// In en, this message translates to:
  /// **'For people who want to join and meet friends.'**
  String get privatePersonDesc;

  /// No description provided for @eventProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'For event managers and businesses that upload events.'**
  String get eventProfileDesc;

  /// No description provided for @nameOrBrand.
  ///
  /// In en, this message translates to:
  /// **'Name / brand'**
  String get nameOrBrand;

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get writeMessage;

  /// No description provided for @emoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get emoji;

  /// No description provided for @searchGif.
  ///
  /// In en, this message translates to:
  /// **'Search GIF'**
  String get searchGif;

  /// No description provided for @noChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noChatsYet;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChat;

  /// No description provided for @deleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get deleteChat;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @dev.
  ///
  /// In en, this message translates to:
  /// **'Dev'**
  String get dev;

  /// No description provided for @marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get marketing;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String level(int level);

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age} years'**
  String yearsOld(int age);

  /// No description provided for @ageNotSet.
  ///
  /// In en, this message translates to:
  /// **'Age not set'**
  String get ageNotSet;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendedForYou;

  /// No description provided for @yourChallenges.
  ///
  /// In en, this message translates to:
  /// **'Your challenges'**
  String get yourChallenges;

  /// No description provided for @friendsOnline.
  ///
  /// In en, this message translates to:
  /// **'Friends online'**
  String get friendsOnline;

  /// No description provided for @noFriendsOnline.
  ///
  /// In en, this message translates to:
  /// **'No friends online right now.'**
  String get noFriendsOnline;

  /// No description provided for @noRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No recommendations – add interests in your profile.'**
  String get noRecommendations;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account yet? Sign up'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get haveAccount;

  /// No description provided for @direct.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get direct;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @circle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get circle;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @gif.
  ///
  /// In en, this message translates to:
  /// **'GIF'**
  String get gif;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @writeFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Write the first message…'**
  String get writeFirstMessage;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePictureUpdated;

  /// No description provided for @bannerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Banner updated'**
  String get bannerUpdated;

  /// No description provided for @locationApplied.
  ///
  /// In en, this message translates to:
  /// **'Location: {name}'**
  String locationApplied(String name);

  /// No description provided for @placeNotFound.
  ///
  /// In en, this message translates to:
  /// **'“{query}” not found. Keep typing – suggestions appear highlighted in blue (Tab / → / Enter).'**
  String placeNotFound(String query);

  /// No description provided for @gpsTaken.
  ///
  /// In en, this message translates to:
  /// **'Location taken from GPS.'**
  String get gpsTaken;

  /// No description provided for @mockLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Test location active. GPS or a place chip overrides the mock.'**
  String get mockLocationHint;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get finish;

  /// No description provided for @searchPlaceholderDiscover.
  ///
  /// In en, this message translates to:
  /// **'Find people. Create memories.'**
  String get searchPlaceholderDiscover;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutMe;

  /// No description provided for @activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activities;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @levelTab.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get levelTab;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @followersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} followers'**
  String followersCount(int count);

  /// No description provided for @oneFollower.
  ///
  /// In en, this message translates to:
  /// **'1 follower'**
  String get oneFollower;

  /// No description provided for @companies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get companies;

  /// No description provided for @acquaintances.
  ///
  /// In en, this message translates to:
  /// **'Acquaintances'**
  String get acquaintances;

  /// No description provided for @acquaintance.
  ///
  /// In en, this message translates to:
  /// **'Acquaintance'**
  String get acquaintance;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friend;

  /// No description provided for @noConnectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No connections yet'**
  String get noConnectionsYet;

  /// No description provided for @searchPeopleOrCompanies.
  ///
  /// In en, this message translates to:
  /// **'Search people & companies'**
  String get searchPeopleOrCompanies;

  /// No description provided for @followHint.
  ///
  /// In en, this message translates to:
  /// **'Search for people as friends or follow companies / event profiles.'**
  String get followHint;

  /// No description provided for @noCompaniesFollowed.
  ///
  /// In en, this message translates to:
  /// **'No companies followed yet.'**
  String get noCompaniesFollowed;

  /// No description provided for @noProfilesFound.
  ///
  /// In en, this message translates to:
  /// **'No profiles found.'**
  String get noProfilesFound;

  /// No description provided for @addAsFriend.
  ///
  /// In en, this message translates to:
  /// **'Add as friend'**
  String get addAsFriend;

  /// No description provided for @addAsAcquaintance.
  ///
  /// In en, this message translates to:
  /// **'Add as acquaintance'**
  String get addAsAcquaintance;

  /// No description provided for @companyFollowing.
  ///
  /// In en, this message translates to:
  /// **'Company · Following'**
  String get companyFollowing;

  /// No description provided for @companyCanFollow.
  ///
  /// In en, this message translates to:
  /// **'Company · Follow'**
  String get companyCanFollow;

  /// No description provided for @eventProfileShort.
  ///
  /// In en, this message translates to:
  /// **'Event profile'**
  String get eventProfileShort;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @weeklyChallengesHint.
  ///
  /// In en, this message translates to:
  /// **'Weekly challenges reset every Monday, monthly ones on the 1st of the month.'**
  String get weeklyChallengesHint;

  /// No description provided for @otherChallenges.
  ///
  /// In en, this message translates to:
  /// **'More challenges'**
  String get otherChallenges;

  /// No description provided for @noActiveChallenges.
  ///
  /// In en, this message translates to:
  /// **'No active challenges.'**
  String get noActiveChallenges;

  /// No description provided for @businessNoLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'No personal level'**
  String get businessNoLevelTitle;

  /// No description provided for @businessNoLevelBody.
  ///
  /// In en, this message translates to:
  /// **'Event and company profiles have no personal level or challenge system.\n\nSoon you’ll be able to create one monthly challenge for your followers.'**
  String get businessNoLevelBody;

  /// No description provided for @businessPanelHint.
  ///
  /// In en, this message translates to:
  /// **'No personal level. Followers and events come first.'**
  String get businessPanelHint;

  /// No description provided for @currentBadge.
  ///
  /// In en, this message translates to:
  /// **'Current badge: {name}'**
  String currentBadge(String name);

  /// No description provided for @unlockedBadges.
  ///
  /// In en, this message translates to:
  /// **'Unlocked ({count})'**
  String unlockedBadges(int count);

  /// No description provided for @lockedBadges.
  ///
  /// In en, this message translates to:
  /// **'Still locked ({count})'**
  String lockedBadges(int count);

  /// No description provided for @noBadgesYet.
  ///
  /// In en, this message translates to:
  /// **'No badges unlocked yet.'**
  String get noBadgesYet;

  /// No description provided for @noBadgeYetHint.
  ///
  /// In en, this message translates to:
  /// **'No badge yet – Spark awaits you at level 5.'**
  String get noBadgeYetHint;

  /// No description provided for @badgeLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Still locked. Reach level {level} to unlock this badge.\n\n{description}'**
  String badgeLockedHint(int level, String description);

  /// No description provided for @badgeStillLocked.
  ///
  /// In en, this message translates to:
  /// **'Still locked – unlocks at level {level}'**
  String badgeStillLocked(int level);

  /// No description provided for @unlockedBadgesHint.
  ///
  /// In en, this message translates to:
  /// **'Badges you have already earned.'**
  String get unlockedBadgesHint;

  /// No description provided for @lockedBadgesHint.
  ///
  /// In en, this message translates to:
  /// **'Upcoming badges – tap to preview.'**
  String get lockedBadgesHint;

  /// No description provided for @levelBadges.
  ///
  /// In en, this message translates to:
  /// **'Level badges'**
  String get levelBadges;

  /// No description provided for @levelBadgesWithName.
  ///
  /// In en, this message translates to:
  /// **'Level badges · {name}'**
  String levelBadgesWithName(String name);

  /// No description provided for @xpRemaining.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP left until level {level}'**
  String xpRemaining(int xp, int level);

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @topInterests.
  ///
  /// In en, this message translates to:
  /// **'Top interests'**
  String get topInterests;

  /// No description provided for @noInterestsYet.
  ///
  /// In en, this message translates to:
  /// **'No interests added yet.'**
  String get noInterestsYet;

  /// No description provided for @noActivitiesYet.
  ///
  /// In en, this message translates to:
  /// **'No activities yet.\nCreate one or join a friend’s.'**
  String get noActivitiesYet;

  /// No description provided for @noVisibleActivities.
  ///
  /// In en, this message translates to:
  /// **'No visible activities.'**
  String get noVisibleActivities;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset search / filters'**
  String get resetFilters;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @showEventsIn.
  ///
  /// In en, this message translates to:
  /// **'Show events in {category}.'**
  String showEventsIn(String category);

  /// No description provided for @catAll.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get catAll;

  /// No description provided for @catConcerts.
  ///
  /// In en, this message translates to:
  /// **'Concerts'**
  String get catConcerts;

  /// No description provided for @catParties.
  ///
  /// In en, this message translates to:
  /// **'Parties'**
  String get catParties;

  /// No description provided for @catFestivals.
  ///
  /// In en, this message translates to:
  /// **'Festivals'**
  String get catFestivals;

  /// No description provided for @catTheater.
  ///
  /// In en, this message translates to:
  /// **'Theater & stage'**
  String get catTheater;

  /// No description provided for @catComedy.
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get catComedy;

  /// No description provided for @catSport.
  ///
  /// In en, this message translates to:
  /// **'Sports & fitness'**
  String get catSport;

  /// No description provided for @catKids.
  ///
  /// In en, this message translates to:
  /// **'Kids & family'**
  String get catKids;

  /// No description provided for @catCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses & seminars'**
  String get catCourses;

  /// No description provided for @catMarkets.
  ///
  /// In en, this message translates to:
  /// **'Markets & fairs'**
  String get catMarkets;

  /// No description provided for @catClassic.
  ///
  /// In en, this message translates to:
  /// **'Classical & opera'**
  String get catClassic;

  /// No description provided for @catLeisure.
  ///
  /// In en, this message translates to:
  /// **'Leisure & trips'**
  String get catLeisure;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @phraseAll.
  ///
  /// In en, this message translates to:
  /// **'all categories'**
  String get phraseAll;

  /// No description provided for @phraseConcerts.
  ///
  /// In en, this message translates to:
  /// **'concerts'**
  String get phraseConcerts;

  /// No description provided for @phraseParties.
  ///
  /// In en, this message translates to:
  /// **'parties'**
  String get phraseParties;

  /// No description provided for @phraseFestivals.
  ///
  /// In en, this message translates to:
  /// **'festivals'**
  String get phraseFestivals;

  /// No description provided for @phraseTheater.
  ///
  /// In en, this message translates to:
  /// **'theater & stage'**
  String get phraseTheater;

  /// No description provided for @phraseComedy.
  ///
  /// In en, this message translates to:
  /// **'comedy'**
  String get phraseComedy;

  /// No description provided for @phraseSport.
  ///
  /// In en, this message translates to:
  /// **'sports & fitness'**
  String get phraseSport;

  /// No description provided for @phraseKids.
  ///
  /// In en, this message translates to:
  /// **'kids & family'**
  String get phraseKids;

  /// No description provided for @phraseCourses.
  ///
  /// In en, this message translates to:
  /// **'courses & seminars'**
  String get phraseCourses;

  /// No description provided for @phraseMarkets.
  ///
  /// In en, this message translates to:
  /// **'markets & fairs'**
  String get phraseMarkets;

  /// No description provided for @phraseClassic.
  ///
  /// In en, this message translates to:
  /// **'classical & opera'**
  String get phraseClassic;

  /// No description provided for @phraseLeisure.
  ///
  /// In en, this message translates to:
  /// **'leisure & trips'**
  String get phraseLeisure;

  /// No description provided for @phraseOther.
  ///
  /// In en, this message translates to:
  /// **'other'**
  String get phraseOther;

  /// No description provided for @feedFromFriends.
  ///
  /// In en, this message translates to:
  /// **'Activities from friends and acquaintances'**
  String get feedFromFriends;

  /// No description provided for @noFeedYet.
  ///
  /// In en, this message translates to:
  /// **'No activities from friends or acquaintances yet.\nAdd friends to see their events here.'**
  String get noFeedYet;

  /// No description provided for @searchFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Search friends or profiles…'**
  String get searchFriendsHint;

  /// No description provided for @searchActivitiesHint.
  ///
  /// In en, this message translates to:
  /// **'Search activities…'**
  String get searchActivitiesHint;

  /// No description provided for @searchMessagesHint.
  ///
  /// In en, this message translates to:
  /// **'Search chats…'**
  String get searchMessagesHint;

  /// No description provided for @searchFeedHint.
  ///
  /// In en, this message translates to:
  /// **'Search feed…'**
  String get searchFeedHint;

  /// No description provided for @searchDiscoverHint.
  ///
  /// In en, this message translates to:
  /// **'Search events…'**
  String get searchDiscoverHint;

  /// No description provided for @searchEverything.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get searchEverything;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Results · {context}'**
  String searchResults(String context);

  /// No description provided for @applyPlace.
  ///
  /// In en, this message translates to:
  /// **'Apply place'**
  String get applyPlace;

  /// No description provided for @weeklyReset.
  ///
  /// In en, this message translates to:
  /// **'Resets every Monday'**
  String get weeklyReset;

  /// No description provided for @monthlyReset.
  ///
  /// In en, this message translates to:
  /// **'Resets on the 1st of the month'**
  String get monthlyReset;

  /// No description provided for @onceOnly.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get onceOnly;

  /// No description provided for @challenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challenge;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @actionJoin.
  ///
  /// In en, this message translates to:
  /// **'I\'m in!'**
  String get actionJoin;

  /// No description provided for @actionInterested.
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get actionInterested;

  /// No description provided for @actionJoined.
  ///
  /// In en, this message translates to:
  /// **'Going'**
  String get actionJoined;

  /// No description provided for @actionInterestSent.
  ///
  /// In en, this message translates to:
  /// **'Interest sent'**
  String get actionInterestSent;

  /// No description provided for @actionFull.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get actionFull;

  /// No description provided for @actionYourEvent.
  ///
  /// In en, this message translates to:
  /// **'Your event'**
  String get actionYourEvent;

  /// No description provided for @actionExternal.
  ///
  /// In en, this message translates to:
  /// **'Open source'**
  String get actionExternal;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelLabel(int level);

  /// No description provided for @discoverHeroHint.
  ///
  /// In en, this message translates to:
  /// **'What do you want to experience today?'**
  String get discoverHeroHint;

  /// No description provided for @optionalComment.
  ///
  /// In en, this message translates to:
  /// **'Optional comment'**
  String get optionalComment;

  /// No description provided for @tellAboutYou.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself…'**
  String get tellAboutYou;

  /// No description provided for @interestExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. go-kart, football'**
  String get interestExample;

  /// No description provided for @interestInputHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. go-kart, football – press Enter to add'**
  String get interestInputHint;

  /// No description provided for @activityTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. go-karting'**
  String get activityTitleHint;

  /// No description provided for @locationExampleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Berlin Mitte'**
  String get locationExampleHint;

  /// No description provided for @gifSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search GIFs…'**
  String get gifSearchHint;

  /// No description provided for @activitySingular.
  ///
  /// In en, this message translates to:
  /// **'activity'**
  String get activitySingular;

  /// No description provided for @activityPlural.
  ///
  /// In en, this message translates to:
  /// **'activities'**
  String get activityPlural;

  /// No description provided for @challengeHowToWeekly.
  ///
  /// In en, this message translates to:
  /// **'Create or join activities – counts this week (resets Monday).'**
  String get challengeHowToWeekly;

  /// No description provided for @challengeHowToMonthly.
  ///
  /// In en, this message translates to:
  /// **'Create or join activities – counts this month (resets on the 1st).'**
  String get challengeHowToMonthly;

  /// No description provided for @challengeHowToSocial.
  ///
  /// In en, this message translates to:
  /// **'Make new friendships – counts this month (resets on the 1st).'**
  String get challengeHowToSocial;

  /// No description provided for @challengeHowToSport.
  ///
  /// In en, this message translates to:
  /// **'Join sports/outdoor activities – counts this month (resets on the 1st).'**
  String get challengeHowToSport;

  /// No description provided for @challengeHowToDefault.
  ///
  /// In en, this message translates to:
  /// **'Complete the goal to claim the reward.'**
  String get challengeHowToDefault;

  /// No description provided for @weatherCold.
  ///
  /// In en, this message translates to:
  /// **'Cold'**
  String get weatherCold;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weatherSun;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newBadge;

  /// No description provided for @selfCreatedBadge.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get selfCreatedBadge;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSearch;

  /// No description provided for @targetAudiences.
  ///
  /// In en, this message translates to:
  /// **'Audiences'**
  String get targetAudiences;

  /// No description provided for @friendsCanJoin.
  ///
  /// In en, this message translates to:
  /// **'Can join directly'**
  String get friendsCanJoin;

  /// No description provided for @acquaintancesCanInterest.
  ///
  /// In en, this message translates to:
  /// **'Can show interest'**
  String get acquaintancesCanInterest;

  /// No description provided for @strangersAudience.
  ///
  /// In en, this message translates to:
  /// **'Strangers / like-minded'**
  String get strangersAudience;

  /// No description provided for @strangersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Radius-based, show interest'**
  String get strangersSubtitle;

  /// No description provided for @discoveryRadius.
  ///
  /// In en, this message translates to:
  /// **'Discovery radius: {km} km'**
  String discoveryRadius(int km);

  /// No description provided for @radiusFreePremiumHint.
  ///
  /// In en, this message translates to:
  /// **'Free: max. {freeKm} km · Premium: up to {premiumKm} km'**
  String radiusFreePremiumHint(int freeKm, int premiumKm);

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage account and test features'**
  String get settingsSubtitle;

  /// No description provided for @accountTypePerson.
  ///
  /// In en, this message translates to:
  /// **'Private person'**
  String get accountTypePerson;

  /// No description provided for @accountTypeEvent.
  ///
  /// In en, this message translates to:
  /// **'Event profile'**
  String get accountTypeEvent;

  /// No description provided for @accountTypeCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get accountTypeCompany;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @rewardXp.
  ///
  /// In en, this message translates to:
  /// **'Reward: {xp} XP'**
  String rewardXp(int xp);

  /// No description provided for @howToComplete.
  ///
  /// In en, this message translates to:
  /// **'How to complete'**
  String get howToComplete;

  /// No description provided for @challengeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Challenge not found.'**
  String get challengeNotFound;

  /// No description provided for @claimReward.
  ///
  /// In en, this message translates to:
  /// **'Claim reward'**
  String get claimReward;

  /// No description provided for @challengeComplete.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get challengeComplete;

  /// No description provided for @rewardClaimed.
  ///
  /// In en, this message translates to:
  /// **'Reward claimed (+{xp} XP)'**
  String rewardClaimed(int xp);

  /// No description provided for @goToFriends.
  ///
  /// In en, this message translates to:
  /// **'Go to friends'**
  String get goToFriends;

  /// No description provided for @discoverActivities.
  ///
  /// In en, this message translates to:
  /// **'Discover activities'**
  String get discoverActivities;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get success;

  /// No description provided for @noExternalSource.
  ///
  /// In en, this message translates to:
  /// **'No external source available'**
  String get noExternalSource;

  /// No description provided for @linkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get linkOpenFailed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @maxDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'max. {km} km'**
  String maxDistanceKm(int km);

  /// No description provided for @discoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover activities near you – with friends, the community, and events from your region.'**
  String get discoverSubtitle;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @noOwnActivitiesYet.
  ///
  /// In en, this message translates to:
  /// **'No activities of your own yet.\nCreate one or join a friend’s.'**
  String get noOwnActivitiesYet;

  /// No description provided for @noCurrentActivities.
  ///
  /// In en, this message translates to:
  /// **'No upcoming activities.\nPast ones are below.'**
  String get noCurrentActivities;

  /// No description provided for @pastActivities.
  ///
  /// In en, this message translates to:
  /// **'Past activities'**
  String get pastActivities;

  /// No description provided for @galleryEmptyPast.
  ///
  /// In en, this message translates to:
  /// **'No completed activities yet.\nAfter an event you can store your photos here.'**
  String get galleryEmptyPast;

  /// No description provided for @noPhotosYetUpload.
  ///
  /// In en, this message translates to:
  /// **'No photos yet.\nUpload your first memories.'**
  String get noPhotosYetUpload;

  /// No description provided for @noPhotosInMemory.
  ///
  /// In en, this message translates to:
  /// **'No photos in this memory yet.'**
  String get noPhotosInMemory;

  /// No description provided for @photoSingular.
  ///
  /// In en, this message translates to:
  /// **'photo'**
  String get photoSingular;

  /// No description provided for @photoPlural.
  ///
  /// In en, this message translates to:
  /// **'photos'**
  String get photoPlural;

  /// No description provided for @memoriesPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Memories are private and only visible to the account owner.'**
  String get memoriesPrivateHint;

  /// No description provided for @noPublicMemories.
  ///
  /// In en, this message translates to:
  /// **'No public memories yet.'**
  String get noPublicMemories;

  /// No description provided for @noReviewsReceived.
  ///
  /// In en, this message translates to:
  /// **'No reviews received yet.'**
  String get noReviewsReceived;

  /// No description provided for @noReviewsBeFirst.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet – be the first.'**
  String get noReviewsBeFirst;

  /// No description provided for @allReviews.
  ///
  /// In en, this message translates to:
  /// **'All reviews'**
  String get allReviews;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @locationType.
  ///
  /// In en, this message translates to:
  /// **'Location type'**
  String get locationType;

  /// No description provided for @deleteAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Delete all?'**
  String get deleteAllNotifications;

  /// No description provided for @deleteAllNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'All notifications will be permanently removed.'**
  String get deleteAllNotificationsBody;

  /// No description provided for @deleteAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAllTooltip;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @noSearchHits.
  ///
  /// In en, this message translates to:
  /// **'No matches in this area.'**
  String get noSearchHits;

  /// No description provided for @challengeTitleWeekly.
  ///
  /// In en, this message translates to:
  /// **'{count} activities this week'**
  String challengeTitleWeekly(int count);

  /// No description provided for @challengeTitleMonthly.
  ///
  /// In en, this message translates to:
  /// **'{count} activities this month'**
  String challengeTitleMonthly(int count);

  /// No description provided for @challengeTitleSocial.
  ///
  /// In en, this message translates to:
  /// **'{count} new friends this month'**
  String challengeTitleSocial(int count);

  /// No description provided for @challengeTitleSport.
  ///
  /// In en, this message translates to:
  /// **'{count} sports activities this month'**
  String challengeTitleSport(int count);

  /// No description provided for @challengeDescWeekly.
  ///
  /// In en, this message translates to:
  /// **'Join or create activities this week. Resets every Monday.'**
  String get challengeDescWeekly;

  /// No description provided for @challengeDescMonthly.
  ///
  /// In en, this message translates to:
  /// **'Join or create activities this month. Resets on the 1st.'**
  String get challengeDescMonthly;

  /// No description provided for @challengeDescSocial.
  ///
  /// In en, this message translates to:
  /// **'Make new friendships this month. Resets on the 1st.'**
  String get challengeDescSocial;

  /// No description provided for @challengeDescSport.
  ///
  /// In en, this message translates to:
  /// **'Join sports/outdoor activities this month. Resets on the 1st.'**
  String get challengeDescSport;

  /// No description provided for @deleteActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete activity?'**
  String get deleteActivityTitle;

  /// No description provided for @activityDeleted.
  ///
  /// In en, this message translates to:
  /// **'Activity deleted'**
  String get activityDeleted;

  /// No description provided for @memoriesPublicTitle.
  ///
  /// In en, this message translates to:
  /// **'Public memories'**
  String get memoriesPublicTitle;

  /// No description provided for @memoriesPublicOn.
  ///
  /// In en, this message translates to:
  /// **'All your memories are visible to others.'**
  String get memoriesPublicOn;

  /// No description provided for @memoriesPublicOff.
  ///
  /// In en, this message translates to:
  /// **'When on, all memories become public automatically.'**
  String get memoriesPublicOff;

  /// No description provided for @memoriesNowPublic.
  ///
  /// In en, this message translates to:
  /// **'All memories are now public'**
  String get memoriesNowPublic;

  /// No description provided for @memoriesNowPrivate.
  ///
  /// In en, this message translates to:
  /// **'Memories are private'**
  String get memoriesNowPrivate;

  /// No description provided for @updateYourReview.
  ///
  /// In en, this message translates to:
  /// **'Update your review'**
  String get updateYourReview;

  /// No description provided for @tapStarsToRate.
  ///
  /// In en, this message translates to:
  /// **'Tap stars to rate'**
  String get tapStarsToRate;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get submitReview;

  /// No description provided for @reviewConnectedOnly.
  ///
  /// In en, this message translates to:
  /// **'You can only review people you\'re connected with.'**
  String get reviewConnectedOnly;

  /// No description provided for @saveReview.
  ///
  /// In en, this message translates to:
  /// **'Save review'**
  String get saveReview;

  /// No description provided for @reviewSaved.
  ///
  /// In en, this message translates to:
  /// **'Review saved'**
  String get reviewSaved;

  /// No description provided for @reviewSingular.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewSingular;

  /// No description provided for @reviewWithCount.
  ///
  /// In en, this message translates to:
  /// **'Review ({count})'**
  String reviewWithCount(int count);

  /// No description provided for @changeBanner.
  ///
  /// In en, this message translates to:
  /// **'Change banner'**
  String get changeBanner;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changeProfilePhoto;

  /// No description provided for @deleteActivityBody.
  ///
  /// In en, this message translates to:
  /// **'“{title}” will be permanently deleted (including participants, interests, and chats).'**
  String deleteActivityBody(String title);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
