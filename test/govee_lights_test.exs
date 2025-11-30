defmodule GoveeLightsTest do
  use ExUnit.Case, async: true
  doctest GoveeLights

  test "devices/0 returns the mocked devices" do
    assert GoveeLights.devices() == [
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
  end

  test "turn_on/2 delegates to HTTP client and returns ok" do
    assert {:ok, "Device state updated"} =
             GoveeLights.turn_on("AA:BB:CC:DD:EE:FF:11:22", "H6008")
  end
end
