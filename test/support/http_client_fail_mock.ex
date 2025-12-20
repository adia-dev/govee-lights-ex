defmodule GoveeLightsTest.HTTPClientFailMock do
  @behaviour GoveeLights.HTTPClient

  @impl true
  def get(_opts), do: {:error, :timeout}

  @impl true
  def put(_opts), do: {:error, :timeout}
end

