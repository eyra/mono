defmodule Systems.Sequence.Public do
  import Ecto.Query, warn: false
  alias Core.Repo

  alias Systems.{
    Sequence
  }

  def get!(id, preload \\ []) do
    from(c in Sequence.Model,
      where: c.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def create() do
    %Sequence.Model{}
    |> Sequence.Model.changeset(%{})
    |> Repo.insert!()
  end
end
