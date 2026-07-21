// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'CircleVeya';

  @override
  String get discover => 'Entdecken';

  @override
  String get feed => 'Feed';

  @override
  String get createActivity => 'Aktivität erstellen';

  @override
  String get create => 'Erstellen';

  @override
  String get chats => 'Chats';

  @override
  String get events => 'Events';

  @override
  String get myActivities => 'Meine Aktivitäten';

  @override
  String get loginSubtitle => 'Melde dich an, um Aktivitäten zu entdecken.';

  @override
  String get accountTypeHint =>
      'Wähle, ob du als Privatperson oder als Event-Profil (Manager / Geschäft) starten möchtest.';

  @override
  String get emailRequired => 'Bitte E-Mail eingeben';

  @override
  String get emailInvalid => 'Ungültige E-Mail';

  @override
  String get passwordRequired => 'Bitte Passwort eingeben';

  @override
  String get passwordMinLength => 'Mindestens 6 Zeichen';

  @override
  String get nameRequired => 'Bitte Namen eingeben';

  @override
  String get nameMinLength => 'Mindestens 3 Zeichen';

  @override
  String get groups => 'Kreise';

  @override
  String get messages => 'Nachrichten';

  @override
  String get friends => 'Freunde';

  @override
  String get memories => 'Erinnerungen';

  @override
  String get challenges => 'Challenges';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Einstellungen';

  @override
  String get myProfile => 'Mein Profil';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get signOut => 'Abmelden';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get language => 'Sprache';

  @override
  String get german => 'Deutsch';

  @override
  String get english => 'Englisch';

  @override
  String get search => 'Suchen';

  @override
  String get searchHint => 'Suchen…';

  @override
  String get location => 'Standort';

  @override
  String get currentLocation => 'Aktueller Standort';

  @override
  String get currentLocationGps => 'Aktueller Standort (GPS)';

  @override
  String get searchPlaceHint => 'Ort suchen (Zürich, Basel, Bern…)';

  @override
  String get applyLocation => 'Ort übernehmen';

  @override
  String get category => 'Kategorie';

  @override
  String get allCategories => 'Alle Kategorien';

  @override
  String get showAllCategories => 'Events in allen Kategorien anzeigen.';

  @override
  String get when => 'Wann?';

  @override
  String get today => 'Heute';

  @override
  String get tomorrow => 'Morgen';

  @override
  String get thisWeekend => 'Dieses Wochenende';

  @override
  String get from => 'Von';

  @override
  String get to => 'Bis';

  @override
  String get allTime => 'Gesamtzeit';

  @override
  String get all => 'Alle';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get pickDate => 'Datum wählen';

  @override
  String get distance => 'Entfernung';

  @override
  String get everywhere => 'Überall';

  @override
  String get done => 'Fertig';

  @override
  String get filter => 'Filter';

  @override
  String get share => 'Teilen';

  @override
  String get shareActivity => 'Aktivität teilen';

  @override
  String get copyLink => 'Link kopieren';

  @override
  String get copyLinkSubtitle => 'In die Zwischenablage';

  @override
  String get copyAsText => 'Als Text kopieren';

  @override
  String get copyAsTextSubtitle => 'Titel + Link';

  @override
  String get linkCopied => 'Link kopiert – bereit zum Versenden';

  @override
  String get textCopied => 'Text mit Link kopiert';

  @override
  String get join => 'Zusagen';

  @override
  String get expressInterest => 'Interesse bekunden';

  @override
  String get withFriendsToEvent => 'Mit Freunden zum Event';

  @override
  String get toEventSource => 'Zur Event-Quelle';

  @override
  String participants(int count) {
    return '$count Teilnehmer';
  }

  @override
  String host(String name) {
    return 'Host: $name';
  }

  @override
  String get login => 'Anmelden';

  @override
  String get register => 'Registrieren';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get username => 'Benutzername';

  @override
  String get accountType => 'Konto-Typ';

  @override
  String get privatePerson => 'Privatperson';

  @override
  String get eventProfile => 'Event-Profil';

  @override
  String get privatePersonDesc =>
      'Für Leute, die mitmachen und Freunde treffen wollen.';

  @override
  String get eventProfileDesc =>
      'Für Event-Manager und Geschäfte, die Events hochladen.';

  @override
  String get nameOrBrand => 'Name / Marke';

  @override
  String get writeMessage => 'Nachricht …';

  @override
  String get emoji => 'Emoji';

  @override
  String get searchGif => 'GIF suchen';

  @override
  String get noChatsYet => 'Noch keine Chats';

  @override
  String get newChat => 'Neuer Chat';

  @override
  String get deleteChat => 'Chat löschen';

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
    return '$age Jahre';
  }

  @override
  String get ageNotSet => 'Alter nicht angegeben';

  @override
  String get recommendedForYou => 'Für dich empfohlen';

  @override
  String get yourChallenges => 'Deine Challenges';

  @override
  String get friendsOnline => 'Freunde online';

  @override
  String get noFriendsOnline => 'Keine Freunde gerade online.';

  @override
  String get noRecommendations =>
      'Keine Empfehlungen – Interessen im Profil ergänzen.';

  @override
  String get trending => 'Im Trend';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get loading => 'Laden…';

  @override
  String get retry => 'Erneut laden';

  @override
  String get errorGeneric => 'Etwas ist schiefgelaufen';

  @override
  String get loginTitle => 'Willkommen zurück';

  @override
  String get registerTitle => 'Konto erstellen';

  @override
  String get noAccount => 'Noch kein Konto? Registrieren';

  @override
  String get haveAccount => 'Schon ein Konto? Anmelden';

  @override
  String get direct => 'Direkt';

  @override
  String get activity => 'Aktivität';

  @override
  String get circle => 'Kreis';

  @override
  String get image => 'Bild';

  @override
  String get gif => 'GIF';

  @override
  String get noMessagesYet => 'Noch keine Nachrichten';

  @override
  String get writeFirstMessage => 'Schreib die erste Nachricht …';

  @override
  String get profilePictureUpdated => 'Profilbild aktualisiert';

  @override
  String get bannerUpdated => 'Banner aktualisiert';

  @override
  String locationApplied(String name) {
    return 'Standort: $name';
  }

  @override
  String placeNotFound(String query) {
    return '„$query“ nicht gefunden. Tippe weiter – Vorschläge erscheinen ausgegraut (Tab / → / Enter).';
  }

  @override
  String get gpsTaken => 'Standort per GPS übernommen.';

  @override
  String get mockLocationHint =>
      'Test-Standort aktiv. GPS oder Ort-Chip überschreibt den Mock.';

  @override
  String get finish => 'Fertig';

  @override
  String get searchPlaceholderDiscover =>
      'Menschen finden. Erinnerungen schaffen.';
}
