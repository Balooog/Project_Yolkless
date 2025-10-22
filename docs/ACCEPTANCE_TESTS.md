# Acceptance Tests

## RM-001: Data-first loop + research + hot reload
- Editing `BURST_MULT` in TSV and pressing **R** updates PPS immediately.
- Buying `r_prod_1` increases PPS and persists across prestige and reload.
- Offline grant applies with 8 h cap and 0.8 efficiency; login popup shows amount.
- Autosave triggers every `AUTOSAVE_SECONDS` and after buy/promote/prestige.
- Export (copy) and Import (paste) round-trip the save successfully.

## RM-002: Schema expansion + UI indicators
- `[UPGRADES]` scanner aggregates **all** `prod_*` and `cap_*` rows (no hardcoded ids).
- `FACTORY_TIERS.cost` is used by `promote_factory()`.
- Research Panel lists nodes with Locked / Affordable / Owned and updates after **R**.
- Capacity bar clamps exactly at Capacity; burst cooldown indicator tracks time left.

## RM-003: UX polish + accessibility
- Color palette passes WCAG AA for text/bars (≥ 4.5:1).
- Hold-to-burst button shows tactile press feedback and disabled state on cooldown.
- All UI text scales cleanly at 125% and 150%.
