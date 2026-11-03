defmodule Mica.Repo.Migrations.RenameStoredModuleNames do
  @moduledoc """
  Nova step code-rename renamed modules whose names are stored:
    * `oban_jobs.worker`: the worker of jobs that have not run yet (such as
      Next's Paper RIS import jobs and the Announcement delivery job);
    * `authentication_entity.identifier`: `Elixir.<module>:<id>`, such as the system
      actors' `Elixir.Core.Authentication.Actor:<id>`;
    * `next_actions.action`: `Elixir.<module>` of the next action, such as
      `Elixir.Systems.Announcement.NextActions.ReadAnnouncement`.

  The last migration of the rename's release, so every table it rewrites exists.
  This file names the old modules on purpose: scripts/rename_mica.exs skips it.
  """
  use Ecto.Migration

  # Next's systems, as in scripts/rename_mica.exs (`@next_systems`).
  @next_systems ~w(Annotation Announcement Citizen Graphite Ontology Onyx Paper Probe Student Zircon)
  # Next's bundle systems, as in scripts/rename_mica.exs (`@next_bundle_systems`).
  @next_bundle_systems ~w(Account E2E Panl WellKnown)

  # {old, new} module name prefixes, specific before general.
  @renames [{"CoreWeb.", "MicaWeb."}, {"Core.", "Mica."}] ++
             Enum.map(@next_systems, &{"Systems.#{&1}.", "Next.Systems.#{&1}."}) ++
             Enum.map(@next_bundle_systems, &{"Next.#{&1}.", "Next.Systems.#{&1}."}) ++
             [
               {"Next.Layouts.", "NextWeb.Layouts."},
               {"Next.Menu.", "NextWeb.Menu."},
               {"Frameworks.E2E.", "Next.Frameworks.E2E."},
               {"Frameworks.Concept.ScreeningAgent", "Next.Frameworks.Concept.ScreeningAgent"},
               {"Self.Account.", "MicaSaas.Systems.Account."},
               {"Self.Layouts.", "MicaSaasWeb.Layouts."},
               {"Self.Menu.", "MicaSaasWeb.Menu."},
               {"Self.", "MicaSaas."}
             ]

  # {table, column, prefix of the stored module name, only rows matching this SQL}
  @columns [
    {"oban_jobs", "worker", "", "state NOT IN ('completed', 'discarded', 'cancelled')"},
    {"authentication_entity", "identifier", "Elixir.", "TRUE"},
    {"next_actions", "action", "Elixir.", "TRUE"}
  ]

  def renames, do: @renames

  def up, do: Enum.each(@renames, &rename/1)

  def down, do: Enum.each(@renames, fn {old, new} -> rename({new, old}) end)

  defp rename({from, to}) do
    for {table, column, prefix, where} <- @columns do
      from = prefix <> from
      to = prefix <> to

      execute("""
      UPDATE #{table}
      SET #{column} = '#{to}' || substr(#{column}, #{String.length(from) + 1})
      WHERE starts_with(#{column}, '#{from}') AND #{where}
      """)
    end
  end
end
