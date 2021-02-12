defmodule Link.Factories do
  @moduledoc """
  This module provides factory function to be used for tests.
  """
  alias Link.Users
  alias Link.{Studies, SurveyTools, Authorization}
  alias Link.Repo

  def build(:member) do
    %Users.User{
      email: Faker.Internet.email(),
      password_hash: Pow.Ecto.Schema.Password.pbkdf2_hash("S4p3rS3cr3t")
    }
  end

  def build(:researcher) do
    :member
    |> build()
    |> struct!(%{
      profile: %Users.Profile{
        fullname: Faker.Person.name(),
        displayname: Faker.Person.first_name(),
        researcher: true
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
