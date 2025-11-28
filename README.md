# 💡 GoveeLights

Control your Govee smart lights directly from **Elixir**.

This project provides a clean and simple wrapper for the Govee Developer API, allowing you to list devices, control power, adjust brightness, and modify color temperature, all with straightforward, minimal function calls.

> ⚠️ This library is **unofficial** and not affiliated with Govee.  
> It simply gives Elixir developers a nice, ergonomic way to talk to the Govee API.

---

## 🚀 Installation

Add to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:govee_lights, "~> 0.1.0"}
  ]
end
```

Fetch deps:

```bash
mix deps.get
```

---

## 🔑 API Key

You must export your Govee API key before usage:

```bash
export GOVEE_API_KEY="YOUR_KEY"
```

You can request a key here:
[https://developer.govee.com/reference/apply-you-govee-api-key](https://developer.govee.com/reference/apply-you-govee-api-key)

---

## 📘 Usage Examples

### List devices

```elixir
iex> GoveeLights.devices()
[
  %{
    "device" => "AA:BB:CC:DD:EE:FF:11:22",
    "deviceName" => "Bedroom Lightbulb",
    "model" => "H6008",
    "controllable" => true,
    "retrievable" => true,
    "supportCmds" => ["turn", "brightness", "color", "colorTem"]
  }
]
```

---

### Power Control

```elixir
GoveeLights.turn_on("AA:BB:CC:DD:EE:FF:11:22", "H6008")
GoveeLights.turn_off("AA:BB:CC:DD:EE:FF:11:22", "H6008")
```

---

### Brightness (0–100)

```elixir
GoveeLights.set_brightness("AA:BB:CC:DD:EE:FF:11:22", "H6008", 50)
```

---

### Color Temperature

```elixir
# values differ per model → check devices/0 properties
GoveeLights.set_temperature("AA:BB:CC:DD:EE:FF:11:22", "H6008", 3000)
```

---

## 🧠 Notes & Tips

| Feature                | Status         |
| ---------------------- | -------------- |
| Device listing         | ✔️ `devices/0` |
| Power control          | ✔️ on/off      |
| Brightness             | ✔️ 0–100       |
| Temperature            | ✔️ Kelvin      |
| RGB color support      | planned        |
| Scene / effect control | planned        |

---

## 🛠 Development

```bash
mix test         # run test suite
mix docs         # generate documentation
```

---

## 📌 Planned Improvements / TODO

### Internal Enhancements

- **Device caching layer**
  - reduces API calls dramatically
  - TTL-based refresh or manual invalidation

- **Better error messages**
  - contextual failures (`device not found`, `brightness out of range`, etc.)
  - include Govee error metadata

- Improved fault-tolerance
  - automatic retries for transient network errors
  - optional backoff mechanism

### Feature Expansion

- Add full RGB color control
- Scene / Dynamic effect control
- Presets & automation helpers
- More test coverage + mock API adapter

Create an issue if you'd like to help or suggest something.

---

## ❤️ Contributing

Pull requests are welcome!
Issues, ideas, feedback, all appreciated.

If you enjoy this library, leave a ⭐ on the repo •͡˘㇁•͡˘
