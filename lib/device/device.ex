defmodule GoveeLights.Device do
  @moduledoc """
  Represents a single Govee light device.

  This module defines a typed struct and a **smart constructor** `new/1` that
  validates and normalizes input coming from Govee's API responses or internal
  code.

  ## Fields

    * `:id` – **required**. Govee device identifier (MAC-like string).
    * `:model` – **required**. Govee model identifier (e.g. `"H6008"`).
    * `:name` – optional, user-friendly name for the device (or `nil`).
    * `:state` – normalized device state as `GoveeLights.Device.State.t()`.
      When no state map is provided, a default state with `:unknown` values
      is used.
    * `:properties` – map for additional device properties (defaults to `%{}`).
    * `:controllable` – boolean flag indicating whether the device can be
      controlled by the API (defaults to `false`).

  The `new/1` function accepts either a **map** or a **keyword list**, with
  string or atom keys. Unknown keys are ignored. All validation happens
  in `new/1` / `new_internal/1`.

  ## Examples

  Minimal valid device using atom keys:

      iex> {:ok, device} =
      ...>   GoveeLights.Device.new(%{id: "AA:BB:CC:DD:EE:FF:11:22", model: "H6008"})
      iex> device.id
      "AA:BB:CC:DD:EE:FF:11:22"
      iex> device.model
      "H6008"
      iex> device.name
      nil
      iex> match?(%GoveeLights.Device.State{}, device.state)
      true
      iex> device.state.on
      :unknown
      iex> device.properties
      %{}
      iex> device.controllable
      false

  Using a keyword list (e.g. from internal code):

      iex> {:ok, device} =
      ...>   GoveeLights.Device.new(
      ...>     id: "AA:BB:CC:DD:EE:FF:11:22",
      ...>     model: "H6008",
      ...>     name: "Backrooms",
      ...>     controllable: true
      ...>   )
      iex> device.name
      "Backrooms"
      iex> device.controllable
      true

  Using string keys (e.g. decoded JSON from the Govee API):

      iex> {:ok, device} =
      ...>   GoveeLights.Device.new(%{
      ...>     "id" => "AA:BB:CC:DD:EE:FF:11:22",
      ...>     "model" => "H6008",
      ...>     "name" => "Bedroom",
      ...>     "state" => %{
      ...>       on: true,
      ...>       brightness: 42
      ...>     }
      ...>   })
      iex> device.id
      "AA:BB:CC:DD:EE:FF:11:22"
      iex> device.model
      "H6008"
      iex> device.name
      "Bedroom"
      iex> device.state.on
      true
      iex> device.state.brightness
      42

  Error when required fields are missing:

      iex> GoveeLights.Device.new(%{model: "H6008"})
      {:error, {:missing, :id}}

      iex> GoveeLights.Device.new(%{id: "AA:BB:CC:DD:EE:FF:11:22"})
      {:error, {:missing, :model}}

  Error when passing a non-keyword list:

      iex> GoveeLights.Device.new([1, 2, 3])
      {:error, {:invalid_attrs, :expected_keyword_list}}

  Error when the input is neither a map nor a keyword list:

      iex> GoveeLights.Device.new("not-a-map-or-keyword-list")
      {:error, {:invalid_attrs, :expected_map_or_keyword_list}}
  """

  alias GoveeLights.Utils
  alias GoveeLights.Device.State

  # Helps compilation to have a set of already defined atoms
  @fields ~w[id model name state properties controllable]a
  @fields_str ~w[id model name state properties controllable]

  @enforce_keys [:id, :model]
  defstruct @fields

  @type t :: %__MODULE__{
          id: String.t(),
          model: String.t(),
          name: String.t() | nil,
          state: State.t(),
          properties: map(),
          controllable: boolean()
        }

  @type new_error ::
          {:missing, atom()}
          | {:invalid_string, atom(), term()}
          | {:invalid_map, atom(), term()}
          | {:invalid_boolean, atom(), term()}
          | {:invalid_attrs, term()}
          | State.new_error()

  @doc """
  Builds a new `#{__MODULE__}` struct from a map or keyword list.

  Accepted inputs:

    * a **map** with atom and/or string keys
    * a **keyword list** (list of `{atom, value}` pairs)

  Validation rules:

    * `:id` and `:model` must be present and non-empty strings.
    * `:name` is optional and may be `nil` or a (possibly empty) string.
    * `:state` may be omitted or provided as a map; when present it must be a
      map suitable for `GoveeLights.Device.State.new/1`.
    * `:properties` must be a map when present; otherwise defaults to `%{}`.
    * `:controllable` must be boolean when present; otherwise defaults to `false`.

  On success, returns `{:ok, %#{__MODULE__}{}}`. On failure, returns
  `{:error, reason}` where `reason` is one of the `t:new_error/0` variants.
  """
  @spec new(map() | keyword()) :: {:ok, t()} | {:error, new_error()}
  def new(attrs) when is_list(attrs) do
    if Keyword.keyword?(attrs) do
      attrs
      |> Enum.into(%{})
      |> new_internal()
    else
      {:error, {:invalid_attrs, :expected_keyword_list}}
    end
  end

  def new(attrs) when is_map(attrs) do
    attrs
    |> atomize_keys()
    |> new_internal()
  end

  def new(_attrs) do
    {:error, {:invalid_attrs, :expected_map_or_keyword_list}}
  end

  defp new_internal(%{} = attrs) do
    with {:ok, id} <- Utils.fetch_string(attrs, :id),
         {:ok, model} <- Utils.fetch_string(attrs, :model),
         {:ok, name} <- Utils.fetch_string(attrs, :name, optional: true),
         {:ok, raw_state} <- Utils.fetch_optional_map(attrs, :state, %{}),
         {:ok, state} <- State.new(raw_state),
         {:ok, properties} <- Utils.fetch_optional_map(attrs, :properties),
         {:ok, controllable} <- Utils.fetch_optional_boolean(attrs, :controllable) do
      {:ok,
       %__MODULE__{
         id: id,
         model: model,
         name: name,
         state: state,
         properties: properties,
         controllable: controllable
       }}
    else
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unknown_invalid_internal_state, other}}
    end
  end

  defp atomize_keys(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) and k in @fields_str ->
        {String.to_existing_atom(k), v}

      pair ->
        pair
    end)
  end
end
