defmodule GoveeLights do
  @moduledoc """
  Simple Elixir wrapper around the Govee Developer API.

  To use this module, set the `GOVEE_API_KEY` environment variable:

      export GOVEE_API_KEY="your_key_here"

  You can request an API key from Govee here:
  https://developer.govee.com/reference/apply-you-govee-api-key

  This library is unofficial and not affiliated with Govee.

  If you have questions, suggestions or want to contribute, please open an
  issue or pull request on GitHub: https://github.com/adia-dev/govee-lights-ex

  ## Configuration

  You can configure the client by setting the `:http_client` option in your
  `config.exs` file:

      config :govee_lights, http_client: MyHTTPClient

  The default client is `GoveeLights.HTTPClient`, which uses the `req` library
  to make HTTP requests.

  If you want to use a different HTTP client, you can create a module that
  implements the `GoveeLights.HTTPClient` behaviour and set it as the client.

  For example, if you want to use the `Tesla` library, you can create a module
  like this:

      defmodule MyHTTPClient do
        @behaviour GoveeLights.HTTPClient

        def get(url, headers, params) do
          Tesla.get(url, headers, params)
        end

        def put(url, headers, json) do
          Tesla.put(url, headers, json)
        end
      end

  Then, set it as the client in your `config.exs` file:

      config :govee_lights, http_client: MyHTTPClient
  """

  @http_client Application.compile_env(:govee_lights, :http_client, GoveeLights.HTTPClient)

  @govee_api_key "GOVEE_API_KEY"
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

  @doc """
  Retrieve all devices associated with your Govee account.

  Returns a list of maps with device details, or `{:error, reason}` if the
  request fails.

  ## Examples

      iex> GoveeLights.devices()
      [
        %{
          "controllable" => true,
          "device" => "AA:BB:CC:DD:EE:FF:11:22",
          "deviceName" => "User’s room",
          "model" => "H6008",
          "properties" => %{
            "colorTem" => %{"range" => %{"max" => 6500, "min" => 2700}}
          },
          "retrievable" => true,
          "supportCmds" => ["turn", "brightness", "color", "colorTem"]
        }
      ]
  """
  def devices do
    api_key = api_key!()

    case @http_client.get(
           url: "#{@govee_base_url}#{@govee_endpoints[:devices]}",
           headers: %{govee_api_key: api_key}
         ) do
      {:ok, response} ->
        response.body["data"]["devices"]

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Retrieve the current state of a device.

  Returns a map with device details, or `{:error, reason}` if the request fails.

  ## Examples

      iex> GoveeLights.device_state("AA:BB:CC:DD:EE:FF:11:22", "H6008")
      %{
        "device" => "AA:BB:CC:DD:EE:FF:11:22",
        "model" => "H6008",
        "properties" => [
          %{"online" => true},
          %{"powerState" => "on"},
          %{"brightness" => 10},
          %{"color" => %{"b" => 156, "g" => 242, "r" => 36}}
        ]
      }
  """
  def device_state(device, model) do
    api_key = api_key!()

    case @http_client.get(
           url: "#{@govee_base_url}#{@govee_endpoints[:device_state]}",
           headers: %{govee_api_key: api_key},
           params: [device: device, model: model]
         ) do
      {:ok, response} ->
        response.body["data"]

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Turn on a device by its MAC address and model.

  Returns `{:ok, message}` on success or `{:error, reason}` on failure.

  ## Examples

      iex> GoveeLights.turn_on("AA:BB:CC:DD:EE:FF:11:22", "H6008")
      {:ok, "Device state updated"}
  """
  def turn_on(device, model), do: exec_command(device, model, "turn", "on")

  @doc """
  Turn off a device by its MAC address and model.

  Returns `{:ok, message}` on success or `{:error, reason}` on failure.

  ## Examples

      iex> GoveeLights.turn_off("AA:BB:CC:DD:EE:FF:11:22", "H6008")
      {:ok, "Device state updated"}
  """
  def turn_off(device, model), do: exec_command(device, model, "turn", "off")

  @doc """
  Set the brightness of a device (0–100).

  Setting the brightness to `0` is equivalent to calling `GoveeLights.turn_off/2`.

  Returns `{:ok, message}` on success or `{:error, reason}` on failure.

  ## Examples

      iex> GoveeLights.set_brightness("AA:BB:CC:DD:EE:FF:11:22", "H6008", 15)
      {:ok, "Device state updated"}
  """
  def set_brightness(device, model, value),
    do: exec_command(device, model, "brightness", value)

  @doc """
  Set the color temperature of a device (in Kelvin).

  The valid range for the value depends on the device model. You can find the
  supported range in the `colorTem` property returned by `GoveeLights.devices/0`.

  Returns `{:ok, message}` on success or `{:error, reason}` on failure.

  ## Examples

      iex> GoveeLights.set_temperature("AA:BB:CC:DD:EE:FF:11:22", "H6008", 2700)
      {:ok, "Device state updated"}
  """
  def set_temperature(device, model, value),
    do: exec_command(device, model, "colorTem", value)

  @doc """
  Set the color of a device (in RGB format).

  Returns `{:ok, message}` on success or `{:error, reason}` on failure.

  ## Examples:
      iex> GoveeLights.set_color("AA:BB:CC:DD:EE:FF:11:22", "H6008", %{r: 255, g: 0, b: 0})
      {:ok, "Device state updated"}
  """
  def set_color(device, model, %{r: r, g: g, b: b}),
    do: exec_command(device, model, "color", %{r: r, g: g, b: b})

  def set_color(_, _, _),
    do: {:error, "Invalid color format, expected: %{r: integer(), g: integer(), b: integer()}"}

  defp exec_command(device, model, command, value) do
    api_key = api_key!()

    case @http_client.put(
           url: "#{@govee_base_url}#{@govee_endpoints[:device_control]}",
           headers: %{govee_api_key: api_key},
           json: %{
             "device" => device,
             "model" => model,
             "cmd" => %{
               "name" => command,
               "value" => value
             }
           }
         ) do
      {:ok, response} ->
        if response.body["code"] == 200 do
          {:ok, "Device state updated"}
        else
          {
            :error,
            "Failed to change the state of the device for the command " <>
              "'#{command}' to '#{inspect(value)}', #{device}/#{model}: " <>
              "#{response.body["message"]}"
          }
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp api_key!() do
    case Application.get_env(:govee_lights, :api_key) || System.get_env(@govee_api_key) do
      nil ->
        exit("#{@govee_api_key} must be set.")

      api_key ->
        api_key
    end
  end
end
