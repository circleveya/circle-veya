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

  @override
  String get aboutMe => 'Über mich';

  @override
  String get activities => 'Aktivitäten';

  @override
  String get gallery => 'Galerie';

  @override
  String get reviews => 'Bewertungen';

  @override
  String get levelTab => 'Level';

  @override
  String get follow => 'Folgen';

  @override
  String get following => 'Gefolgt';

  @override
  String get unfollow => 'Entfolgen';

  @override
  String get followers => 'Follower';

  @override
  String followersCount(int count) {
    return '$count Follower';
  }

  @override
  String get oneFollower => '1 Follower';

  @override
  String get companies => 'Unternehmen';

  @override
  String get acquaintances => 'Bekannte';

  @override
  String get acquaintance => 'Bekannter';

  @override
  String get friend => 'Freund';

  @override
  String get noConnectionsYet => 'Noch keine Verbindungen';

  @override
  String get searchPeopleOrCompanies => 'Personen & Unternehmen suchen';

  @override
  String get followHint =>
      'Suche Personen als Freunde oder folge Unternehmen / Event-Profilen.';

  @override
  String get noCompaniesFollowed => 'Noch keine Unternehmen gefolgt.';

  @override
  String get noProfilesFound => 'Keine Profile gefunden.';

  @override
  String get addAsFriend => 'Als Freund hinzufügen';

  @override
  String get addAsAcquaintance => 'Als Bekannten hinzufügen';

  @override
  String get companyFollowing => 'Unternehmen · Du folgst';

  @override
  String get companyCanFollow => 'Unternehmen · Folgen möglich';

  @override
  String get eventProfileShort => 'Event-Profil';

  @override
  String get weekly => 'Wöchentlich';

  @override
  String get monthly => 'Monatlich';

  @override
  String get weeklyChallengesHint =>
      'Wöchentliche Challenges starten montags neu, monatliche am 1. des Monats.';

  @override
  String get otherChallenges => 'Weitere Challenges';

  @override
  String get noActiveChallenges => 'Noch keine aktiven Challenges.';

  @override
  String get businessNoLevelTitle => 'Kein persönliches Level';

  @override
  String get businessNoLevelBody =>
      'Event- und Unternehmens-Profile haben kein Level- oder Challenge-System für dich persönlich.\n\nBald kannst du einmal pro Monat eine eigene Challenge für deine Follower erstellen.';

  @override
  String get businessPanelHint =>
      'Kein persönliches Level. Follower und Events stehen im Mittelpunkt.';

  @override
  String currentBadge(String name) {
    return 'Aktuelles Badge: $name';
  }

  @override
  String unlockedBadges(int count) {
    return 'Freigeschaltet ($count)';
  }

  @override
  String lockedBadges(int count) {
    return 'Noch offen ($count)';
  }

  @override
  String get noBadgesYet => 'Noch keine Badges freigeschaltet.';

  @override
  String get noBadgeYetHint =>
      'Noch kein Badge – ab Level 5 wartet Spark auf dich.';

  @override
  String badgeLockedHint(int level, String description) {
    return 'Noch gesperrt. Erreiche Level $level, um dieses Badge freizuschalten.\n\n$description';
  }

  @override
  String get levelBadges => 'Level-Badges ansehen';

  @override
  String levelBadgesWithName(String name) {
    return 'Level-Badges · $name';
  }

  @override
  String xpRemaining(int xp, int level) {
    return 'Noch $xp XP bis Level $level';
  }

  @override
  String get notSignedIn => 'Nicht angemeldet';

  @override
  String get bio => 'Bio';

  @override
  String get topInterests => 'Top Interessen';

  @override
  String get noInterestsYet => 'Noch keine Interessen hinterlegt.';

  @override
  String get noActivitiesYet =>
      'Noch keine Aktivitäten.\nErstelle eine oder sage bei Freunden zu.';

  @override
  String get noVisibleActivities => 'Keine sichtbaren Aktivitäten.';

  @override
  String get resetFilters => 'Suche / Filter zurücksetzen';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String showEventsIn(String category) {
    return 'Events in $category anzeigen.';
  }

  @override
  String get catAll => 'Alle Kategorien';

  @override
  String get catConcerts => 'Konzerte';

  @override
  String get catParties => 'Parties';

  @override
  String get catFestivals => 'Festivals';

  @override
  String get catTheater => 'Theater & Bühne';

  @override
  String get catComedy => 'Comedy';

  @override
  String get catSport => 'Sport & Fitness';

  @override
  String get catKids => 'Kinder & Familie';

  @override
  String get catCourses => 'Kurse & Seminare';

  @override
  String get catMarkets => 'Märkte & Messen';

  @override
  String get catClassic => 'Klassik & Oper';

  @override
  String get catLeisure => 'Freizeit & Ausflüge';

  @override
  String get catOther => 'Sonstiges';

  @override
  String get phraseAll => 'allen Kategorien';

  @override
  String get phraseConcerts => 'Konzerten';

  @override
  String get phraseParties => 'Parties';

  @override
  String get phraseFestivals => 'Festivals';

  @override
  String get phraseTheater => 'Theater & Bühne';

  @override
  String get phraseComedy => 'Comedy';

  @override
  String get phraseSport => 'Sport & Fitness';

  @override
  String get phraseKids => 'Kinder & Familie';

  @override
  String get phraseCourses => 'Kursen & Seminaren';

  @override
  String get phraseMarkets => 'Märkten & Messen';

  @override
  String get phraseClassic => 'Klassik & Oper';

  @override
  String get phraseLeisure => 'Freizeit & Ausflügen';

  @override
  String get phraseOther => 'Sonstigem';

  @override
  String get feedFromFriends => 'Aktivitäten von Freunden und Bekannten';

  @override
  String get noFeedYet =>
      'Noch keine Aktivitäten von Freunden oder Bekannten.\nFüge Freunde hinzu, um ihre Events hier zu sehen.';

  @override
  String get searchFriendsHint => 'Freunde oder Profile suchen …';

  @override
  String get searchActivitiesHint => 'Aktivitäten suchen …';

  @override
  String get searchMessagesHint => 'Chats suchen …';

  @override
  String get searchFeedHint => 'Im Feed suchen …';

  @override
  String get searchDiscoverHint => 'Events suchen …';

  @override
  String get searchEverything => 'Alles';

  @override
  String searchResults(String context) {
    return 'Ergebnisse · $context';
  }

  @override
  String get applyPlace => 'Ort übernehmen';

  @override
  String get weeklyReset => 'Reset jeden Montag';

  @override
  String get monthlyReset => 'Reset am 1. des Monats';

  @override
  String get onceOnly => 'Einmalig';

  @override
  String get challenge => 'Challenge';

  @override
  String get nearby => 'In der Nähe';

  @override
  String get actionJoin => 'Ich bin dabei!';

  @override
  String get actionInterested => 'Interessiert';

  @override
  String get actionJoined => 'Dabei';

  @override
  String get actionInterestSent => 'Interesse gesendet';

  @override
  String get actionFull => 'Ausgebucht';

  @override
  String get actionYourEvent => 'Dein Event';

  @override
  String get actionExternal => 'Zur Quelle';

  @override
  String levelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get discoverHeroHint => 'Was möchtest du heute erleben?';

  @override
  String get optionalComment => 'Optionaler Kommentar';

  @override
  String get tellAboutYou => 'Erzähl kurz etwas über dich …';

  @override
  String get interestExample => 'z.B. Go-Kart, Fußball';

  @override
  String get activityTitleHint => 'z.B. Go-Kart fahren';

  @override
  String get locationExampleHint => 'z.B. Berlin Mitte';

  @override
  String get gifSearchHint => 'GIF suchen …';

  @override
  String get activitySingular => 'Aktivität';

  @override
  String get activityPlural => 'Aktivitäten';

  @override
  String get challengeHowToWeekly =>
      'Erstelle oder nimm an Aktivitäten teil – zählt diese Woche (Reset Montag).';

  @override
  String get challengeHowToMonthly =>
      'Erstelle oder nimm an Aktivitäten teil – zählt diesen Monat (Reset am 1.).';

  @override
  String get challengeHowToSocial =>
      'Schließe neue Freundschaften – zählt diesen Monat (Reset am 1.).';

  @override
  String get challengeHowToSport =>
      'Nimm an Sport-/Outdoor-Aktivitäten teil – zählt diesen Monat (Reset am 1.).';

  @override
  String get challengeHowToDefault =>
      'Erfülle das Ziel, um die Belohnung abzuholen.';

  @override
  String get weatherCold => 'Kälte';

  @override
  String get weatherRain => 'Regen';

  @override
  String get weatherSun => 'Sonne';

  @override
  String get newBadge => 'Neu';

  @override
  String get clearSearch => 'Leeren';

  @override
  String get targetAudiences => 'Zielgruppen';

  @override
  String get friendsCanJoin => 'Direkt zusagen möglich';

  @override
  String get acquaintancesCanInterest => 'Können Interesse bekunden';

  @override
  String get strangersAudience => 'Fremde / Gleichgesinnte';

  @override
  String get strangersSubtitle => 'Radius-basiert, Interesse bekunden';

  @override
  String discoveryRadius(int km) {
    return 'Entdeckungs-Radius: $km km';
  }

  @override
  String radiusFreePremiumHint(int freeKm, int premiumKm) {
    return 'Free: max. $freeKm km · Premium: bis $premiumKm km';
  }

  @override
  String get settingsSubtitle => 'Account und Testfunktionen verwalten';

  @override
  String get accountTypePerson => 'Privatperson';

  @override
  String get accountTypeEvent => 'Event-Profil';

  @override
  String get accountTypeCompany => 'Unternehmen';

  @override
  String get progress => 'Fortschritt';

  @override
  String rewardXp(int xp) {
    return 'Belohnung: $xp XP';
  }

  @override
  String get howToComplete => 'So schließt du sie ab';

  @override
  String get challengeNotFound => 'Challenge nicht gefunden.';

  @override
  String get claimReward => 'Belohnung abholen';

  @override
  String get challengeComplete => 'Abgeschlossen';

  @override
  String rewardClaimed(int xp) {
    return 'Belohnung abgeholt (+$xp XP)';
  }

  @override
  String get goToFriends => 'Zu Freunden';

  @override
  String get discoverActivities => 'Aktivitäten entdecken';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get success => 'Erfolgreich!';

  @override
  String get noExternalSource => 'Keine externe Quelle verfügbar';

  @override
  String get linkOpenFailed => 'Link konnte nicht geöffnet werden';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get weather => 'Wetter';

  @override
  String maxDistanceKm(int km) {
    return 'max. $km km';
  }

  @override
  String get discoverSubtitle =>
      'Entdecke Aktivitäten in deiner Nähe – mit Freunden, der Community und Events aus deiner Region.';

  @override
  String get daily => 'Täglich';

  @override
  String get repeat => 'Wiederholen';

  @override
  String get noOwnActivitiesYet =>
      'Noch keine eigenen Aktivitäten.\nErstelle eine oder sage bei Freunden zu.';

  @override
  String get noCurrentActivities =>
      'Keine aktuellen Aktivitäten.\nVergangene findest du unten.';

  @override
  String get pastActivities => 'Vergangene Aktivitäten';

  @override
  String get galleryEmptyPast =>
      'Noch keine abgeschlossenen Aktivitäten.\nNach einem Event kannst du hier deine Fotos ablegen.';

  @override
  String get noPhotosYetUpload =>
      'Noch keine Fotos.\nLade deine ersten Erinnerungen hoch.';

  @override
  String get noPhotosInMemory => 'Noch keine Fotos in dieser Erinnerung.';

  @override
  String get photoSingular => 'Foto';

  @override
  String get photoPlural => 'Fotos';

  @override
  String get memoriesPrivateHint =>
      'Erinnerungen sind privat und nur für den Account-Inhaber sichtbar.';

  @override
  String get noPublicMemories => 'Noch keine öffentlichen Erinnerungen.';

  @override
  String get noReviewsReceived => 'Noch keine Bewertungen erhalten.';

  @override
  String get noReviewsBeFirst =>
      'Noch keine Bewertungen – sei die erste Person.';

  @override
  String get allReviews => 'Alle Bewertungen';

  @override
  String get addPhoto => 'Foto hinzufügen';

  @override
  String get locationType => 'Ort-Typ';

  @override
  String get deleteAllNotifications => 'Alle löschen?';

  @override
  String get deleteAllNotificationsBody =>
      'Alle Benachrichtigungen werden unwiderruflich entfernt.';

  @override
  String get deleteAllTooltip => 'Alle löschen';

  @override
  String get markAllRead => 'Alle gelesen';

  @override
  String get noNotifications => 'Keine Benachrichtigungen';

  @override
  String get noSearchHits => 'Keine Treffer in diesem Bereich.';

  @override
  String challengeTitleWeekly(int count) {
    return '$count Aktivitäten diese Woche';
  }

  @override
  String challengeTitleMonthly(int count) {
    return '$count Aktivitäten diesen Monat';
  }

  @override
  String challengeTitleSocial(int count) {
    return '$count neue Freunde diesen Monat';
  }

  @override
  String challengeTitleSport(int count) {
    return '$count Sport-Aktivitäten diesen Monat';
  }

  @override
  String get challengeDescWeekly =>
      'Nimm diese Woche an Aktivitäten teil oder erstelle eigene. Reset jeden Montag.';

  @override
  String get challengeDescMonthly =>
      'Nimm diesen Monat an Aktivitäten teil oder erstelle eigene. Reset am 1. des Monats.';

  @override
  String get challengeDescSocial =>
      'Schließe diesen Monat neue Freundschaften. Reset am 1. des Monats.';

  @override
  String get challengeDescSport =>
      'Nimm diesen Monat an Sport-/Outdoor-Aktivitäten teil. Reset am 1. des Monats.';

  @override
  String get deleteActivityTitle => 'Aktivität löschen?';

  @override
  String get activityDeleted => 'Aktivität gelöscht';

  @override
  String get memoriesPublicTitle => 'Erinnerungen öffentlich';

  @override
  String get memoriesPublicOn =>
      'Alle deine Erinnerungen sind für andere sichtbar.';

  @override
  String get memoriesPublicOff =>
      'Wenn aktiv, werden alle Erinnerungen automatisch öffentlich.';

  @override
  String get memoriesNowPublic => 'Alle Erinnerungen sind jetzt öffentlich';

  @override
  String get memoriesNowPrivate => 'Erinnerungen sind privat';

  @override
  String get updateYourReview => 'Deine Bewertung aktualisieren';

  @override
  String get tapStarsToRate => 'Sterne tippen zum Bewerten';

  @override
  String get submitReview => 'Bewertung absenden';

  @override
  String get saveReview => 'Bewertung speichern';

  @override
  String get reviewSaved => 'Bewertung gespeichert';

  @override
  String get reviewSingular => 'Bewertung';

  @override
  String reviewWithCount(int count) {
    return 'Bewertung ($count)';
  }

  @override
  String get changeBanner => 'Banner ändern';

  @override
  String get changeProfilePhoto => 'Profilbild ändern';

  @override
  String deleteActivityBody(String title) {
    return '„$title“ wird unwiderruflich gelöscht (inkl. Teilnehmer, Interessen und Chats).';
  }
}
