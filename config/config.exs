import Config

config :govee_lights,
  http_client: GoveeLights.HTTPClient,
  base_url: "https://developer-api.govee.com/v1",
  api_key: nil

import_config "#{Mix.env()}.exs"
