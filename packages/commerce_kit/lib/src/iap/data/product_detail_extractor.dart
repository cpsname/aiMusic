import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../domain/store_offer.dart';

/// Extracts subscription periods + introductory/promotional offers (App Store
/// Connect discounts, Play Billing pricing phases) from platform-specific
/// [ProductDetails], producing the store-agnostic [ProductOffer] /
/// [SubscriptionPeriodValue] / [StoreType] domain types.
class ProductDetailExtractor {
  const ProductDetailExtractor();

  /// The introductory offer (free trial / intro price) for [details], if any.
  ProductOffer? extractIntroductoryOffer(ProductDetails details) {
    try {
      if (details is AppStoreProductDetails) {
        return _iosIntroductoryOffer(details);
      } else if (details is AppStoreProduct2Details) {
        return _ios2IntroductoryOffer(details);
      } else if (details is GooglePlayProductDetails) {
        return _androidIntroductoryOffer(details);
      }
    } on Object catch (e) {
      _warn('introductory offer', details.id, e);
    }
    return null;
  }

  /// Promotional offers / discounts for [details] (may be empty).
  List<ProductOffer> extractPromotionalOffers(ProductDetails details) {
    try {
      if (details is AppStoreProductDetails) {
        return _iosPromotionalOffers(details);
      } else if (details is AppStoreProduct2Details) {
        return _ios2PromotionalOffers(details);
      } else if (details is GooglePlayProductDetails) {
        return _androidPromotionalOffers(details);
      }
    } on Object catch (e) {
      _warn('promotional offers', details.id, e);
    }
    return const [];
  }

  /// The subscription period for [details] (null for non-subscriptions).
  SubscriptionPeriodValue? extractSubscriptionPeriod(ProductDetails details) {
    try {
      if (details is AppStoreProductDetails) {
        return _iosSubscriptionPeriod(details);
      } else if (details is AppStoreProduct2Details) {
        return _ios2SubscriptionPeriod(details);
      } else if (details is GooglePlayProductDetails) {
        return _androidSubscriptionPeriod(details);
      }
    } on Object catch (e) {
      _warn('subscription period', details.id, e);
    }
    return null;
  }

  /// Clean display title (Android strips the " (App Name)" suffix).
  String cleanTitle(ProductDetails details) {
    if (details is GooglePlayProductDetails) {
      final name = details.productDetails.name;
      if (name.isNotEmpty) return name;
      return details.title.replaceAll(RegExp(r'\s*\(.*\)\s*$'), '');
    }
    return details.title;
  }

  /// The store platform behind [details].
  StoreType detectStoreType(ProductDetails details) {
    if (details is AppStoreProductDetails || details is AppStoreProduct2Details) {
      return StoreType.appStore;
    }
    if (details is GooglePlayProductDetails) return StoreType.playStore;
    return StoreType.appStore;
  }

  void _warn(String what, String id, Object error) {
    if (kDebugMode) {
      debugPrint('[iap] failed to extract $what for $id: $error');
    }
  }

  // --- iOS StoreKit 1 -------------------------------------------------------

  ProductOffer? _iosIntroductoryOffer(AppStoreProductDetails details) {
    final intro = details.skProduct.introductoryPrice;
    if (intro == null) return null;
    return _mapIosDiscount(intro, OfferType.introductory);
  }

  List<ProductOffer> _iosPromotionalOffers(AppStoreProductDetails details) {
    final discounts = details.skProduct.discounts;
    if (discounts.isEmpty) return const [];
    return discounts
        .where((d) => d.type == SKProductDiscountType.subscription)
        .map((d) => _mapIosDiscount(d, OfferType.promotional))
        .toList();
  }

  SubscriptionPeriodValue? _iosSubscriptionPeriod(AppStoreProductDetails d) {
    final period = d.skProduct.subscriptionPeriod;
    if (period == null) return null;
    return SubscriptionPeriodValue(
      numberOfUnits: period.numberOfUnits,
      unit: _iosPeriodUnit(period.unit),
    );
  }

  ProductOffer _mapIosDiscount(SKProductDiscountWrapper d, OfferType type) =>
      ProductOffer(
        identifier: d.identifier,
        type: type,
        paymentMode: _iosPaymentMode(d.paymentMode),
        formattedPrice: d.price,
        rawPrice: double.tryParse(d.price) ?? 0,
        currencyCode: d.priceLocale.currencyCode,
        numberOfPeriods: d.numberOfPeriods,
        period: SubscriptionPeriodValue(
          numberOfUnits: d.subscriptionPeriod.numberOfUnits,
          unit: _iosPeriodUnit(d.subscriptionPeriod.unit),
        ),
      );

  PeriodUnit _iosPeriodUnit(SKSubscriptionPeriodUnit unit) => switch (unit) {
    SKSubscriptionPeriodUnit.day => PeriodUnit.day,
    SKSubscriptionPeriodUnit.week => PeriodUnit.week,
    SKSubscriptionPeriodUnit.month => PeriodUnit.month,
    SKSubscriptionPeriodUnit.year => PeriodUnit.year,
  };

  OfferPaymentMode _iosPaymentMode(SKProductDiscountPaymentMode mode) =>
      switch (mode) {
        // Apple's SDK has a typo: `freeTrail`.
        SKProductDiscountPaymentMode.freeTrail => OfferPaymentMode.freeTrial,
        SKProductDiscountPaymentMode.payAsYouGo => OfferPaymentMode.payAsYouGo,
        SKProductDiscountPaymentMode.payUpFront => OfferPaymentMode.payUpFront,
        SKProductDiscountPaymentMode.unspecified => OfferPaymentMode.freeTrial,
      };

  // --- iOS StoreKit 2 -------------------------------------------------------

  ProductOffer? _ios2IntroductoryOffer(AppStoreProduct2Details details) {
    final offers = details.sk2Product.subscription?.promotionalOffers;
    if (offers == null || offers.isEmpty) return null;
    for (final offer in offers) {
      if (offer.type == SK2SubscriptionOfferType.introductory) {
        return _mapIos2Offer(details, offer);
      }
    }
    return null;
  }

  List<ProductOffer> _ios2PromotionalOffers(AppStoreProduct2Details details) {
    final offers = details.sk2Product.subscription?.promotionalOffers;
    if (offers == null || offers.isEmpty) return const [];
    return offers
        .where(
          (o) =>
              o.type == SK2SubscriptionOfferType.promotional ||
              o.type == SK2SubscriptionOfferType.winBack,
        )
        .map((o) => _mapIos2Offer(details, o))
        .toList();
  }

  SubscriptionPeriodValue? _ios2SubscriptionPeriod(AppStoreProduct2Details d) {
    final period = d.sk2Product.subscription?.subscriptionPeriod;
    if (period == null) return null;
    return SubscriptionPeriodValue(
      numberOfUnits: period.value,
      unit: _ios2PeriodUnit(period.unit),
    );
  }

  ProductOffer _mapIos2Offer(
    AppStoreProduct2Details details,
    SK2SubscriptionOffer offer,
  ) =>
      ProductOffer(
        identifier: offer.id,
        type: _ios2OfferType(offer.type),
        paymentMode: _ios2PaymentMode(offer.paymentMode),
        formattedPrice: _ios2OfferPrice(details, offer),
        rawPrice: offer.price,
        currencyCode: details.currencyCode,
        numberOfPeriods: offer.periodCount,
        period: SubscriptionPeriodValue(
          numberOfUnits: offer.period.value,
          unit: _ios2PeriodUnit(offer.period.unit),
        ),
      );

  OfferType _ios2OfferType(SK2SubscriptionOfferType type) => switch (type) {
    SK2SubscriptionOfferType.introductory => OfferType.introductory,
    SK2SubscriptionOfferType.promotional ||
    SK2SubscriptionOfferType.winBack => OfferType.promotional,
  };

  PeriodUnit _ios2PeriodUnit(SK2SubscriptionPeriodUnit unit) => switch (unit) {
    SK2SubscriptionPeriodUnit.day => PeriodUnit.day,
    SK2SubscriptionPeriodUnit.week => PeriodUnit.week,
    SK2SubscriptionPeriodUnit.month => PeriodUnit.month,
    SK2SubscriptionPeriodUnit.year => PeriodUnit.year,
  };

  OfferPaymentMode _ios2PaymentMode(SK2SubscriptionOfferPaymentMode mode) =>
      switch (mode) {
        SK2SubscriptionOfferPaymentMode.freeTrial => OfferPaymentMode.freeTrial,
        SK2SubscriptionOfferPaymentMode.payAsYouGo => OfferPaymentMode.payAsYouGo,
        SK2SubscriptionOfferPaymentMode.payUpFront => OfferPaymentMode.payUpFront,
      };

  String _ios2OfferPrice(
    AppStoreProduct2Details details,
    SK2SubscriptionOffer offer,
  ) {
    if (offer.paymentMode == SK2SubscriptionOfferPaymentMode.freeTrial ||
        offer.price <= 0) {
      return '';
    }
    final isWhole = offer.price == offer.price.truncateToDouble();
    final amount = offer.price.toStringAsFixed(isWhole ? 0 : 2);
    final symbol = details.currencySymbol;
    if (symbol.isNotEmpty) return '$symbol$amount';
    final code = details.currencyCode;
    return code.isEmpty ? amount : '$amount $code';
  }

  // --- Android Play Billing -------------------------------------------------

  ProductOffer? _androidIntroductoryOffer(GooglePlayProductDetails details) {
    final offerDetails = details.productDetails.subscriptionOfferDetails;
    if (offerDetails == null || offerDetails.isEmpty) return null;
    for (final phase in offerDetails.first.pricingPhases) {
      if (phase.recurrenceMode == RecurrenceMode.finiteRecurring ||
          phase.recurrenceMode == RecurrenceMode.nonRecurring) {
        return _mapAndroidPhase(phase, OfferType.introductory);
      }
    }
    return null;
  }

  List<ProductOffer> _androidPromotionalOffers(GooglePlayProductDetails d) {
    final offerDetails = d.productDetails.subscriptionOfferDetails;
    if (offerDetails == null || offerDetails.length <= 1) return const [];
    final offers = <ProductOffer>[];
    for (var i = 1; i < offerDetails.length; i++) {
      for (final phase in offerDetails[i].pricingPhases) {
        if (phase.recurrenceMode == RecurrenceMode.finiteRecurring ||
            phase.recurrenceMode == RecurrenceMode.nonRecurring) {
          offers.add(_mapAndroidPhase(phase, OfferType.promotional));
        }
      }
    }
    return offers;
  }

  SubscriptionPeriodValue? _androidSubscriptionPeriod(
    GooglePlayProductDetails details,
  ) {
    final offerDetails = details.productDetails.subscriptionOfferDetails;
    if (offerDetails == null || offerDetails.isEmpty) return null;
    final phases = offerDetails.first.pricingPhases;
    for (var i = phases.length - 1; i >= 0; i--) {
      if (phases[i].recurrenceMode == RecurrenceMode.infiniteRecurring) {
        return _tryAndroidPeriod(phases[i].billingPeriod);
      }
    }
    return null;
  }

  ProductOffer _mapAndroidPhase(PricingPhaseWrapper phase, OfferType type) =>
      ProductOffer(
        type: type,
        paymentMode: _androidPaymentMode(phase.recurrenceMode),
        formattedPrice: phase.formattedPrice,
        rawPrice: phase.priceAmountMicros / 1000000.0,
        currencyCode: phase.priceCurrencyCode,
        numberOfPeriods: phase.billingCycleCount,
        period: _tryAndroidPeriod(phase.billingPeriod) ??
            const SubscriptionPeriodValue(
              numberOfUnits: 1,
              unit: PeriodUnit.month,
            ),
      );

  SubscriptionPeriodValue? _tryAndroidPeriod(String billingPeriod) {
    try {
      return SubscriptionPeriodValue.fromIso8601(billingPeriod);
    } on FormatException {
      return null;
    }
  }

  OfferPaymentMode _androidPaymentMode(RecurrenceMode mode) => switch (mode) {
    RecurrenceMode.nonRecurring => OfferPaymentMode.freeTrial,
    RecurrenceMode.finiteRecurring => OfferPaymentMode.payAsYouGo,
    RecurrenceMode.infiniteRecurring => OfferPaymentMode.payAsYouGo,
  };
}
