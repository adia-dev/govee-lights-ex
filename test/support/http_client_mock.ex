defmodule GoveeLightsTest.HTTPClientMock do
  @behaviour GoveeLights.HTTPClient

  @devices_response [
    %{
      "controllable" => true,
      "device" => "0A:0A:0A:0A:0A:0A:0A:0A",
      "deviceName" => "User’s room",
      "model" => "H6008",
      "properties" => %{
        "colorTem" => %{"range" => %{"max" => 6500, "min" => 2700}}
      },
      "retrievable" => true,
      "supportCmds" => ["turn", "brightness", "color", "colorTem"]
    }
  ]
  @impl true
  @spec get(keyword()) :: {:ok, %{body: map()}} | {:error, term()}
  def get(_opts) do
    {:ok, %{body: %{"data" => %{"devices" => @devices_response}}}}
  end

  @impl true
  @spec put(keyword()) :: {:ok, %{body: map()}} | {:error, term()}
  def put(_opts) do
    {:ok, %{body: %{"code" => 200, "message" => "Success"}}}
  end
end
