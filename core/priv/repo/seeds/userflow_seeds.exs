# Script for populating the userflow system with test data.
# Run it with: mix run priv/repo/seeds/userflow_seeds.exs

alias Core.Repo
alias Systems.Userflow
alias Systems.Account.User

# Example: Onboarding Flow
{:ok, onboarding} = Systems.Userflow.Public.create("onboarding", "User Onboarding")

# Add steps grouped by section
{:ok, _} = Systems.Userflow.Public.add_step(onboarding, "welcome", 1, "introduction")
{:ok, _} = Systems.Userflow.Public.add_step(onboarding, "profile", 2, "introduction")

{:ok, _} = Systems.Userflow.Public.add_step(onboarding, "privacy_policy", 3, "legal")
{:ok, _} = Systems.Userflow.Public.add_step(onboarding, "terms", 4, "legal")

{:ok, _} = Systems.Userflow.Public.add_step(onboarding, "interests", 5, "preferences")
{:ok, _} = Systems.Userflow.Public.add_step(onboarding, "notifications", 6, "preferences")

# Example: Project Setup Flow
{:ok, project_setup} = Systems.Userflow.Public.create("project_setup", "New Project Setup")

# Add steps grouped by section
{:ok, _} = Systems.Userflow.Public.add_step(project_setup, "project_info", 1, "basics")
{:ok, _} = Systems.Userflow.Public.add_step(project_setup, "team_members", 2, "basics")

{:ok, _} = Systems.Userflow.Public.add_step(project_setup, "milestones", 3, "planning")
{:ok, _} = Systems.Userflow.Public.add_step(project_setup, "timeline", 4, "planning")

{:ok, _} = Systems.Userflow.Public.add_step(project_setup, "budget", 5, "resources")
{:ok, _} = Systems.Userflow.Public.add_step(project_setup, "tools", 6, "resources")

# Example: Survey Creation Flow
{:ok, survey_setup} = Systems.Userflow.Public.create("survey_setup", "Survey Creation")

# Add steps grouped by section
{:ok, _} = Systems.Userflow.Public.add_step(survey_setup, "survey_type", 1, "setup")
{:ok, _} = Systems.Userflow.Public.add_step(survey_setup, "target_audience", 2, "setup")

{:ok, _} = Systems.Userflow.Public.add_step(survey_setup, "questions", 3, "content")
{:ok, _} = Systems.Userflow.Public.add_step(survey_setup, "responses", 4, "content")

{:ok, _} = Systems.Userflow.Public.add_step(survey_setup, "preview", 5, "review")
{:ok, _} = Systems.Userflow.Public.add_step(survey_setup, "publish", 6, "review")

# Example: Mark some steps as visited for a test user
case Repo.get_by(User, email: "test@example.com") do
  nil ->
    IO.puts("No test user found. Skipping progress creation.")

  user ->
    # Mark first two steps of onboarding as visited
    onboarding = Systems.Userflow.Public.get!("onboarding")
    [step1, step2 | _] = onboarding.steps

    Systems.Userflow.Public.mark_visited(user.id, step1.id)
    Systems.Userflow.Public.mark_visited(user.id, step2.id)

    IO.puts("Created test progress for user #{user.email}")
end
