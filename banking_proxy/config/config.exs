import Config

if config_env() != :dev || File.exists?("config/dev.exs") do
  import_config "#{config_env()}.exs"
end
