defmodule GoveeLightsTest.DeviceTest do
  use ExUnit.Case, async: true

  doctest GoveeLights.Device

  alias GoveeLights.Device
  alias GoveeLights.Device.State

  describe "new/1 with valid attrs" do
    test "builds a device from a map with atom keys" do
      attrs = %{
        id: "AA:BB:CC:DD:EE:FF:11:22",
        model: "H6008",
        name: "Backrooms",
        state: %{on: true},
        properties: %{brightness: 50},
        controllable: true
      }

      assert {:ok, %Device{} = device} = Device.new(attrs)
      assert device.id == "AA:BB:CC:DD:EE:FF:11:22"
      assert device.model == "H6008"
      assert device.name == "Backrooms"

      assert %State{
               on: true,
               brightness: :unknown,
               color: :unknown,
               last_checked: nil
             } = device.state

      assert device.properties == %{brightness: 50}
      assert device.controllable == true
    end

    test "builds a device with optional fields omitted" do
      attrs = %{
        "id" => "AA:BB:CC:DD:EE:FF:11:22",
        "model" => "H5678"
      }

      assert {:ok, %Device{} = device} = Device.new(attrs)
      assert device.id == "AA:BB:CC:DD:EE:FF:11:22"
      assert device.model == "H5678"

      assert is_nil(device.name)

      assert %GoveeLights.Device.State{
               brightness: :unknown,
               color: :unknown,
               last_checked: nil,
               on: :unknown
             } = device.state

      assert device.properties == %{}
      assert device.controllable == false
    end

    test "builds a device from a map with string keys" do
      attrs = %{
        "id" => "AA:BB:CC:DD:EE:FF:11:22",
        "model" => "H5678",
        "name" => "Bedroom"
      }

      assert {:ok, %Device{} = device} = Device.new(attrs)
      assert device.id == "AA:BB:CC:DD:EE:FF:11:22"
      assert device.model == "H5678"
      assert device.name == "Bedroom"
    end

    test "builds a device from a keyword list" do
      attrs = [
        id: "AA:BB:CC:DD:EE:FF:11:22",
        model: "H5678",
        name: "Bedroom"
      ]

      assert {:ok, %Device{} = device} = Device.new(attrs)
      assert device.id == "AA:BB:CC:DD:EE:FF:11:22"
      assert device.model == "H5678"
      assert device.name == "Bedroom"
    end
  end

  describe "new/1 with invalid attrs" do
    test "returns an error when id missing" do
      attrs = %{
        model: "H6008"
      }

      assert {:error, {:missing, :id}} = Device.new(attrs)
    end

    test "returns an error when model is missing" do
      attrs = %{
        id: "AA:BB:CC:DD:EE:FF:11:22"
      }

      assert {:error, {:missing, :model}} = Device.new(attrs)
    end

    test "returns an error when id is not a string" do
      attrs = %{
        id: 111
      }

      assert {:error, {:invalid_string, :id, 111}} = Device.new(attrs)
    end

    test "returns an error when model is not a string" do
      attrs = %{
        id: "AA:BB:CC:DD:EE:FF:11:22",
        model: 111
      }

      assert {:error, {:invalid_string, :model, 111}} = Device.new(attrs)
    end

    test "returns an error when id is empty" do
      attrs = %{
        id: ""
      }

      assert {:error, {:invalid_string, :id, ""}} = Device.new(attrs)
    end

    test "returns an error when model is empty" do
      attrs = %{
        id: "AA:BB:CC:DD:EE:FF:11:22",
        model: ""
      }

      assert {:error, {:invalid_string, :model, ""}} = Device.new(attrs)
    end

    test "returns an error when properties is not a map" do
      attrs = %{
        id: "AA:BB:CC:DD:EE:FF:11:22",
        model: "H6008",
        properties: "eheh"
      }

      assert {:error, {:invalid_map, :properties, "eheh"}} = Device.new(attrs)
    end

    test "returns an error when controllable is not a boolean" do
      attrs = %{
        id: "AA:BB:CC:DD:EE:FF:11:22",
        model: "H6008",
        controllable: "not-a-boolean"
      }

      assert {:error, {:invalid_boolean, :controllable, "not-a-boolean"}} = Device.new(attrs)
    end

    test "returns an error when attrs is not a keyword list" do
      attrs = [1, 2, 3]

      assert {:error, {:invalid_attrs, :expected_keyword_list}} = Device.new(attrs)
    end

    test "returns an error when attrs is not a map nor a keyword list" do
      attrs = 1

      assert {:error, {:invalid_attrs, :expected_map_or_keyword_list}} = Device.new(attrs)
    end
  end

  test "new/1 ignores unknown keys" do
    attrs = %{
      id: "AA:BB:CC:DD:EE:FF:11:22",
      model: "H6008",
      age: 1
    }

    assert {:ok, %Device{} = device} = Device.new(attrs)
    assert device.id == "AA:BB:CC:DD:EE:FF:11:22"
    assert device.model == "H6008"

    refute Map.has_key?(device, :age)
  end
end
