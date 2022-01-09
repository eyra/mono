defmodule Frameworks.Utility.Model do
  @moduledoc """
  The content node schema.
  """
  @callback operational_fields() :: list(atom())
  @callback operational_validation(Ecto.Changeset.t()) :: Ecto.Changeset.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Frameworks.Utility.Model

      import Ecto.Changeset
      alias Core.Repo

      def operational_changeset(entity, attrs) do
        changeset =
          entity
          |> cast(attrs, operational_fields())
          |> validate_required(operational_fields())
          |> operational_validation()
      end
    end
  end
end
