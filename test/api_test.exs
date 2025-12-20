defmodule GoveeLightsTest.ApiTest do
  use ExUnit.Case, async: true

  doctest GoveeLights.Api

  alias GoveeLights.Api
  alias GoveeLights.Device
  alias GoveeLights.Device.State

  describe "devices/0" do
    test "returns a list of Device structs" do
      assert {:ok, [%Device{} = device]} = Api.devices()

      assert device.id == "AA:BB:CC:DD:EE:FF:11:22"
      assert device.model == "H6008"
      assert device.name == "User’s room"

      assert %State{on: :unknown, brightness: :unknown, color: :unknown, last_checked: nil} =
               device.state

      assert is_map(device.properties)
      assert device.controllable == true
    end

    test "bang variant returns list or raises" do
      devices = Api.devices!()
      assert is_list(devices)
      assert Enum.all?(devices, &match?(%Device{}, &1))
    end
  end

  describe "device_state/2" do
    test "returns a normalized State struct from the Govee properties list" do
      assert {:ok, %State{} = state} =
               Api.device_state("AA:BB:CC:DD:EE:FF:11:22", "H6008")

      assert state.on == true
      assert state.brightness == 10
      assert state.color == %{r: 36, g: 242, b: 156}
      assert %DateTime{} = state.last_checked
    end

    test "bang variant returns State or raises" do
      state = Api.device_state!("AA:BB:CC:DD:EE:FF:11:22", "H6008")
      assert %State{} = state
    end
  end

  describe "commands" do
    test "turn_on/2 returns ok" do
      assert {:ok, :updated} = Api.turn_on("AA:BB:CC:DD:EE:FF:11:22", "H6008")
    end

    test "turn_off/2 returns ok" do
      assert {:ok, :updated} = Api.turn_off("AA:BB:CC:DD:EE:FF:11:22", "H6008")
    end

    test "set_brightness/3 returns ok for valid range" do
      assert {:ok, :updated} =
               Api.set_brightness("AA:BB:CC:DD:EE:FF:11:22", "H6008", 50)
    end

    test "set_brightness/3 returns invalid_command for out of range" do
      assert {:error, {:invalid_command, "brightness", 101}} =
               Api.set_brightness("AA:BB:CC:DD:EE:FF:11:22", "H6008", 101)

      assert {:error, {:invalid_command, "brightness", -1}} =
               Api.set_brightness("AA:BB:CC:DD:EE:FF:11:22", "H6008", -1)
    end

    test "set_color/3 returns ok for valid rgb" do
      assert {:ok, :updated} =
               Api.set_color("AA:BB:CC:DD:EE:FF:11:22", "H6008", %{r: 255, g: 0, b: 0})
    end

    test "set_color/3 returns invalid_command for invalid rgb" do
      assert {:error, {:invalid_command, "color", %{r: 999, g: 0, b: 0}}} =
               Api.set_color("AA:BB:CC:DD:EE:FF:11:22", "H6008", %{r: 999, g: 0, b: 0})

      assert {:error, {:invalid_command, "color", "nope"}} =
               Api.set_color("AA:BB:CC:DD:EE:FF:11:22", "H6008", "nope")
    end

    test "bang variants return :updated" do
      assert :updated = Api.turn_on!("AA:BB:CC:DD:EE:FF:11:22", "H6008")
      assert :updated = Api.set_brightness!("AA:BB:CC:DD:EE:FF:11:22", "H6008", 10)
    end
  end
end
