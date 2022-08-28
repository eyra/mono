defmodule Systems.Scholar.Context do
  alias Ecto.Multi
  alias Core.Repo
  alias Core.Accounts.User

  alias Frameworks.Signal

  alias Systems.{
    Scholar,
    Org
  }

  def course_patterns(_user) do
    # FIXME: determine which pools are for the current user
    ["vu", ":2021"]
  end

  def list_universities(template \\ [], preload \\ []) do
    Org.Context.list_nodes(:university, template, preload)
  end

  def list_faculties(template \\ [], preload \\ []) do
    Org.Context.list_nodes(:faculty, template, preload)
  end

  def list_programs(template \\ [], preload \\ []) do
    Org.Context.list_nodes(:scholar_program, template, preload)
  end

  def list_classes(_, preload \\ [])

  def list_classes(%User{} = user, preload) do
    Org.Context.list_nodes(user, :scholar_class, preload)
  end

  def list_classes(template, preload) do
    Org.Context.list_nodes(:scholar_class, template, preload)
  end

  def list_courses(_, preload \\ [])

  def list_courses(%User{} = user, preload) do
    Org.Context.list_nodes(user, :scholar_course, preload)
  end

  def list_courses(template, preload) do
    Org.Context.list_nodes(:scholar_course, template, preload)
  end

  def update_class_accociations(%User{} = user, old_codes, new_codes) do
    added_to_classes =
      (new_codes -- old_codes)
      |> map_to_scholar_class_nodes()

    deleted_from_classes =
      (old_codes -- new_codes)
      |> map_to_scholar_class_nodes()

    Multi.new()
    |> Multi.run(:add, fn _, _ ->
      added_to_classes
      |> update_classes(user, :add)

      {:ok, true}
    end)
    |> Multi.run(:delete, fn _, _ ->
      deleted_from_classes
      |> update_classes(user, :delete)

      {:ok, true}
    end)
    |> Signal.Context.multi_dispatch(
      :scholar_class_updated,
      %{
        user: user,
        added_to: added_to_classes,
        deleted_from: deleted_from_classes
      }
    )
    |> Repo.transaction()
  end

  defp update_classes([_ | _] = class_nodes, user, command) do
    class_nodes
    |> Enum.map(&update_class(&1, user, command))
  end

  defp update_classes(_, _, _), do: nil

  defp update_class(class, user, :add), do: Org.Context.add_user(class, user)
  defp update_class(class, user, :delete), do: Org.Context.delete_user(class, user)

  defp map_to_scholar_class_nodes(codes) do
    codes
    |> Enum.map(&scholar_class_node(&1))
    |> Enum.uniq()
  end

  defp scholar_class_node(code), do: Scholar.Class.identifier(code)
end
