defmodule Core.Pools do
  alias Core.Pools.Pool
  alias Core.Repo

  def list() do
    ensure_student_pool()
    Repo.all(Pool)
  end

  def get!(id), do: Repo.get!(Pool, id)
  def get(id), do: Repo.get(Pool, id)

  def get_by_name(name) when is_atom(name), do: get_by_name(Atom.to_string(name))

  def get_by_name(name) do
    ensure_student_pool()
    Repo.get_by(Pool, name: name)
  end

  defp ensure_student_pool() do
    case Repo.get_by(Pool, name: "vu_students") do
      nil -> create_student_pool()
      pool -> {:ok, pool}
    end
  end

  defp create_student_pool() do
    %Pool{name: "vu_students"}
    |> Repo.insert!()
  end
end
