defmodule Link.Factories do
  @moduledoc """
  This module provides factory function to be used for tests.
  """
  alias Link.Users
  alias Link.Studies

  def get_or_create_user(attrs \\ []) do
    merged_attrs =
      Enum.into(attrs, %{
        email: Faker.Internet.email(),
        password: "S4p3rS3cr3t",
        password_confirmation: "S4p3rS3cr3t"
      })

    Users.get_by(email: merged_attrs.email) || Users.create!(merged_attrs)
  end

  def get_or_create_researcher(attrs \\ []) do
    user = get_or_create_user(attrs)

    user
    |> Users.get_profile()
    |> Users.update_profile(%{researcher: true, fullname: Faker.Person.last_name(), displayname: Faker.Person.last_name()})

    user
  end

  def create_study(attrs \\ []) do
    {researcher, study_attrs} = Keyword.pop(attrs, :owner)
    researcher = researcher || get_or_create_researcher()

    {:ok, study} =
      study_attrs
      |> Enum.into(%{description: Faker.Lorem.sentence(), title: Faker.Lorem.sentence()})
      |> Studies.create_study(researcher)

    study
  end
end
