defmodule GoveeLights.Api do
  @moduledoc """
  Elixir client for the **Govee Developer API**.

  This module is the main entry point for interacting with Govee devices.
  It provides functions to:

    * list devices associated with your account
    * retrieve the current state of a device
    * send control commands (power, brightness, color, temperature)

  All data returned by this module is converted into domain structs
  (`GoveeLights.Device` and `GoveeLights.Device.State`) instead of raw API maps.

  ---

  ## Authentication

  You must provide a Govee API key, either as an environment variable:

      export GOVEE_API_KEY="your_api_key"

  or via application configuration:

      config :govee_lights, api_key: "your_api_key"

  You can request an API key from Govee at:
  https://developer.govee.com/reference/apply-you-govee-api-key

  ---

  ## Devices

  Retrieve all devices linked to your account:

      iex> {:ok, devices} = GoveeLights.Api.devices()
      iex> Enum.all?(devices, &match?(%GoveeLights.Device{}, &1))
      true

  Each device contains basic metadata and a normalized `state` field.

  ---

  ## Device state

  Fetch the current state of a device by its identifier and model:

      iex> {:ok, state} =
      ...>   GoveeLights.Api.device_state("AA:BB:CC:DD:EE:FF:11:22", "H6008")
      iex> state.on
      true
      iex> state.brightness
      10
      iex> state.color
      %{r: 36, g: 242, b: 156}

  The returned value is a `%GoveeLights.Device.State{}` struct with normalized
  fields. Missing information is represented as `:unknown`.

  ---

  ## Device control

  Send commands to a device using its identifier and model.

  Turn a device on or off:

      iex> GoveeLights.Api.turn_on("AA:BB:CC:DD:EE:FF:11:22", "H6008")
      {:ok, :updated}

      iex> GoveeLights.Api.turn_off("AA:BB:CC:DD:EE:FF:11:22", "H6008")
      {:ok, :updated}

  Set brightness (0–100):

      iex> GoveeLights.Api.set_brightness("AA:BB:CC:DD:EE:FF:11:22", "H6008", 25)
      {:ok, :updated}

  Set color temperature (Kelvin):

      iex> GoveeLights.Api.set_temperature("AA:BB:CC:DD:EE:FF:11:22", "H6008", 2700)
      {:ok, :updated}

  Set RGB color:

      iex> GoveeLights.Api.set_color(
      ...>   "AA:BB:CC:DD:EE:FF:11:22",
      ...>   "H6008",
      ...>   %{r: 255, g: 0, b: 0}
      ...> )
      {:ok, :updated}

  ---

  ## Bang functions

  For convenience, most functions also have a bang (`!`) variant that
  returns the successful value directly or raises `GoveeLights.Api.Error`
  on failure.

  Example:

      iex> state =
      ...>   GoveeLights.Api.device_state!(
      ...>     "AA:BB:CC:DD:EE:FF:11:22",
      ...>     "H6008"
      ...>   )
      iex> state.on
      true

  ---

  ## Errors

  Non-bang functions return structured error tuples:

    * `{:http_error, reason}` – network or HTTP client failure
    * `{:decode_error, data}` – unexpected API response shape
    * `{:device_error, raw, reason}` – invalid device payload
    * `{:state_error, raw, reason}` – invalid state payload
    * `{:command_failed, command, value, code, message}` – API rejected a command
    * `{:invalid_command, command, value}` – invalid command arguments

  Bang functions raise `GoveeLights.Api.Error`, which contains the original
  error tuple in `exception.reason`.

  ---

  ## HTTP client configuration

  By default, this module uses `GoveeLights.HTTPClient` (based on `Req`).
  You can provide a custom HTTP client by configuring:

      config :govee_lights, http_client: MyHTTPClient

  The client module must implement the `GoveeLights.HTTPClient` behaviour.

  ---

  This library is unofficial and not affiliated with Govee.
  """

  alias GoveeLights.Device
  alias GoveeLights.Device.State

  @govee_api_key_name "GOVEE_API_KEY"
  @govee_base_url Application.compile_env(
                    :govee_lights,
                    :base_url,
                    "https://developer-api.govee.com/v1"
                  )

  @govee_endpoints [
    devices: "/devices",
    device_control: "/devices/control",
    device_state: "/devices/state"
  ]

  defmodule Error do
    @moduledoc """
    Exception raised by bang variants in `GoveeLights.Api`.

    The original structured reason is available in `exception.reason`.
    """
    defexception [:message, :reason]

    @impl true
    def exception(reason) do
      %__MODULE__{reason: reason, message: format_reason(reason)}
    end

    defp format_reason({:config_error, msg}),
      do: "GoveeLights configuration error: #{msg}"

    defp format_reason({:http_error, error}),
      do: "HTTP error while calling Govee API: #{inspect(error)}"

    defp format_reason({:decode_error, data}),
      do: "Unexpected Govee API response shape: #{inspect(data)}"

    defp format_reason({:device_error, raw, reason}),
      do: "Failed to build device from #{inspect(raw)}: #{inspect(reason)}"

    defp format_reason({:state_error, raw, reason}),
      do: "Failed to build state from #{inspect(raw)}: #{inspect(reason)}"

    defp format_reason({:command_failed, command, value, code, msg}),
      do:
        "Govee command failed (#{command} #{inspect(value)}): code=#{inspect(code)} message=#{inspect(msg)}"

    defp format_reason({:invalid_command, command, value}),
      do: "Invalid command arguments for #{inspect(command)}: #{inspect(value)}"

    defp format_reason(other),
      do: "GoveeLights.Api error: #{inspect(other)}"
  end

  @type error_reason ::
          {:config_error, String.t()}
          | {:http_error, term()}
          | {:decode_error, term()}
          | {:device_error, map(), Device.new_error()}
          | {:state_error, map(), State.new_error()}
          | {:command_failed, String.t(), term(), term(), term()}
          | {:invalid_command, String.t(), term()}

  @type command_result :: :updated

  @doc """
  Retrieve all devices associated with your Govee account as `%Device{}` structs.

  ## Examples

      iex> {:ok, devices} = GoveeLights.Api.devices()
      iex> Enum.all?(devices, &match?(%GoveeLights.Device{}, &1))
      true
  """
  @spec devices() :: {:ok, [Device.t()]} | {:error, error_reason()}
  def devices do
    with {:ok, %{body: body}} <- http_get(@govee_endpoints[:devices]),
         {:ok, raw_devices} <- extract_devices(body),
         {:ok, devices} <- build_devices(raw_devices) do
      {:ok, devices}
    else
      {:error, error}
      when is_tuple(error) and
             elem(error, 0) in [:config_error, :http_error, :decode_error, :device_error] ->
        {:error, error}

      {:error, error} ->
        {:error, {:http_error, error}}
    end
  end

  @doc """
  Same as `devices/0`, but raises `GoveeLights.Api.Error` on failure.
  """
  @spec devices!() :: [Device.t()]
  def devices! do
    case devices() do
      {:ok, devices} -> devices
      {:error, reason} -> raise Error, reason
    end
  end

  @doc """
  Retrieve the current state of a device as `%State{}`.

  This endpoint returns a somewhat awkward `"properties"` list from Govee; this
  function normalizes it into your `State` struct.

  ## Examples

      iex> {:ok, state} =
      ...>   GoveeLights.Api.device_state("AA:BB:CC:DD:EE:FF:11:22", "H6008")
      iex> match?(%GoveeLights.Device.State{}, state)
      true
  """
  @spec device_state(String.t(), String.t()) :: {:ok, State.t()} | {:error, error_reason()}
  def device_state(device_id, model) when is_binary(device_id) and is_binary(model) do
    with {:ok, %{body: body}} <-
           http_get(@govee_endpoints[:device_state], device: device_id, model: model),
         {:ok, raw_state} <- extract_state(body),
         {:ok, attrs} <- normalize_state_payload(raw_state),
         {:ok, state} <- State.new(attrs) do
      {:ok, state}
    else
      {:error, {:state_error, _, _}} = tagged -> tagged
      {:error, {:decode_error, _}} = tagged -> tagged
      {:error, {:http_error, _}} = tagged -> tagged
      {:error, {:config_error, _}} = tagged -> tagged
      {:error, reason} -> {:error, {:http_error, reason}}
    end
  end

  @doc """
  Same as `device_state/2`, but raises `GoveeLights.Api.Error` on failure.
  """
  @spec device_state!(String.t(), String.t()) :: State.t()
  def device_state!(device_id, model) do
    case device_state(device_id, model) do
      {:ok, state} -> state
      {:error, reason} -> raise Error, reason
    end
  end

  @doc """
  Turn on a device.

  ## Examples

      iex> GoveeLights.Api.turn_on("AA:BB:CC:DD:EE:FF:11:22", "H6008")
      {:ok, :updated}
  """
  @spec turn_on(String.t(), String.t()) :: {:ok, command_result()} | {:error, error_reason()}
  def turn_on(device_id, model), do: exec_command(device_id, model, "turn", "on")

  @doc """
  Bang variant of `turn_on/2`.
  """
  @spec turn_on!(String.t(), String.t()) :: command_result()
  def turn_on!(device_id, model), do: bang!(turn_on(device_id, model))

  @doc """
  Turn off a device.

  ## Examples

      iex> GoveeLights.Api.turn_off("AA:BB:CC:DD:EE:FF:11:22", "H6008")
      {:ok, :updated}
  """
  @spec turn_off(String.t(), String.t()) :: {:ok, command_result()} | {:error, error_reason()}
  def turn_off(device_id, model), do: exec_command(device_id, model, "turn", "off")

  @doc """
  Bang variant of `turn_off/2`.
  """
  @spec turn_off!(String.t(), String.t()) :: command_result()
  def turn_off!(device_id, model), do: bang!(turn_off(device_id, model))

  @doc """
  Set the brightness (0..100).

  ## Examples

      iex> GoveeLights.Api.set_brightness("AA:BB:CC:DD:EE:FF:11:22", "H6008", 10)
      {:ok, :updated}
  """
  @spec set_brightness(String.t(), String.t(), integer()) ::
          {:ok, command_result()} | {:error, error_reason()}
  def set_brightness(device_id, model, value)
      when is_integer(value) and value >= 0 and value <= 100 do
    exec_command(device_id, model, "brightness", value)
  end

  def set_brightness(_device_id, _model, value),
    do: {:error, {:invalid_command, "brightness", value}}

  @doc """
  Bang variant of `set_brightness/3`.
  """
  @spec set_brightness!(String.t(), String.t(), integer()) :: command_result()
  def set_brightness!(device_id, model, value), do: bang!(set_brightness(device_id, model, value))

  @doc """
  Set the color temperature (Kelvin).

  Govee devices support different ranges. You can inspect the range in the
  device `properties` returned by `devices/0`.

  ## Examples

      iex> GoveeLights.Api.set_temperature("AA:BB:CC:DD:EE:FF:11:22", "H6008", 2700)
      {:ok, :updated}
  """
  @spec set_temperature(String.t(), String.t(), integer()) ::
          {:ok, command_result()} | {:error, error_reason()}
  def set_temperature(device_id, model, value) when is_integer(value) and value > 0 do
    exec_command(device_id, model, "colorTem", value)
  end

  def set_temperature(_device_id, _model, value),
    do: {:error, {:invalid_command, "colorTem", value}}

  @doc """
  Bang variant of `set_temperature/3`.
  """
  @spec set_temperature!(String.t(), String.t(), integer()) :: command_result()
  def set_temperature!(device_id, model, value),
    do: bang!(set_temperature(device_id, model, value))

  @doc """
  Set the color of a device using RGB.

  The RGB map must contain integer `:r`, `:g`, `:b` values in `0..255`.

  ## Examples

      iex> GoveeLights.Api.set_color("AA:BB:CC:DD:EE:FF:11:22", "H6008", %{r: 255, g: 0, b: 0})
      {:ok, :updated}

      iex> GoveeLights.Api.set_color("AA:BB:CC:DD:EE:FF:11:22", "H6008", %{r: 999, g: 0, b: 0})
      {:error, {:invalid_command, "color", %{r: 999, g: 0, b: 0}}}
  """
  @spec set_color(String.t(), String.t(), map()) ::
          {:ok, command_result()} | {:error, error_reason()}
  def set_color(device_id, model, %{} = rgb) do
    case normalize_rgb(rgb) do
      {:ok, normalized} -> exec_command(device_id, model, "color", normalized)
      {:error, _} -> {:error, {:invalid_command, "color", rgb}}
    end
  end

  def set_color(_device_id, _model, value),
    do: {:error, {:invalid_command, "color", value}}

  @doc """
  Bang variant of `set_color/3`.
  """
  @spec set_color!(String.t(), String.t(), map()) :: command_result()
  def set_color!(device_id, model, rgb), do: bang!(set_color(device_id, model, rgb))

  defp extract_devices(%{"data" => %{"devices" => devices}}) when is_list(devices),
    do: {:ok, devices}

  defp extract_devices(other),
    do: {:error, {:decode_error, other}}

  defp build_devices(raw_devices) do
    Enum.reduce_while(raw_devices, {:ok, []}, fn raw, {:ok, acc} ->
      case build_device(raw) do
        {:ok, device} ->
          {:cont, {:ok, [device | acc]}}

        {:error, reason} ->
          {:halt, {:error, {:device_error, raw, reason}}}
      end
    end)
    |> case do
      {:ok, devices} -> {:ok, Enum.reverse(devices)}
      {:error, _} = error -> error
    end
  end

  defp build_device(raw) when is_map(raw) do
    %{
      id: raw["device"],
      model: raw["model"],
      name: raw["deviceName"],
      state: %{},
      properties: raw["properties"] || %{},
      controllable: raw["controllable"] || false
    }
    |> Device.new()
  end

  defp extract_state(%{"data" => %{} = data}), do: {:ok, data}
  defp extract_state(other), do: {:error, {:decode_error, other}}

  defp normalize_state_payload(%{"properties" => props} = raw) when is_list(props) do
    attrs =
      Enum.reduce(props, %{}, fn prop, acc ->
        Map.merge(acc, normalize_state_property(prop))
      end)

    attrs = Map.put(attrs, :last_checked, DateTime.utc_now())
    {:ok, attrs}
  rescue
    e ->
      {:error, {:state_error, raw, {:invalid_state_shape, e}}}
  end

  defp normalize_state_payload(raw),
    do: {:error, {:state_error, raw, {:invalid_state_shape, raw}}}

  defp normalize_state_property(%{"powerState" => "on"}), do: %{on: true}
  defp normalize_state_property(%{"powerState" => "off"}), do: %{on: false}
  defp normalize_state_property(%{"brightness" => value}), do: %{brightness: value}

  defp normalize_state_property(%{"color" => %{"b" => b, "g" => g, "r" => r}}),
    do: %{color: %{r: r, g: g, b: b}}

  # TODO: Implement this behavior 
  defp normalize_state_property(%{"online" => _online}), do: %{}
  defp normalize_state_property(_), do: %{}

  defp exec_command(device_id, model, command, value)
       when is_binary(device_id) and is_binary(model) do
    api_key = api_key!()

    case http_client().put(
           url: "#{@govee_base_url}#{@govee_endpoints[:device_control]}",
           headers: %{govee_api_key: api_key},
           json: %{
             "device" => device_id,
             "model" => model,
             "cmd" => %{
               "name" => command,
               "value" => value
             }
           }
         ) do
      {:ok, %{body: %{"code" => 200}}} ->
        {:ok, :updated}

      {:ok, %{body: %{"code" => code, "message" => msg}}} ->
        {:error, {:command_failed, command, value, code, msg}}

      {:ok, %{body: other}} ->
        {:error, {:decode_error, other}}

      {:error, error} ->
        {:error, {:http_error, error}}
    end
  end

  defp http_get(path, params_kw \\ []) do
    api_key = api_key!()

    http_client().get(
      url: "#{@govee_base_url}#{path}",
      headers: %{govee_api_key: api_key},
      params: params_kw
    )
  end

  defp http_client do
    Application.get_env(:govee_lights, :http_client, GoveeLights.HTTPClient)
  end

  @spec api_key!() :: String.t()
  defp api_key! do
    case Application.get_env(:govee_lights, :api_key) || System.get_env(@govee_api_key_name) do
      nil -> raise Error, {:config_error, "#{@govee_api_key_name} must be set."}
      api_key -> api_key
    end
  end

  defp bang!({:ok, value}), do: value
  defp bang!({:error, reason}), do: raise(Error, reason)

  defp normalize_rgb(%{r: r, g: g, b: b} = _rgb) do
    if valid_channel?(r) and valid_channel?(g) and valid_channel?(b) do
      {:ok, %{r: r, g: g, b: b}}
    else
      {:error, :invalid_rgb}
    end
  end

  defp normalize_rgb(_), do: {:error, :invalid_rgb}

  defp valid_channel?(c), do: is_integer(c) and c >= 0 and c <= 255
end
