defmodule Link.Factories do
  @moduledoc """
  This module provides factory function to be used for tests.
  """
  alias Link.Users
  alias Link.{Studies, SurveyTools}
  alias Link.Repo

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

  def build(:survey_tool_task) do
    member = build(:member)

    %SurveyTools.SurveyToolTask{
      user: member,
      survey_tool: build(:survey_tool, participants: [member]),
      status: :pending
    }
  end

  def build(factory_name, attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  def insert!(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> Repo.insert!()
  end
end
