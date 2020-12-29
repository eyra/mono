defmodule Link.Factories do
  @moduledoc """
  This module provides factory function to be used for tests.
  """
  alias Link.Users
  alias Link.Studies
  alias Link.Repo

  def get_or_create_user(attrs \\ []) do
    merged_attrs =
      Enum.into(attrs, %{
        email: Faker.Internet.email(),
        password: "S4p3rS3cr3t",
        password_confirmation: "S4p3rS3cr3t"
      })

    Users.get_by(email: merged_attrs.email) || Users.create!(merged_attrs)
  end

  def build(:member) do
    %Users.User{
      email: Faker.Internet.email(),
      password: "S4p3rS3cr3t"
    }
  end

  def build(:researcher) do
    :member
    |> build()
    |> Map.merge(%{
      profile: %Users.Profile{
        fullname: Faker.Person.name(),
        displayname: Faker.Person.first_name(),
        researcher: true
      }
    })
  end

  def build(:study) do
    %Studies.Study{
      description: Faker.Lorem.paragraph(),
      title: Faker.Lorem.sentence()
    }
  end

  def build(factory_name, attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  def insert!(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> Repo.insert!()
  end
end
