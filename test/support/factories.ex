defmodule Link.Factories do
  @moduledoc """
  This module provides factory function to be used for tests.
  """
  alias Link.Users
  alias Link.Studies

  @user_attrs %{
    email: "user@example.com",
    password: "S4p3rS3cr3t",
    password_confirmation: "S4p3rS3cr3t"
  }
  @researcher_email "researcher@example.com"
  @study_attrs %{description: "some description", title: "some title"}

  def get_or_create_user(attrs \\ []) do
    merged_attrs = Enum.into(attrs, @user_attrs)
    Users.get_by(email: merged_attrs.email) || Users.create!(merged_attrs)
  end

  def get_or_create_researcher(attrs \\ []) do
    user =
      attrs
      |> Keyword.merge(email: @researcher_email)
      |> get_or_create_user()

    user
    |> Users.get_profile()
    |> Users.update_profile(%{researcher: true, fullname: "Grace Hopper"})

    user
  end

  def create_study(attrs \\ []) do
    {researcher, study_attrs} = Keyword.pop(attrs, :owner)
    researcher = researcher || get_or_create_researcher()

    {:ok, study} =
      study_attrs
      |> Enum.into(@study_attrs)
      |> Studies.create_study(researcher)

    study
  end
end
