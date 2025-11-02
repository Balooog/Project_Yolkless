# RM-021 Sandbox Validation Checklist

> Cross-system guardrails to verify once Diorama/Map renderers and Conveyor overlay ship.

## View Mode Parity
- [ ] Diorama and Map views attach to the same SandboxService front buffer; toggling either direction finishes ≤100 ms with no CA restart.
- [ ] CI tint normalization matches: sample CI low/med/high in each era and confirm Map legend labels match Diorama LUT appearance.
- [ ] Map view surfaces a persistent CI/PPS legend (desktop + tablet + mobile layouts).
- [ ] Replay summary shows `sandbox_render_fallback_ratio ≤ 0.05`; investigate renderer assets if fallback exceeds the limit.

## Conveyor Overlay Guardrails
- [ ] Speed clamp holds at ≤2.5× baseline even under max PPS/Wisdom buffs during replay.
- [ ] Shipment pulses are debounced ≥400 ms; no stacked flashes during burst spam tests.
- [ ] Power ratio only adjusts tint warmth/coolness; conveyor speed remains PPS-driven.
- [ ] Reduce Motion toggle halves burst speed, disables speedlines/micro-pan, and keeps tint transitions smooth in both views.

## Mini-game Isolation (Future RM-0XX)
- [ ] Triggering a mini-game throttles only visual playback (Diorama + Conveyor) to ¼ rate while the CA simulation tick remains unchanged.
- [ ] Mini-game rewards log as `Insight`/`Reputation` and convert to a +2–3 % PPS bonus for 2–3 min with ≥10 min cooldown.
- [ ] Telemetry captures `minigame_active`, `minigame_duration`, and sandbox render metrics in the same session.

## Power & Automation Coupling
- [ ] Power deficits desaturate belts/backgrounds without slowing CA tick; surpluses warm tint only.
- [ ] Automation mode changes leave Sandbox render cadence untouched (verify via StatsProbe logs).
- [ ] `power_ratio`, `sandbox_render_view_mode`, and `sandbox_render_fallback_ratio` stats export together in nightly dashboard runs.
