defmodule GoveeLightsTest.DeviceStateTest do
  use ExUnit.Case, async: true

  doctest GoveeLights.Device.State

  alias GoveeLights.Device.State

  describe "new/1 with valid attrs" do
    test "builds a default state from an empty map" do
      assert {:ok, %State{} = state} = State.new(%{})

      assert state.on == :unknown
      assert state.brightness == :unknown
      assert state.color == :unknown
      assert state.last_checked == nil
    end

    test "builds a state with only on flag" do
      assert {:ok, %State{} = state} = State.new(%{on: true})

      assert state.on == true
      assert state.brightness == :unknown
      assert state.color == :unknown
    end

    test "builds a state with brightness in range" do
      for value <- [0, 1, 50, 100] do
        assert {:ok, %State{} = state} = State.new(%{brightness: value})
        assert state.brightness == value
      end
    end

    test "builds a state with valid RGB color" do
      attrs = %{
        color: %{r: 0, g: 128, b: 255}
      }

      assert {:ok, %State{} = state} = State.new(attrs)

      assert state.color == %{r: 0, g: 128, b: 255}
      assert state.on == :unknown
      assert state.brightness == :unknown
    end

    test "sets last_checked when provided" do
      ts = ~U[2025-01-02 12:00:00Z]
      assert {:ok, %State{} = state} = State.new(%{last_checked: ts})

      assert state.last_checked == ts
    end

    test "ignores unknown keys" do
      assert {:ok, %State{} = state} =
               State.new(%{
                 on: false,
                 brightness: 10,
                 color: %{r: 1, g: 2, b: 3},
                 foo: "bar",
                 baz: 123
               })

      assert state.on == false
      assert state.brightness == 10
      assert state.color == %{r: 1, g: 2, b: 3}
      refute Map.has_key?(state, :foo)
      refute Map.has_key?(state, :baz)
    end
  end

  describe "new/1 with invalid on" do
    test "returns error when on is not a boolean" do
      assert {:error, {:invalid_boolean, :on, "yes"}} =
               State.new(%{on: "yes"})

      assert {:error, {:invalid_boolean, :on, 1}} =
               State.new(%{on: 1})
    end
  end

  describe "new/1 with invalid brightness" do
    test "returns error when brightness is negative" do
      assert {:error, {:invalid_brightness, -1}} =
               State.new(%{brightness: -1})
    end

    test "returns error when brightness is above 100" do
      assert {:error, {:invalid_brightness, 101}} =
               State.new(%{brightness: 101})
    end

    test "returns error when brightness is not an integer" do
      for val <- ["100", 50.5, :fifty] do
        assert {:error, {:invalid_brightness, ^val}} =
                 State.new(%{brightness: val})
      end
    end
  end

  describe "new/1 with invalid color" do
    test "returns error when color is not a map" do
      assert {:error, {:invalid_color, "not-a-map"}} =
               State.new(%{color: "not-a-map"})

      assert {:error, {:invalid_color, 123}} =
               State.new(%{color: 123})
    end

    test "returns error when color map is missing channels" do
      assert {:error, {:invalid_color, %{r: 0, g: 0}, "expected a map with r, g, b"}} =
               State.new(%{color: %{r: 0, g: 0}})

      assert {:error, {:invalid_color, %{}, "expected a map with r, g, b"}} =
               State.new(%{color: %{}})
    end

    test "returns error when one of the channels is out of range" do
      bad_colors = [
        %{r: -1, g: 0, b: 0},
        %{r: 0, g: -1, b: 0},
        %{r: 0, g: 0, b: -1},
        %{r: 256, g: 0, b: 0},
        %{r: 0, g: 256, b: 0},
        %{r: 0, g: 0, b: 256}
      ]

      Enum.each(bad_colors, fn color ->
        assert {:error, {:invalid_color, ^color, "expected r, g, b in 0..255"}} =
                 State.new(%{color: color})
      end)
    end

    test "returns error when channels are not integers" do
      bad_colors = [
        %{r: 0.5, g: 0, b: 0},
        %{r: 0, g: "0", b: 0},
        %{r: :r, g: 0, b: 0}
      ]

      Enum.each(bad_colors, fn color ->
        assert {:error, {:invalid_color, ^color, "expected r, g, b in 0..255"}} =
                 State.new(%{color: color})
      end)
    end
  end
end
