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
end
