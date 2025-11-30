defmodule GoveeLightsTest.HTTPClientMock do
  @behaviour GoveeLights.HTTPClient

  @devices_response [
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

  @device_state_response %{
    "device" => "AA:BB:CC:DD:EE:FF:11:22",
    "model" => "H6008",
    "properties" => [
      %{"online" => true},
      %{"powerState" => "on"},
      %{"brightness" => 10},
      %{"color" => %{"b" => 156, "g" => 242, "r" => 36}}
    ]
  }

  @impl true
  @spec get(keyword()) :: {:ok, %{body: map()}} | {:error, term()}
  def get(opts) do
    case opts[:url] do
      "https://developer-api.govee.com/v1/devices" ->
        {:ok, %{body: %{"data" => %{"devices" => @devices_response}}}}

      "https://developer-api.govee.com/v1/devices/state" ->
        {:ok, %{body: %{"data" => @device_state_response}}}

      _ ->
        {:error, "Invalid URL"}
    end
  end

  @impl true
  @spec put(keyword()) :: {:ok, %{body: map()}} | {:error, term()}
  def put(_opts) do
    {:ok, %{body: %{"code" => 200, "message" => "Success"}}}
  end
end
