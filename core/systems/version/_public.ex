defmodule Systems.Version.Public do
  alias Systems.Version

  def prepare_first() do
    Version.Model.prepare_first()
  end

  def prepare_new(%Version.Model{} = version) do
    Version.Model.prepare_new(version)
  end
end
