defmodule GoveeLights do
  @moduledoc """
  Documentation for `GoveeLights`.
  """

  @govee_api_key "GOVEE_API_KEY"
  @govee_base_url "https://developer-api.govee.com/v1"
  @govee_endpoints [devices: "/devices", state: "/state"]

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

    request =
      Req.new(
        method: :get,
        url: "#{@govee_base_url}#{@govee_endpoints[:devices]}",
        headers: %{govee_api_key: api_key}
      )

    case Req.get(request) do
      {:ok, response} ->
        response.body["data"]["devices"]

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
