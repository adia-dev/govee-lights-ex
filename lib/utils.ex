defmodule GoveeLights.Utils do
  def fetch_string(map, key, options \\ []) do
    case Map.fetch(map, key) do
      :error ->
        if options[:optional] == true do
          {:ok, nil}
        else
          {:error, {:missing, key}}
        end

      {:ok, val} when is_binary(val) and val != "" ->
        {:ok, val}

      {:ok, val} ->
        if val == "" and options[:optional] == true do
          {:ok, val}
        else
          {:error, {:invalid_string, key, val}}
        end
    end
  end

  def fetch_optional_map(map, key, default \\ %{}) do
    case Map.fetch(map, key) do
      :error ->
        {:ok, default}

      {:ok, val} when is_map(val) ->
        {:ok, val}

      {:ok, val} ->
        {:error, {:invalid_map, key, val}}
    end
  end

  def fetch_optional_boolean(map, key, default \\ false) do
    case Map.fetch(map, key) do
      :error ->
        {:ok, default}

      {:ok, val} when is_boolean(val) ->
        {:ok, val}

      {:ok, val} ->
        {:error, {:invalid_boolean, key, val}}
    end
  end
end
