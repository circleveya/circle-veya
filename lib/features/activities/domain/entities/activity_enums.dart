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

  String get label => switch (this) {
        friend => 'Freund',
        acquaintance => 'Bekannter',
        stranger => 'In der Nähe',
      };
}
