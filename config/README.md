# Config Guide

- Copy `user_settings.example.yaml` to `user_settings.yaml`.
- Keys:
  - `ui.language`: UI locale tag
  - `ui.autosave_interval_sec`: autosave cadence
  - `paths.artifacts_dir`: where demo artifacts are written
  - `sandbox.default_ticks` / `sandbox.seed`: defaults for replay demo
- On startup, the app/scripts should fall back to example values if the user file is missing and print a warning.
