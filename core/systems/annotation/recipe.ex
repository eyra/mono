defprotocol Systems.Annotation.Recipe do
  @moduledoc """
  A protocol for creating Annotations Recipes.
  Naming convention:
  - Each recipe is named after the type of annotation it creates.
  - Each recipe name is a noun, like "Definition", "Parameter", "Retraction", etc.
  """

  # FIXME: Remove hard dependency on Ecto
  alias Ecto.Query

  alias Systems.Annotation

  @doc """
    Obtain an annotation from a recipe. It returns an annotation and inserts it if it doesn't exist.
  """
  @spec obtain(t) :: {:ok, Annotation.Model.t()} | {:error, {atom(), any()}}
  def obtain(t)

  @doc """
    Query annotations based on a recipe. It returns a query that can be used to load annotations from the database.
  """
  @spec query(t) :: {:ok, Query.t()} | {:error, {atom(), any()}}
  def query(t)
end
