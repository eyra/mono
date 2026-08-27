defmodule Systems.Version.Queries do
  @moduledoc false
  import Ecto.Query
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Version

  require Frameworks.Utility.Query

  def version_query do
    from(v in Version.Model, as: :version)
  end

  def version_query(%Version.Model{id: id}) do
    build(version_query(), :version, [id == ^id])
  end
end
