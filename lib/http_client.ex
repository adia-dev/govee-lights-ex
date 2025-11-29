defmodule GoveeLights.HTTPClient do
  @moduledoc false

  @callback get(keyword()) :: {:ok, map()} | {:error, term()}
  @callback put(keyword()) :: {:ok, map()} | {:error, term()}

  def get(opts), do: Req.get(opts)
  def put(opts), do: Req.put(opts)
end
