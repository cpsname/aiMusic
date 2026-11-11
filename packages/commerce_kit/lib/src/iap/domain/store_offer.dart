import 'package:meta/meta.dart';

/// The store platform a product was fetched from.
enum StoreType {
  appStore,
  playStore,
  web;

  String get displayName => switch (this) {
    StoreType.appStore => 'App Store',
    StoreType.playStore => 'Google Play',
    StoreType.web => 'Web',
  };
}

/// Unit of time for a subscription period.
enum PeriodUnit { day, week, month, year }

/// Cross-platform subscription period value object (e.g. "1 month", "3 weeks").
@immutable
class SubscriptionPeriodValue {
  const SubscriptionPeriodValue({required this.numberOfUnits, required this.unit});

  final int numberOfUnits;
  final PeriodUnit unit;

  /// Human-readable label (e.g. "1 week", "3 months").
  String get displayLabel {
    final unitName = unit.name;
    return numberOfUnits == 1 ? '$numberOfUnits $unitName' : '$numberOfUnits ${unitName}s';
  }

  /// Parses an ISO 8601 duration (the Android Billing subset `P<n>[DWMY]`).
  static SubscriptionPeriodValue fromIso8601(String iso) {
    final match = RegExp(r'^P(\d+)([DWMY])$').firstMatch(iso);
    if (match == null) throw FormatException('Invalid ISO 8601 period: $iso');
    final count = int.parse(match.group(1)!);
    final unit = switch (match.group(2)!) {
      'D' => PeriodUnit.day,
      'W' => PeriodUnit.week,
      'M' => PeriodUnit.month,
      'Y' => PeriodUnit.year,
      _ => throw FormatException('Unknown period unit in: $iso'),
    };
    return SubscriptionPeriodValue(numberOfUnits: count, unit: unit);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPeriodValue &&
          numberOfUnits == other.numberOfUnits &&
          unit == other.unit;

  @override
  int get hashCode => Object.hash(numberOfUnits, unit);

  @override
  String toString() => 'SubscriptionPeriodValue($displayLabel)';
}

/// How the user pays during an offer period.
enum OfferPaymentMode { freeTrial, payAsYouGo, payUpFront }

/// The type of offer/discount configured in App Store Connect / Play Console.
enum OfferType { introductory, promotional }

/// Cross-platform introductory/promotional offer (App Store Connect discount,
/// Play Billing pricing phase). Surfaced on the paywall as free trial / intro
/// price / promo.
@immutable
class ProductOffer {
  const ProductOffer({
    required this.type,
    required this.paymentMode,
    required this.formattedPrice,
    required this.rawPrice,
    required this.currencyCode,
    required this.numberOfPeriods,
    required this.period,
    this.identifier,
  });

  /// Store-specific offer identifier (null for iOS introductory offers).
  final String? identifier;
  final OfferType type;
  final OfferPaymentMode paymentMode;

  /// Store-formatted price string (e.g. "$0.99", "" for a free trial).
  final String formattedPrice;
  final double rawPrice;
  final String currencyCode;

  /// Number of billing periods the offer lasts.
  final int numberOfPeriods;

  /// Duration of each billing period within the offer.
  final SubscriptionPeriodValue period;

  bool get isFreeTrial => paymentMode == OfferPaymentMode.freeTrial;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductOffer &&
          identifier == other.identifier &&
          type == other.type &&
          paymentMode == other.paymentMode &&
          formattedPrice == other.formattedPrice &&
          rawPrice == other.rawPrice &&
          currencyCode == other.currencyCode &&
          numberOfPeriods == other.numberOfPeriods &&
          period == other.period;

  @override
  int get hashCode => Object.hash(identifier, type, paymentMode, formattedPrice,
      rawPrice, currencyCode, numberOfPeriods, period);

  @override
  String toString() =>
      'ProductOffer(type: $type, mode: $paymentMode, price: $formattedPrice)';
}
