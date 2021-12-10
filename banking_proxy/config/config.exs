import Config

if Mix.env() != :dev || File.exists?("config/dev.exs") do
  import_config "#{Mix.env()}.exs"
end
