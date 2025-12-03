defmodule GoveeLights.Device.State do
  @moduledoc """
  Represents the **normalized state** of a Govee device.

  This struct wraps a subset of the state we care about in a typed way, while
  still allowing the rest of the raw API payload to be handled elsewhere if
  needed.

  Fields:

    * `:on` – whether the device is on, or `:unknown` if the API didn't say.
    * `:brightness` – brightness level (0..100), or `:unknown`.
    * `:color` – RGB map like `%{r: 255, g: 255, b: 255}`, or `:unknown`.
    * `:last_checked` – timestamp of the last known state update (or `nil`
      if not provided yet).

  The `new/1` constructor expects a map with **atom keys** and uses
  `GoveeLights.Utils` helpers to validate values. You can extend it over
  time to parse more fields as you discover them.

  ## Examples

  Minimal state (no keys provided):

      iex> {:ok, state} = GoveeLights.Device.State.new(%{})
      iex> state.on
      :unknown
      iex> state.brightness
      :unknown
      iex> state.color
      :unknown
      iex> state.last_checked
      nil

  With basic fields:

      iex> {:ok, state} =
      ...>   GoveeLights.Device.State.new(%{
      ...>     on: true,
      ...>     brightness: 42
      ...>   })
      iex> state.on
      true
      iex> state.brightness
      42
      iex> state.color
      :unknown

  With a valid RGB color and last_checked timestamp:

      iex> ts = ~U[2025-01-02 12:00:00Z]
      iex> {:ok, state} =
      ...>   GoveeLights.Device.State.new(%{
      ...>     on: true,
      ...>     brightness: 100,
      ...>     color: %{r: 255, g: 128, b: 0},
      ...>     last_checked: ts
      ...>   })
      iex> state.color
      %{r: 255, g: 128, b: 0}
      iex> state.last_checked == ts
      true

  Invalid `on` value (delegated to `GoveeLights.Utils.fetch_optional_boolean/3`):

      iex> GoveeLights.Device.State.new(%{on: "yes"})
      {:error, {:invalid_boolean, :on, "yes"}}

  Invalid brightness:

      iex> GoveeLights.Device.State.new(%{brightness: -1})
      {:error, {:invalid_brightness, -1}}

      iex> GoveeLights.Device.State.new(%{brightness: 200})
      {:error, {:invalid_brightness, 200}}

  Invalid color shape / values:

      iex> GoveeLights.Device.State.new(%{color: %{r: 0, g: 0}})
      {:error, {:invalid_color, %{r: 0, g: 0}, "expected a map with r, g, b"}}

      iex> GoveeLights.Device.State.new(%{color: %{r: 999, g: 0, b: 0}})
      {:error, {:invalid_color, %{r: 999, g: 0, b: 0}, "expected r, g, b in 0..255"}}

      iex> GoveeLights.Device.State.new(%{color: "not-a-map"})
      {:error, {:invalid_color, "not-a-map"}}
  """

  alias GoveeLights.Utils

  defstruct on: :unknown,
            brightness: :unknown,
            color: :unknown,
            last_checked: nil

  @type color_rgb ::
          %{r: non_neg_integer(), g: non_neg_integer(), b: non_neg_integer()}

  @type t :: %__MODULE__{
          on: boolean() | :unknown,
          brightness: non_neg_integer() | :unknown,
          color: color_rgb() | :unknown,
          last_checked: DateTime.t() | nil
        }

  @type new_error ::
          {:invalid_boolean, atom(), term()}
          | {:invalid_brightness, term()}
          | {:invalid_color, term() | map(), String.t() | nil}

  @doc """
  Builds a new `#{__MODULE__}` struct from a map with atom keys.

  It normalizes optional fields and returns either `{:ok, state}` or
  `{:error, reason}`. See the moduledoc for detailed examples.
  """
  @spec new(map()) :: {:ok, t()} | {:error, new_error()}
  def new(attrs) when is_map(attrs), do: new_internal(attrs)

  defp new_internal(%{} = attrs) do
    with {:ok, on} <- Utils.fetch_optional_boolean(attrs, :on, :unknown),
         {:ok, brightness} <- fetch_optional_brightness(attrs, :brightness, :unknown),
         {:ok, color} <- fetch_optional_color(attrs, :color, :unknown) do
      {:ok,
       %__MODULE__{
         on: on,
         brightness: brightness,
         color: color,
         last_checked: Map.get(attrs, :last_checked)
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_optional_brightness(map, key, default) do
    case Map.fetch(map, key) do
      :error ->
        {:ok, default}

      {:ok, val} when is_integer(val) and val >= 0 and val <= 100 ->
        {:ok, val}

      {:ok, val} ->
        {:error, {:invalid_brightness, val}}
    end
  end

  defp fetch_optional_color(map, key, default) do
    case Map.fetch(map, key) do
      :error ->
        {:ok, default}

      {:ok, %{} = val} ->
        with {:ok, r} <- Map.fetch(val, :r),
             {:ok, g} <- Map.fetch(val, :g),
             {:ok, b} <- Map.fetch(val, :b) do
          if valid_channel?(r) and valid_channel?(g) and valid_channel?(b) do
            {:ok, %{r: r, g: g, b: b}}
          else
            {:error, {:invalid_color, val, "expected r, g, b in 0..255"}}
          end
        else
          :error ->
            {:error, {:invalid_color, val, "expected a map with r, g, b"}}
        end

      {:ok, val} ->
        {:error, {:invalid_color, val}}
    end
  end

  defp valid_channel?(c), do: is_integer(c) and c >= 0 and c <= 255
end
