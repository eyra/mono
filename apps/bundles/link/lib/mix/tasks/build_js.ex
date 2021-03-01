defmodule Mix.Tasks.BuildJs do
  @moduledoc """
  A Mix task to build the Javascript dependencies.
  """
  use Mix.Task

  def run(_) do
    sh = Mix.shell()
    sh.cmd("npm install", cd: "assets")
    sh.cmd("node node_modules/webpack/bin/webpack.js --mode development", cd: "assets")
  end
end
