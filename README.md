# 💡 GoveeLights

[![Hex.pm](https://img.shields.io/hexpm/v/govee_lights.svg)](https://hex.pm/packages/govee_lights)
[![Documentation](https://img.shields.io/badge/hexdocs-docs-blue)](https://hexdocs.pm/govee_lights)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Build Status](https://img.shields.io/github/actions/workflow/status/adia-dev/govee-lights-ex/ci.yml?branch=main)](https://github.com/adia-dev/govee-lights-ex/actions)

Control your **Govee smart lights** directly from **Elixir**.

This library provides a typed, documented wrapper around the **Govee Developer API**.
Instead of working with raw JSON maps, you interact with domain structs such as
`GoveeLights.Device` and `GoveeLights.Device.State`.

> ⚠️ This library is **unofficial** and not affiliated with Govee.

---

## 🚀 Installation

Add the dependency to your `mix.exs`:

```elixir
def deps do
  [
    {:govee_lights, "~> 0.2.0"}
  ]
end
```

Fetch dependencies:

```bash
mix deps.get
```

---

## 🔑 API Key

You must provide a Govee API key before using the API.

Either via environment variable:

```bash
export GOVEE_API_KEY="YOUR_KEY"
```

Or via application configuration:

```elixir
config :govee_lights, api_key: "YOUR_KEY"
```

You can request a key here:
[https://developer.govee.com/reference/apply-you-govee-api-key](https://developer.govee.com/reference/apply-you-govee-api-key)

---

## 📘 Usage

All interaction happens through **`GoveeLights.Api`**.

```elixir
alias GoveeLights.Api
```

---

## 📦 List devices

Retrieve all devices associated with your account as typed structs:

```elixir
iex> {:ok, devices} = Api.devices()
iex> Enum.all?(devices, &match?(%GoveeLights.Device{}, &1))
true
```

Each `%Device{}` contains metadata, properties, and a normalized state field.

You can also use the bang variant:

```elixir
iex> devices = Api.devices!()
```

---

## 🔍 Device state

Fetch the current state of a device:

```elixir
iex> {:ok, state} =
...>   Api.device_state("AA:BB:CC:DD:EE:FF:11:22", "H6008")

iex> state.on
true

iex> state.brightness
10

iex> state.color
%{r: 36, g: 242, b: 156}
```

The result is a `%GoveeLights.Device.State{}` struct.
Missing values are represented as `:unknown`.

Bang variant:

```elixir
iex> state = Api.device_state!("AA:BB:CC:DD:EE:FF:11:22", "H6008")
```

---

## 🔌 Power control

Turn a device on or off:

```elixir
Api.turn_on("AA:BB:CC:DD:EE:FF:11:22", "H6008")
Api.turn_off("AA:BB:CC:DD:EE:FF:11:22", "H6008")
```

Both return:

```elixir
{:ok, :updated}
```

Bang variants are also available:

```elixir
Api.turn_on!("AA:BB:CC:DD:EE:FF:11:22", "H6008")
```

---

## 🔆 Brightness (0–100)

```elixir
Api.set_brightness("AA:BB:CC:DD:EE:FF:11:22", "H6008", 50)
```

Invalid values return structured errors:

```elixir
{:error, {:invalid_command, "brightness", 200}}
```

---

## 🌡 Color temperature (Kelvin)

```elixir
Api.set_temperature("AA:BB:CC:DD:EE:FF:11:22", "H6008", 3000)
```

Supported ranges depend on the device model and can be inspected via `Api.devices/0`.

---

## 🎨 RGB color

```elixir
Api.set_color(
  "AA:BB:CC:DD:EE:FF:11:22",
  "H6008",
  %{r: 255, g: 0, b: 0}
)
```

Values must be integers in `0..255`.

---

## 💥 Bang vs non-bang APIs

All major functions come in two forms:

| Function | Behavior                                          |
| -------- | ------------------------------------------------- |
| `foo/…`  | returns `{:ok, value}` or `{:error, reason}`      |
| `foo!/…` | returns `value` or raises `GoveeLights.Api.Error` |

Example:

```elixir
Api.device_state!(device, model)
```

Raises `GoveeLights.Api.Error` if the request or decoding fails.

---

## ⚠️ Errors

Non-bang functions return structured error tuples such as:

* `{:http_error, reason}`
* `{:decode_error, data}`
* `{:device_error, raw, reason}`
* `{:state_error, raw, reason}`
* `{:command_failed, command, value, code, message}`
* `{:invalid_command, command, value}`

Bang variants raise `GoveeLights.Api.Error`, which contains the original error tuple in
`exception.reason`.

---

## 🛠 Development

```bash
mix test
mix docs
```

---

## 📌 Roadmap

### Internal

* Device caching layer (TTL / manual invalidation)
* Improved contextual errors
* Retry & backoff for transient HTTP failures

### Features

* Full RGB color workflows
* Scene / effect control
* Presets & automation helpers
* Extended state modeling

---

## ❤️ Contributing

Issues and pull requests are welcome.

If you find this useful, consider leaving a ⭐ on the repository: it helps a lot !!!
