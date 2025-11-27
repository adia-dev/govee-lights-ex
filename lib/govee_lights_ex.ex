defmodule GoveeLights do
  @moduledoc """
  Documentation for `GoveeLights`.
  """

  @govee_api_key "GOVEE_API_KEY"
  @govee_base_url "https://developer-api.govee.com/v1"
  @govee_endpoints [devices: "/devices", device_control: "/devices/control"]

  @doc """
  Hello world.

  ## Examples

      iex> GoveeLights.hello()
      :world

  """
  def hello do
    :world
  end

  def devices do
    api_key = api_key!()

    case Req.get(
           url: "#{@govee_base_url}#{@govee_endpoints[:devices]}",
           headers: %{govee_api_key: api_key}
         ) do
      {:ok, response} ->
        response.body["data"]["devices"]

      {:error, error} ->
        {:error, error}
    end
  end

  def turn_on(device, model), do: exec_command(device, model, "turn", "on")
  def turn_off(device, model), do: exec_command(device, model, "turn", "off")
  def set_brightness(device, model, value), do: exec_command(device, model, "brightness", value)
  def set_temperature(device, model, value), do: exec_command(device, model, "colorTem", value)

  defp exec_command(device, model, command, value) do
    api_key = api_key!()

    case Req.put(
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
            "Failed to change the state of the device for the command #{command} to #{value}, #{device}/#{model}: #{response.body["message"]}"
          }
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp api_key!() do
    case System.get_env(@govee_api_key) do
      nil ->
        exit("#{@govee_api_key} must be set.")

      api_key ->
        api_key
    end
  end
end
