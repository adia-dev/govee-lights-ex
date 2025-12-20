defmodule GoveeLightsTest.ApiErrorsTest do
  use ExUnit.Case, async: true

  alias GoveeLights.Api

  setup do
    old = Application.get_env(:govee_lights, :http_client)
    Application.put_env(:govee_lights, :http_client, GoveeLightsTest.HTTPClientFailMock)

    on_exit(fn ->
      Application.put_env(:govee_lights, :http_client, old)
    end)

    :ok
  end

  test "devices/0 tags transport errors as http_error" do
    assert {:error, {:http_error, :timeout}} = Api.devices()
  end

  test "turn_on/2 tags transport errors as http_error" do
    assert {:error, {:http_error, :timeout}} = Api.turn_on("d", "m")
  end

  test "bang variants raise Api.Error with the same reason" do
    assert_raise GoveeLights.Api.Error, fn ->
      Api.devices!()
    end
  end
end
