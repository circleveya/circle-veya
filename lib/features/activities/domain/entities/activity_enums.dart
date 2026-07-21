import '../../../../l10n/app_localizations.dart';

enum ViewerAction {
  directJoin,
  interest,
  joined,
  interestPending,
  host,
  full,
  externalLink,
  none;

  static ViewerAction fromDb(String value) => switch (value) {
        'direct_join' => directJoin,
        'interest' => interest,
        'joined' => joined,
        'interest_pending' => interestPending,
        'host' => host,
        'full' => full,
        'external_link' => externalLink,
        _ => none,
      };

  String localizedButtonLabel(AppLocalizations l10n) => switch (this) {
        directJoin => l10n.actionJoin,
        interest => l10n.actionInterested,
        joined => l10n.actionJoined,
        interestPending => l10n.actionInterestSent,
        full => l10n.actionFull,
        host => l10n.actionYourEvent,
        externalLink => l10n.actionExternal,
        none => '',
      };

  @Deprecated('Use localizedButtonLabel(AppLocalizations)')
  String get buttonLabel => switch (this) {
        directJoin => 'Ich bin dabei!',
        interest => 'Interessiert',
        joined => 'Dabei',
        interestPending => 'Interesse gesendet',
        full => 'Ausgebucht',
        host => 'Dein Event',
        externalLink => 'Zur Quelle',
        none => '',
      };

  bool get canTap =>
      this == directJoin || this == interest || this == externalLink;
}

enum VisibleAs {
  friend,
  acquaintance,
  stranger;

  static VisibleAs fromDb(String value) => switch (value) {
        'friend' => friend,
        'acquaintance' => acquaintance,
        _ => stranger,
      };

  String localizedLabel(AppLocalizations l10n) => switch (this) {
        friend => l10n.friend,
        acquaintance => l10n.acquaintance,
        stranger => l10n.nearby,
      };

  @Deprecated('Use localizedLabel(AppLocalizations)')
  String get label => switch (this) {
        friend => 'Freund',
        acquaintance => 'Bekannter',
        stranger => 'In der Nähe',
      };
}
