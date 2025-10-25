# Project Yolkless — Idle Game Prototype (SPEC-1)

## Vision
A cozy, tactile idle game with **hold-to-burst** production, **two currencies** (Soft, Prestige), **no ads/IAP**, and **Linux-first iteration**. Future-ready for Steam/Google Play.

Design tone, pacing, and system layering follow the comfort-idle benchmarks summarized in `docs/analysis/IdleGameComparative.md`.

## Core Decisions
- **Research:** prestige-only (permanent), acts as meta tree.
- **Factory Levels:** distinct building tiers (not just capacity ranks). Tiers unlock systems and apply multipliers.
- **Offline:** simulate auto-collect at 80% efficiency, cap at 8 h. Show a summary popup on login.
- **Save:** autosave on interval and major actions; include simple manual export/import (base64 JSON).
- **UI style:** minimal, high-contrast, colorblind-safe (soft pastels, clean icons).

## Loop Summary
1) Player holds to **burst** → temporary production multiplier (5 s) with cooldown (10 s).
2) Earn **Soft**, limited by **Capacity**; spend on upgrades and tier promotions.
3) Unlock **Automation**; bursts fire on a timer with slight efficiency penalty.
4) **Prestige:** convert lifetime earnings → Prestige points; buy permanent **Research** nodes.

## Tech
- **Engine:** Godot 4.x (GDScript).
- **Data:** `data/balance.tsv` (hot-reload with `R`).
- **Scripts:** `game/scripts/*`; Scenes in `game/scenes/*`.
- **Run:** `tools/run_dev.sh`; Build: `tools/build_linux.sh` (preset: “Linux”).

## Non-goals (MVP)
- Monetization, multiplayer, cloud saves, skins store.

## Risks & Mitigations
- Data drift: keep **schema in `/docs/balance_schema.md`** and validate on load.
- Tuning churn: use **hot reload** and keep numbers in TSV only.
- Save breakage: versioned JSON with light integrity hash; manual export/import in Settings.
