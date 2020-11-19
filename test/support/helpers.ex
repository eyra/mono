defmodule Link.Authorization.TestEntity do
  @moduledoc """
  An entity that is only used for test purposes.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "test_entities" do
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(test_entity, attrs) do
    test_entity
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end

defmodule Link.TestHelpers do
  @moduledoc """
  Helper functions to make testing convenient.
  """
  alias Link.{Repo, Users.User}

  def user_fixture(attrs \\ %{}) do
    password = Faker.String.base64(32)

    %User{}
    |> Link.Users.User.changeset(
      Map.merge(
        %{email: Faker.Internet.email(), password: password, password_confirmation: password},
        attrs
      )
    )
    |> Repo.insert!()
  end

  def study_fixture(researcher) do
    {:ok, study} =
      Link.Studies.create_study(%{title: "Test Study", description: "Testing"}, researcher)

    study
  end
end
