defmodule Core.Studies.StudyEdit.Test do
  use ExUnit.Case, async: true
  alias Core.Factories
  alias Core.Studies.StudyEdit

  test "create merges study and survey tool into new struct" do
    study = Factories.build(:study)
    survey_tool = Factories.build(:survey_tool)
    merged = StudyEdit.create(study, survey_tool)
    assert merged.title == study.title
    assert merged.description == survey_tool.description
    assert merged.survey_url == survey_tool.survey_url
    assert merged.subject_count == survey_tool.subject_count
    assert merged.phone_enabled == survey_tool.phone_enabled
    assert merged.tablet_enabled == survey_tool.tablet_enabled
    assert merged.desktop_enabled == survey_tool.desktop_enabled
  end

  test "to_study splits out only the fields needed for the study" do
    study = Factories.build(:study)
    survey_tool = Factories.build(:survey_tool)
    merged = StudyEdit.create(study, survey_tool)
    assert StudyEdit.to_study(merged) == %{title: study.title}
  end

  test "to_survey_tool splits out only the fields needed for the study" do
    study = Factories.build(:study)
    survey_tool = Factories.build(:survey_tool)
    merged = StudyEdit.create(study, survey_tool)

    assert StudyEdit.to_survey_tool(merged) == %{
             description: survey_tool.description,
             survey_url: survey_tool.survey_url,
             subject_count: survey_tool.subject_count,
             duration: survey_tool.duration,
             phone_enabled: survey_tool.phone_enabled,
             tablet_enabled: survey_tool.tablet_enabled,
             desktop_enabled: survey_tool.desktop_enabled,
             published_at: survey_tool.published_at,
             image_url: survey_tool.image_url,
             marks: survey_tool.marks,
             reward_currency: survey_tool.reward_currency,
             reward_value: survey_tool.reward_value,
             themes: survey_tool.themes
           }
  end

  test "the changeset requires the title to be filled" do
    study = Factories.build(:study)
    survey_tool = Factories.build(:survey_tool)
    merged = StudyEdit.create(study, survey_tool)
    changeset = StudyEdit.changeset(merged, %{title: ""})

    assert changeset.errors == [title: {"can't be blank", [validation: :required]}]
  end
end
