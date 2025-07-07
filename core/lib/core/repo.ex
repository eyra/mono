defmodule Core.Repo do
  use Ecto.Repo,
    otp_app: :core,
    adapter: Ecto.Adapters.Postgres,
    types: GreenLight.Postgres.Types

  import Ecto.Query, warn: false
  alias Ecto.Multi

  require Logger

  def multi_update(multi, name, changeset) do
    multi
    |> multi_update_guard(name, changeset.data)
    |> Multi.update(name, changeset)
  end

  def multi_update_guard(multi, name, model) do
    Multi.run(multi, "#{name}_up_to_date?", fn repo, _ ->
      if up_to_date?(repo, model) do
        {:ok, true}
      else
        message = "#{String.capitalize(name)} is not up to date, preventing database change"
        Logger.warning(message)
        {:error, message}
      end
    end)
  end

  defp up_to_date?(repo, %schema{id: id, updated_at: updated_at}) do
    from(e in schema, where: e.id == ^id and e.updated_at == ^updated_at)
    |> repo.exists?()
  end

  @doc """
  Checks if a model is orphaned by checking if it has any associations with other models.
  The model is considered orphaned if it has no associations with other models.

  ## Options
  - `ignore`: A list of modules to ignore when checking for associations.
  Generally, this is a list of association/link tables

  ## Example
  ```elixir
  Repo.orphan?(%Systems.Annotation.Model{id: 1}, ignore: [Systems.Annotation.Assoc])
  ```
  """
  def orphan?(%module_under_inspection{id: model_id}, opts \\ []) do
    ignore_modules = Keyword.get(opts, :ignore, [])

    {:ok, modules} = :application.get_key(:core, :modules)

    modules
    |> Enum.reject(&(&1 in ignore_modules))
    |> Enum.filter(&({:__schema__, 1} in &1.__info__(:functions)))
    |> map_associations()
    |> map_belongs_to_fields(module_under_inspection)
    |> create_queries(model_id)
    |> run_queries()
  end

  defp map_associations(modules) do
    Enum.map(modules, fn module ->
      {module, module.__schema__(:associations)}
    end)
  end

  defp map_belongs_to_fields(module_associations, module_under_inspection) do
    Enum.reduce(module_associations, [], fn {module, associations}, acc ->
      acc ++
        case find_belongs_to_fields(module, associations, module_under_inspection) do
          [] -> []
          fields -> Enum.map(fields, &{module, &1})
        end
    end)
  end

  defp find_belongs_to_fields(module, associations, module_under_inspection) do
    associations
    |> Enum.map(&module.__schema__(:association, &1))
    |> Enum.filter(
      &match?(%{__struct__: Ecto.Association.BelongsTo, related: ^module_under_inspection}, &1)
    )
    |> Enum.map(fn %{field: field} ->
      field
    end)
  end

  defp run_queries(queries) do
    Enum.reduce(queries, true, fn query, acc ->
      acc && !exists?(query)
    end)
  end

  defp create_queries(module_fields, model_id) do
    Enum.map(module_fields, fn {module, field} ->
      create_query(module, field, model_id)
    end)
  end

  defp create_query(module, field, model_id)
       when is_atom(module) and is_atom(field) and is_integer(model_id) do
    field_id = String.to_existing_atom("#{field}_id")
    from(e in module, where: field(e, ^field_id) == ^model_id)
  end
end
