import Config

config :govee_lights,
  http_client: GoveeLights.HTTPClient,
  api_key: nil

import_config "#{Mix.env()}.exs"
