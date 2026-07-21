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
}
