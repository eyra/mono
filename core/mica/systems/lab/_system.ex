defmodule Systems.Lab.System do
  use Mica.System

  def routes do
    quote do
      require Systems.Lab.Routes
      Systems.Lab.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Lab.ToolModel, [:owner, :participant]},
        {Systems.Lab.PublicPage, [:member]}
      ]
    end
  end
end
