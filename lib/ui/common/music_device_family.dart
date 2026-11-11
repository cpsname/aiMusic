/// The device families Songlet ships for (ADR-0037: iPhone-only at launch, an
/// iPad decision after the first wave's data).
///
/// The one switch for everything iPad-specific: the two-column layouts
/// (`MusicWindowClass.regular`), the iPad devices of the golden / layout matrix,
/// the iPad-only page tests and the iPad App Store previews. It mirrors the
/// Runner target's `TARGETED_DEVICE_FAMILY` — `true` exactly when that
/// contains 2 — and test/governance/device_family_test.dart fails when the
/// two disagree, so they change together. Nothing iPad-specific is deleted
/// while it is off; it only stays dormant.
const bool ipadEnabled = false;
