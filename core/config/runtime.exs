import Config

if config_env() == :dev do
  env_file = Path.expand("../.env", __DIR__)

  if File.exists?(env_file) do
    env_file
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Stream.map(fn line ->
      line
      |> String.replace_prefix("export ", "")
      |> String.split("=", parts: 2)
    end)
    |> Enum.each(fn
      [key, value] ->
        unquoted =
          value
          |> String.trim()
          |> String.trim_leading(~s("))
          |> String.trim_trailing(~s("))
          |> String.trim_leading("'")
          |> String.trim_trailing("'")

        System.put_env(key, unquoted)

      _ ->
        :ok
    end)
  end

  config :core, base_url: System.get_env("APP_DOMAIN") || "http://localhost:4000"

  config :core, :payment_webhook_base_url, System.get_env("PAYMENT_WEBHOOK_BASE_URL")
end
