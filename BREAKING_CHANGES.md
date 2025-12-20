# Breaking changes

## 0.1.4 → 0.2.0

Version `0.2.0` introduces `GoveeLights.Api` as the main entry point.
The old `GoveeLights` module returned raw maps; the new API returns typed structs
and structured errors.

### What changed?

#### 1) New entry point

Replace:

```elixir
GoveeLights.devices()
GoveeLights.device_state(device, model)
GoveeLights.turn_on(device, model)
GoveeLights.turn_off(device, model)
GoveeLights.set_brightness(device, model, value)
GoveeLights.set_temperature(device, model, kelvin)
GoveeLights.set_color(device, model, %{r: 255, g: 0, b: 0})
```

With:

```elixir
alias GoveeLights.Api

Api.devices()
Api.device_state(device, model)
Api.turn_on(device, model)
Api.turn_off(device, model)
Api.set_brightness(device, model, value)
Api.set_temperature(device, model, kelvin)
Api.set_color(device, model, %{r: 255, g: 0, b: 0})
```

#### 2) Typed return values

`Api.devices/0` now returns:

```elixir
{:ok, [GoveeLights.Device.t()]} | {:error, reason}
```

`Api.device_state/2` now returns:

```elixir
{:ok, GoveeLights.Device.State.t()} | {:error, reason}
```

#### 3) Command return values

Commands now return:

```elixir
{:ok, :updated} | {:error, reason}
```

#### 4) Bang variants

Most functions have a `!` variant that raises `GoveeLights.Api.Error`:

```elixir
devices = Api.devices!()
state   = Api.device_state!(device, model)
:updated = Api.turn_on!(device, model)
```

#### 5) Error shape

Non-bang functions return structured error tuples, e.g.:

- `{:http_error, reason}`
- `{:decode_error, data}`
- `{:device_error, raw, reason}`
- `{:state_error, raw, reason}`
- `{:command_failed, command, value, code, message}`
- `{:invalid_command, command, value}`
