// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CircleVeya';

  @override
  String get discover => 'Discover';

  @override
  String get feed => 'Feed';

  @override
  String get createActivity => 'Create activity';

  @override
  String get create => 'Create';

  @override
  String get chats => 'Chats';

  @override
  String get events => 'Events';

  @override
  String get myActivities => 'My activities';

  @override
  String get loginSubtitle => 'Sign in to discover activities.';

  @override
  String get accountTypeHint =>
      'Choose whether to start as a private person or as an event profile (manager / business).';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'Invalid email';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordMinLength => 'At least 6 characters';

  @override
  String get nameRequired => 'Please enter a name';

  @override
  String get nameMinLength => 'At least 3 characters';

  @override
  String get groups => 'Circles';

  @override
  String get messages => 'Messages';

  @override
  String get friends => 'Friends';

  @override
  String get memories => 'Memories';

  @override
  String get challenges => 'Challenges';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get myProfile => 'My profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get edit => 'Edit';

  @override
  String get signOut => 'Sign out';

  @override
  String get notifications => 'Notifications';

  @override
  String get language => 'Language';

  @override
  String get german => 'German';

  @override
  String get english => 'English';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search…';

  @override
  String get location => 'Location';

  @override
  String get currentLocation => 'Current location';

  @override
  String get currentLocationGps => 'Current location (GPS)';

  @override
  String get searchPlaceHint => 'Search place (Zurich, Basel, Bern…)';

  @override
  String get applyLocation => 'Apply location';

  @override
  String get category => 'Category';

  @override
  String get allCategories => 'All categories';

  @override
  String get showAllCategories => 'Show events in all categories.';

  @override
  String get when => 'When?';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get thisWeekend => 'This weekend';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get allTime => 'All time';

  @override
  String get all => 'All';

  @override
  String get thisWeek => 'This week';

  @override
  String get pickDate => 'Choose date';

  @override
  String get distance => 'Distance';

  @override
  String get everywhere => 'Everywhere';

  @override
  String get done => 'Done';

  @override
  String get filter => 'Filter';

  @override
  String get share => 'Share';

  @override
  String get shareActivity => 'Share activity';

  @override
  String get copyLink => 'Copy link';

  @override
  String get copyLinkSubtitle => 'To clipboard';

  @override
  String get copyAsText => 'Copy as text';

  @override
  String get copyAsTextSubtitle => 'Title + link';

  @override
  String get shareToFriends => 'Send to friends';

  @override
  String get shareToFriendsHint =>
      'Tap a friend – the event goes to your direct message.';

  @override
  String get noFriendsToShare => 'No friends to share with yet.';

  @override
  String activitySentToFriend(String username) {
    return 'Sent to $username';
  }

  @override
  String shareActivityToFriend(String username) {
    return 'Send to $username';
  }

  @override
  String get shareActivityMessageHint => 'Message (optional)';

  @override
  String get shareActivitySend => 'Send';

  @override
  String get privateProfileSetting => 'Private profile';

  @override
  String get privateProfileSettingSubtitle =>
      'Only friends and acquaintances can see bio, activities, level and gallery.';

  @override
  String get privateProfileTitle => 'Private profile';

  @override
  String privateProfileBody(String username) {
    return '$username\'s content is only visible to friends and acquaintances.';
  }

  @override
  String get profileNowPrivate => 'Profile is now private';

  @override
  String get profileNowPublic => 'Profile is now public';

  @override
  String get linkCopied => 'Link copied – ready to send';

  @override
  String get textCopied => 'Text with link copied';

  @override
  String get join => 'Join';

  @override
  String get expressInterest => 'Express interest';

  @override
  String get withFriendsToEvent => 'Go with friends';

  @override
  String get toEventSource => 'To event source';

  @override
  String participants(int count) {
    return '$count participants';
  }

  @override
  String host(String name) {
    return 'Host: $name';
  }

  @override
  String get login => 'Log in';

  @override
  String get register => 'Sign up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get username => 'Username';

  @override
  String get accountType => 'Account type';

  @override
  String get privatePerson => 'Private person';

  @override
  String get eventProfile => 'Event profile';

  @override
  String get createEventProfile => 'Create event profile';

  @override
  String get privatePersonDesc =>
      'For people who want to join and meet friends.';

  @override
  String get eventProfileDesc =>
      'For event managers and businesses that upload events.';

  @override
  String get nameOrBrand => 'Name / brand';

  @override
  String get writeMessage => 'Message…';

  @override
  String get emoji => 'Emoji';

  @override
  String get searchGif => 'Search GIF';

  @override
  String get noChatsYet => 'No chats yet';

  @override
  String get newChat => 'New chat';

  @override
  String get deleteChat => 'Delete chat';

  @override
  String get premium => 'Premium';

  @override
  String get dev => 'Dev';

  @override
  String get marketing => 'Marketing';

  @override
  String get event => 'Event';

  @override
  String level(int level) {
    return 'Level $level';
  }

  @override
  String yearsOld(int age) {
    return '$age years';
  }

  @override
  String get ageNotSet => 'Age not set';

  @override
  String get recommendedForYou => 'Recommended for you';

  @override
  String get yourChallenges => 'Your challenges';

  @override
  String get friendsOnline => 'Friends online';

  @override
  String get noFriendsOnline => 'No friends online right now.';

  @override
  String get noRecommendations =>
      'No recommendations – add interests in your profile.';

  @override
  String get trending => 'Trending';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Try again';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get registerTitle => 'Create account';

  @override
  String get noAccount => 'No account yet? Sign up';

  @override
  String get haveAccount => 'Already have an account? Log in';

  @override
  String get direct => 'Direct';

  @override
  String get activity => 'Activity';

  @override
  String get circle => 'Circle';

  @override
  String get image => 'Image';

  @override
  String get gif => 'GIF';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get writeFirstMessage => 'Write the first message…';

  @override
  String get profilePictureUpdated => 'Profile photo updated';

  @override
  String get bannerUpdated => 'Banner updated';

  @override
  String locationApplied(String name) {
    return 'Location: $name';
  }

  @override
  String placeNotFound(String query) {
    return '“$query” not found. Keep typing – suggestions appear greyed out (Tab / → / Enter).';
  }

  @override
  String get gpsTaken => 'Location taken from GPS.';

  @override
  String get mockLocationHint =>
      'Test location active. GPS or a place chip overrides the mock.';

  @override
  String get finish => 'Done';

  @override
  String get searchPlaceholderDiscover => 'Find people. Create memories.';

  @override
  String get aboutMe => 'About';

  @override
  String get activities => 'Activities';

  @override
  String get gallery => 'Gallery';

  @override
  String get reviews => 'Reviews';

  @override
  String get levelTab => 'Level';

  @override
  String get follow => 'Follow';

  @override
  String get following => 'Following';

  @override
  String get unfollow => 'Unfollow';

  @override
  String get followers => 'Followers';

  @override
  String followersCount(int count) {
    return '$count followers';
  }

  @override
  String get oneFollower => '1 follower';

  @override
  String get companies => 'Companies';

  @override
  String get acquaintances => 'Acquaintances';

  @override
  String get acquaintance => 'Acquaintance';

  @override
  String get friend => 'Friend';

  @override
  String get noConnectionsYet => 'No connections yet';

  @override
  String get searchPeopleOrCompanies => 'Search people & companies';

  @override
  String get followHint =>
      'Search for people as friends or follow companies / event profiles.';

  @override
  String get noCompaniesFollowed => 'No companies followed yet.';

  @override
  String get noProfilesFound => 'No profiles found.';

  @override
  String get addAsFriend => 'Add as friend';

  @override
  String get addAsAcquaintance => 'Add as acquaintance';

  @override
  String get companyFollowing => 'Company · Following';

  @override
  String get companyCanFollow => 'Company · Follow';

  @override
  String get eventProfileShort => 'Event profile';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get weeklyChallengesHint =>
      'Weekly challenges reset every Monday, monthly ones on the 1st of the month.';

  @override
  String get otherChallenges => 'More challenges';

  @override
  String get noActiveChallenges => 'No active challenges.';

  @override
  String get businessNoLevelTitle => 'No personal level';

  @override
  String get businessNoLevelBody =>
      'Event and company profiles have no personal level or challenge system.\n\nSoon you’ll be able to create one monthly challenge for your followers.';

  @override
  String get businessPanelHint =>
      'No personal level. Followers and events come first.';

  @override
  String currentBadge(String name) {
    return 'Current badge: $name';
  }

  @override
  String unlockedBadges(int count) {
    return 'Unlocked ($count)';
  }

  @override
  String lockedBadges(int count) {
    return 'Still locked ($count)';
  }

  @override
  String get noBadgesYet => 'No badges unlocked yet.';

  @override
  String get noBadgeYetHint => 'No badge yet – Spark awaits you at level 5.';

  @override
  String badgeLockedHint(int level, String description) {
    return 'Still locked. Reach level $level to unlock this badge.\n\n$description';
  }

  @override
  String badgeStillLocked(int level) {
    return 'Still locked – unlocks at level $level';
  }

  @override
  String get unlockedBadgesHint => 'Badges you have already earned.';

  @override
  String get lockedBadgesHint => 'Upcoming badges – tap to preview.';

  @override
  String get levelBadges => 'Level badges';

  @override
  String levelBadgesWithName(String name) {
    return 'Level badges · $name';
  }

  @override
  String xpRemaining(int xp, int level) {
    return '$xp XP left until level $level';
  }

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get bio => 'Bio';

  @override
  String get topInterests => 'Top interests';

  @override
  String get noInterestsYet => 'No interests added yet.';

  @override
  String get noActivitiesYet =>
      'No activities yet.\nCreate one or join a friend’s.';

  @override
  String get noVisibleActivities => 'No visible activities.';

  @override
  String get resetFilters => 'Reset search / filters';

  @override
  String get reset => 'Reset';

  @override
  String showEventsIn(String category) {
    return 'Show events in $category.';
  }

  @override
  String get catAll => 'All categories';

  @override
  String get catConcerts => 'Concerts';

  @override
  String get catParties => 'Parties';

  @override
  String get catFestivals => 'Festivals';

  @override
  String get catTheater => 'Theater & stage';

  @override
  String get catComedy => 'Comedy';

  @override
  String get catSport => 'Sports & fitness';

  @override
  String get catKids => 'Kids & family';

  @override
  String get catCourses => 'Courses & seminars';

  @override
  String get catMarkets => 'Markets & fairs';

  @override
  String get catClassic => 'Classical & opera';

  @override
  String get catLeisure => 'Leisure & trips';

  @override
  String get catOther => 'Other';

  @override
  String get phraseAll => 'all categories';

  @override
  String get phraseConcerts => 'concerts';

  @override
  String get phraseParties => 'parties';

  @override
  String get phraseFestivals => 'festivals';

  @override
  String get phraseTheater => 'theater & stage';

  @override
  String get phraseComedy => 'comedy';

  @override
  String get phraseSport => 'sports & fitness';

  @override
  String get phraseKids => 'kids & family';

  @override
  String get phraseCourses => 'courses & seminars';

  @override
  String get phraseMarkets => 'markets & fairs';

  @override
  String get phraseClassic => 'classical & opera';

  @override
  String get phraseLeisure => 'leisure & trips';

  @override
  String get phraseOther => 'other';

  @override
  String get feedFromFriends => 'Activities from friends and acquaintances';

  @override
  String get noFeedYet =>
      'No activities from friends or acquaintances yet.\nAdd friends to see their events here.';

  @override
  String get searchFriendsHint => 'Search friends or profiles…';

  @override
  String get searchActivitiesHint => 'Search activities…';

  @override
  String get searchMessagesHint => 'Search chats…';

  @override
  String get searchFeedHint => 'Search feed…';

  @override
  String get searchDiscoverHint => 'Search events…';

  @override
  String get searchEverything => 'Everything';

  @override
  String searchResults(String context) {
    return 'Results · $context';
  }

  @override
  String get applyPlace => 'Apply place';

  @override
  String get weeklyReset => 'Resets every Monday';

  @override
  String get monthlyReset => 'Resets on the 1st of the month';

  @override
  String get onceOnly => 'One-time';

  @override
  String get challenge => 'Challenge';

  @override
  String get nearby => 'Nearby';

  @override
  String get actionJoin => 'I\'m in!';

  @override
  String get actionInterested => 'Interested';

  @override
  String get actionJoined => 'Going';

  @override
  String get actionInterestSent => 'Interest sent';

  @override
  String get actionFull => 'Sold out';

  @override
  String get actionYourEvent => 'Your event';

  @override
  String get actionExternal => 'Open source';

  @override
  String levelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get discoverHeroHint => 'What do you want to experience today?';

  @override
  String get optionalComment => 'Optional comment';

  @override
  String get tellAboutYou => 'Tell us a bit about yourself…';

  @override
  String get interestExample => 'e.g. go-kart, football';

  @override
  String get interestInputHint =>
      'e.g. go-kart, football – press Enter to add';

  @override
  String get activityTitleHint => 'e.g. go-karting';

  @override
  String get locationExampleHint => 'e.g. Berlin Mitte';

  @override
  String get gifSearchHint => 'Search GIFs…';

  @override
  String get activitySingular => 'activity';

  @override
  String get activityPlural => 'activities';

  @override
  String get challengeHowToWeekly =>
      'Create or join activities – counts this week (resets Monday).';

  @override
  String get challengeHowToMonthly =>
      'Create or join activities – counts this month (resets on the 1st).';

  @override
  String get challengeHowToSocial =>
      'Make new friendships – counts this month (resets on the 1st).';

  @override
  String get challengeHowToSport =>
      'Join sports/outdoor activities – counts this month (resets on the 1st).';

  @override
  String get challengeHowToDefault => 'Complete the goal to claim the reward.';

  @override
  String get weatherCold => 'Cold';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherSun => 'Sun';

  @override
  String get newBadge => 'New';

  @override
  String get selfCreatedBadge => 'Created';

  @override
  String get clearSearch => 'Clear';

  @override
  String get targetAudiences => 'Audiences';

  @override
  String get friendsCanJoin => 'Can join directly';

  @override
  String get acquaintancesCanInterest => 'Can show interest';

  @override
  String get strangersAudience => 'Strangers / like-minded';

  @override
  String get strangersSubtitle => 'Radius-based, show interest';

  @override
  String discoveryRadius(int km) {
    return 'Discovery radius: $km km';
  }

  @override
  String radiusFreePremiumHint(int freeKm, int premiumKm) {
    return 'Free: max. $freeKm km · Premium: up to $premiumKm km';
  }

  @override
  String get settingsSubtitle => 'Manage account and test features';

  @override
  String get accountTypePerson => 'Private person';

  @override
  String get accountTypeEvent => 'Event profile';

  @override
  String get accountTypeCompany => 'Company';

  @override
  String get progress => 'Progress';

  @override
  String rewardXp(int xp) {
    return 'Reward: $xp XP';
  }

  @override
  String get howToComplete => 'How to complete';

  @override
  String get challengeNotFound => 'Challenge not found.';

  @override
  String get claimReward => 'Claim reward';

  @override
  String get challengeComplete => 'Completed';

  @override
  String rewardClaimed(int xp) {
    return 'Reward claimed (+$xp XP)';
  }

  @override
  String get goToFriends => 'Go to friends';

  @override
  String get discoverActivities => 'Discover activities';

  @override
  String get getStarted => 'Get started';

  @override
  String get success => 'Success!';

  @override
  String get noExternalSource => 'No external source available';

  @override
  String get linkOpenFailed => 'Could not open link';

  @override
  String get tryAgain => 'Try again';

  @override
  String get weather => 'Weather';

  @override
  String maxDistanceKm(int km) {
    return 'max. $km km';
  }

  @override
  String get discoverSubtitle =>
      'Discover activities near you – with friends, the community, and events from your region.';

  @override
  String get daily => 'Daily';

  @override
  String get repeat => 'Repeat';

  @override
  String get noOwnActivitiesYet =>
      'No activities of your own yet.\nCreate one or join a friend’s.';

  @override
  String get noCurrentActivities =>
      'No upcoming activities.\nPast ones are below.';

  @override
  String get pastActivities => 'Past activities';

  @override
  String get galleryEmptyPast =>
      'No completed activities yet.\nAfter an event you can store your photos here.';

  @override
  String get noPhotosYetUpload => 'No photos yet.\nUpload your first memories.';

  @override
  String get noPhotosInMemory => 'No photos in this memory yet.';

  @override
  String get photoSingular => 'photo';

  @override
  String get photoPlural => 'photos';

  @override
  String get memoriesPrivateHint =>
      'Memories are private and only visible to the account owner.';

  @override
  String get noPublicMemories => 'No public memories yet.';

  @override
  String get noReviewsReceived => 'No reviews received yet.';

  @override
  String get noReviewsBeFirst => 'No reviews yet – be the first.';

  @override
  String get allReviews => 'All reviews';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get locationType => 'Location type';

  @override
  String get deleteAllNotifications => 'Delete all?';

  @override
  String get deleteAllNotificationsBody =>
      'All notifications will be permanently removed.';

  @override
  String get deleteAllTooltip => 'Delete all';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get noSearchHits => 'No matches in this area.';

  @override
  String challengeTitleWeekly(int count) {
    return '$count activities this week';
  }

  @override
  String challengeTitleMonthly(int count) {
    return '$count activities this month';
  }

  @override
  String challengeTitleSocial(int count) {
    return '$count new friends this month';
  }

  @override
  String challengeTitleSport(int count) {
    return '$count sports activities this month';
  }

  @override
  String get challengeDescWeekly =>
      'Join or create activities this week. Resets every Monday.';

  @override
  String get challengeDescMonthly =>
      'Join or create activities this month. Resets on the 1st.';

  @override
  String get challengeDescSocial =>
      'Make new friendships this month. Resets on the 1st.';

  @override
  String get challengeDescSport =>
      'Join sports/outdoor activities this month. Resets on the 1st.';

  @override
  String get deleteActivityTitle => 'Delete activity?';

  @override
  String get activityDeleted => 'Activity deleted';

  @override
  String get memoriesPublicTitle => 'Public memories';

  @override
  String get memoriesPublicOn => 'All your memories are visible to others.';

  @override
  String get memoriesPublicOff =>
      'When on, all memories become public automatically.';

  @override
  String get memoriesNowPublic => 'All memories are now public';

  @override
  String get memoriesNowPrivate => 'Memories are private';

  @override
  String get updateYourReview => 'Update your review';

  @override
  String get tapStarsToRate => 'Tap stars to rate';

  @override
  String get submitReview => 'Submit review';

  @override
  String get reviewConnectedOnly =>
      'You can only review people you\'re connected with.';

  @override
  String get saveReview => 'Save review';

  @override
  String get reviewSaved => 'Review saved';

  @override
  String get reviewSingular => 'Review';

  @override
  String reviewWithCount(int count) {
    return 'Review ($count)';
  }

  @override
  String get changeBanner => 'Change banner';

  @override
  String get changeProfilePhoto => 'Change profile photo';

  @override
  String deleteActivityBody(String title) {
    return '“$title” will be permanently deleted (including participants, interests, and chats).';
  }
}
