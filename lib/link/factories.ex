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

  def build(:study_participant) do
    %Studies.Participant{
      study: build(:study),
      user: build(:member),
      status: :applied
    }
  end

  def build(:survey_tool) do
    %SurveyTools.SurveyTool{
      title: Faker.Lorem.sentence(),
      study: build(:study)
    }
  end

  def build(:role_assignment) do
    %Authorization.RoleAssignment{}
  end

  def build(:participant) do
    %Studies.Participant{}
  end

  def build(factory_name, attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  def insert!(factory_name, attributes \\ [])

  def insert!(:survey_tool_task, attributes) do
    member = insert!(:member)
    study = insert!(:study)
    insert!(:study_participant, user: member, study: study)
    survey_tool = insert!(:survey_tool, study: study)

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
