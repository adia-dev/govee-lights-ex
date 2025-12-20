defmodule GoveeLights.HTTPClient do
  @moduledoc """
  Behaviour for the HTTP client adapter used by `GoveeLights.Api`.

  Configure a custom implementation via:

      config :govee_lights, http_client: MyHTTPClient

  The module must implement `c:get/1` and `c:put/1`.
  """

  @callback get(keyword()) :: {:ok, map()} | {:error, term()}
  @callback put(keyword()) :: {:ok, map()} | {:error, term()}

  def get(opts), do: Req.get(opts)
  def put(opts), do: Req.put(opts)
end
