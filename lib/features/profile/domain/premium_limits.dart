/// Limits für Free vs. Premium (Client + Server müssen übereinstimmen).
abstract final class PremiumLimits {
  static const freeRadiusKm = 20.0;
  static const premiumRadiusKm = 100.0;
  static const minRadiusKm = 5.0;

  static const freeMaxSlots = 2;
  static const premiumMaxSlots = 12;

  static double maxRadiusKm({required bool isPremium}) =>
      isPremium ? premiumRadiusKm : freeRadiusKm;

  static int maxSlots({required bool isPremium}) =>
      isPremium ? premiumMaxSlots : freeMaxSlots;
}
