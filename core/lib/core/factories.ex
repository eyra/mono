defmodule Core.Factories do
  @moduledoc """
  This module provides factory function to be used for tests.
  """
  alias Core.Accounts.{User, Profile}
  alias Core.{Studies, SurveyTools, Authorization}
  alias Core.Repo

  def valid_user_password, do: Faker.Util.format("%5d%5a%5A#")

  def build(:member) do
    %User{
      email: Faker.Internet.email(),
      hashed_password: Bcrypt.hash_pwd_salt(valid_user_password()),
      displayname: Faker.Person.first_name(),
      confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
  end

  def build(:researcher) do
    :member
    |> build(researcher: true)
    |> struct!(%{
      profile: %Profile{
        fullname: Faker.Person.name()
      }
    })
  end

  def build(:auth_node) do
    %Authorization.Node{}
  end

  def build(:study) do
    %Studies.Study{
      auth_node: build(:auth_node),
      description: Faker.Lorem.paragraph(),
      title: Faker.Lorem.sentence()
    }
  end

  def build(:survey_tool_participant) do
    %SurveyTools.Participant{
      survey_tool: build(:survey_tool),
      user: build(:member)
    }
  end

  def build(:survey_tool) do
    build(:survey_tool, %{})
  end

  def build(:role_assignment) do
    %Authorization.RoleAssignment{}
  end

  def build(:participant) do
    %SurveyTools.Participant{}
  end

  def build(:member, attributes) do
    {password, attributes} = Keyword.pop(attributes, :password)

    build(:member)
    |> struct!(
      if password do
        Keyword.put(attributes, :hashed_password, Bcrypt.hash_pwd_salt(password))
      else
        attributes
      end
    )
  end

  def build(:survey_tool, %{} = attributes) do
    {study, attributes} = Map.pop(attributes, :study, build(:study))

    %SurveyTools.SurveyTool{
      auth_node: build(:auth_node, %{parent: study.auth_node}),
      title: Faker.Lorem.sentence(),
      study: study
    }
    |> struct!(attributes)
  end

  def build(factory_name, attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  def insert!(factory_name, attributes \\ [])

  def insert!(:survey_tool_task, attributes) do
    %{survey_tool: survey_tool, user: member} = insert!(:survey_tool_participant)

    %SurveyTools.SurveyToolTask{
      user: member,
      survey_tool: survey_tool,
      status: :pending
    }
    |> struct!(attributes)
    |> Repo.insert!()
  end

  def insert!(factory_name, attributes) do
    factory_name |> build(attributes) |> Repo.insert!()
  end

  def map_build(enumerable, factory, attributes_fn) do
    enumerable |> Enum.map(&build(factory, attributes_fn.(&1)))
  end
end
