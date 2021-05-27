defmodule Core.Factories do
  @moduledoc """
  This module provides factory function to be used for tests.
  """
  alias Core.Accounts.{User, Profile}
  alias Core.{Studies, SurveyTools, Authorization, DataUploader, NotificationCenter}
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
    |> build(%{researcher: true})
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

  def build(:author) do
    %Studies.Author{
      fullname: Faker.Person.name(),
      displayname: Faker.Person.first_name()
    }
  end

  def build(:survey_tool_participant) do
    build(
      :survey_tool_participant,
      %{
        survey_tool: build(:survey_tool),
        user: build(:member)
      }
    )
  end

  def build(:survey_tool) do
    build(:survey_tool, %{})
  end

  def build(:client_script) do
    build(:survey_tool, %{})
  end

  def build(:role_assignment) do
    %Authorization.RoleAssignment{}
  end

  def build(:participant) do
    %SurveyTools.Participant{}
  end

  def build(:notification_box, %{user: user} = attributes) do
    auth_node =
      build(:auth_node, %{
        role_assignments: [
          %{
            role: :owner,
            principal_id: GreenLight.Principal.id(user)
          }
        ]
      })

    %NotificationCenter.Box{}
    |> struct!(
      Map.delete(attributes, :user)
      |> Map.put(:auth_node, auth_node)
    )
  end

  def build(:author, %{} = attributes) do
    {researcher, attributes} = Map.pop(attributes, :researcher)
    {study, _attributes} = Map.pop(attributes, :study)

    build(:author)
    |> struct!(%{
      user: researcher,
      study: study
    })
  end

  def build(:study, %{} = attributes) do
    build(:study)
    |> struct!(%{
      authors: many_relationship(:authors, attributes)
    })
  end

  def build(:member, %{} = attributes) do
    {password, attributes} = Map.pop(attributes, :password)

    build(:member)
    |> struct!(
      if password do
        Map.put(attributes, :hashed_password, Bcrypt.hash_pwd_salt(password))
      else
        attributes
      end
    )
  end

  def build(:survey_tool_participant, %{} = attributes) do
    survey_tool = Map.get(attributes, :survey_tool, build(:survey_tool))
    user = Map.get(attributes, :user, build(:member))

    %SurveyTools.Participant{
      survey_tool: survey_tool,
      user: user
    }
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

  def build(:client_script, %{} = attributes) do
    {study, attributes} = Map.pop(attributes, :study, build(:study))

    %DataUploader.ClientScript{
      auth_node: build(:auth_node, %{parent: study.auth_node}),
      script: "def process():\n\tprint('hello')",
      study: study
    }
    |> struct!(attributes)
  end

  def build(factory_name, %{} = attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  def insert!(factory_name) do
    insert!(factory_name, %{})
  end

  def insert!(:survey_tool_task, %{} = attributes) do
    %{survey_tool: survey_tool, user: member} = insert!(:survey_tool_participant)

    %SurveyTools.SurveyToolTask{
      user: member,
      survey_tool: survey_tool,
      status: :pending
    }
    |> struct!(attributes)
    |> Repo.insert!()
  end

  def insert!(factory_name, %{} = attributes) do
    factory_name |> build(attributes) |> Repo.insert!()
  end

  def map_build(enumerable, factory, attributes_fn) do
    enumerable |> Enum.map(&build(factory, attributes_fn.(&1)))
  end

  def many_relationship(name, %{} = attributes) do
    result = Map.get(attributes, name)

    if result === nil do
      []
    else
      result
    end
  end
end
