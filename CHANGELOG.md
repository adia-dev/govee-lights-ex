## v0.2.0

This release introduces **GoveeLights.Api** as the main entry point, returning typed structs (`Device`, `Device.State`) and structured error tuples. It also adds bang (`!`) variants that raise `GoveeLights.Api.Error`.

### ⚠️ Breaking changes (from 0.1.4)

- **New entry point:** use `GoveeLights.Api` instead of `GoveeLights` for API calls.
  - `GoveeLights.devices/0` → `GoveeLights.Api.devices/0`
  - `GoveeLights.device_state/2` → `GoveeLights.Api.device_state/2`
  - `GoveeLights.turn_on/2` → `GoveeLights.Api.turn_on/2`
  - `GoveeLights.turn_off/2` → `GoveeLights.Api.turn_off/2`
  - `GoveeLights.set_brightness/3` → `GoveeLights.Api.set_brightness/3`
  - `GoveeLights.set_temperature/3` → `GoveeLights.Api.set_temperature/3`
  - `GoveeLights.set_color/3` → `GoveeLights.Api.set_color/3`

- **Return types changed:** functions now return typed structs instead of raw maps:
  - `devices/0` returns `{:ok, [GoveeLights.Device.t()]}`
  - `device_state/2` returns `{:ok, GoveeLights.Device.State.t()}`

- **Command responses changed:** commands return `{:ok, :updated}` on success (instead of string messages).

### Added

- `GoveeLights.Api` (typed client)
- `GoveeLights.Device` and `GoveeLights.Device.State` structs
- Bang variants: `devices!/0`, `device_state!/2`, `turn_on!/2`, etc.
- `GoveeLights.Api.Error` exception for bang variants
- Improved docs and doctests

### Changed

- HTTP client module is resolved at runtime (via config), making it test-friendly and release-friendly.

### Migration guide

See [`BREAKING_CHANGES.md`](./BREAKING_CHANGES.md) for a quick mapping and examples.
