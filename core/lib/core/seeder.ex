defmodule Core.Seeder do
  @app :core

  def run(names) when is_list(names) do
    Enum.each(names, &run/1)
  end

  def run(name) when is_binary(name) or is_atom(name) do
    start_app()

    path = Application.app_dir(@app, "priv/repo/seeds/#{name}.exs")
    Code.eval_file(path)
  end

  def start_app do
    Application.ensure_all_started(@app)
  end
end
