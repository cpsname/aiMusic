# ADR-0035 — The primary action's words, and what it says it costs
Status: Accepted
Date: 2026-10-05
Relates to: ADR-0031 (everything costs credits; no client-side gate).

## Context
The composer's one action should say what will happen: "Create Alex's preview · free",
"Create full song · 1 song". Since contract 02 v2.1 a free account usually has no free
previews (`clips_left: 0`) and every song costs credits (ADR-0031), so a fixed "free"
would be untrue — and the ledger lives on the server, the client only mirrors it.

## Decision
- **Verb by length and name** (`CreateAction`, pure): Short → "Create preview", or
  "Create {name}'s preview" when a picked card has a name; Standard → "Create full song"
  (no name: the request names nobody differently).
- **Cost only as the ledger shows it** (`songletEntitlementProvider`): a free account
  with free previews left → "· free"; a plan's included preview → "· 1 preview"; an
  included song (plan or pack) → "· 1 song"; nothing left, or the ledger not known yet →
  no cost at all. The action never blocks: the server answers `QUOTA_EXHAUSTED` and the
  generating page opens the paywall it asks for (ADR-0031) — also when the refusal lands
  before that page is up.
- **Enabled** when what would be sent can make a song (free input: words, photos or own
  lyrics; a card: always, unless it asks for the user's words) and nothing is in flight.
- **Copy**: three ICU `select` keys hold whole phrases (`createPreviewLabel`,
  `createPreviewForLabel`, `createFullSongLabel`, selector `cost`), so word order and the
  German length budget work per language.
- **A purchase outside the sheet** (granted by the server, approved later, a renewal):
  after the paywall closes the ledger is re-read; once it covers the refused song, the
  song is made without asking again.

## Consequences
`test/create/composer_model_test.dart` holds the label table; the create home tests check
"free" on a free allowance, no cost with nothing left, and the paywall on the refusal.
