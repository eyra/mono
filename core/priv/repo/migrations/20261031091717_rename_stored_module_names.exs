defmodule Mica.Repo.Migrations.RenameStoredModuleNames do
  @moduledoc """
  Nova step code-rename renamed modules whose names are stored: the worker of
  Oban jobs that have not run yet (Next's Paper RIS import jobs), and the
  identifier of authentication entities (`Elixir.<module>:<id>`, such as the
  system actors' `Elixir.Core.Authentication.Actor:<id>`).

  This file names the old modules on purpose: scripts/rename_mica.exs skips it.
  """
  use Ecto.Migration

  # {old, new} module name prefixes, specific before general.
  @renames [
    {"CoreWeb.", "MicaWeb."},
    {"Core.", "Mica."},
    {"Systems.Annotation.", "Next.Systems.Annotation."},
    {"Systems.Citizen.", "Next.Systems.Citizen."},
    {"Systems.Graphite.", "Next.Systems.Graphite."},
    {"Systems.Ontology.", "Next.Systems.Ontology."},
    {"Systems.Onyx.", "Next.Systems.Onyx."},
    {"Systems.Paper.", "Next.Systems.Paper."},
    {"Systems.Probe.", "Next.Systems.Probe."},
    {"Systems.Student.", "Next.Systems.Student."},
    {"Systems.Zircon.", "Next.Systems.Zircon."},
    {"Next.Account.", "Next.Systems.Account."},
    {"Next.E2E.", "Next.Systems.E2E."},
    {"Next.Panl.", "Next.Systems.Panl."},
    {"Next.WellKnown.", "Next.Systems.WellKnown."},
    {"Next.Layouts.", "NextWeb.Layouts."},
    {"Next.Menu.", "NextWeb.Menu."},
    {"Frameworks.E2E.Controller", "Next.Frameworks.E2E.Controller"},
    {"Frameworks.Concept.ScreeningAgent", "Next.Frameworks.Concept.ScreeningAgent"},
    {"Self.Account.", "MicaSaas.Systems.Account."},
    {"Self.Layouts.", "MicaSaasWeb.Layouts."},
    {"Self.Menu.", "MicaSaasWeb.Menu."},
    {"Self.", "MicaSaas."}
  ]

  def up, do: Enum.each(@renames, &rename/1)

  def down, do: Enum.each(@renames, fn {old, new} -> rename({new, old}) end)

  defp rename({from, to}) do
    execute("""
    UPDATE oban_jobs
    SET worker = '#{to}' || substr(worker, #{String.length(from) + 1})
    WHERE starts_with(worker, '#{from}')
      AND state NOT IN ('completed', 'discarded', 'cancelled')
    """)

    execute("""
    UPDATE authentication_entity
    SET identifier = 'Elixir.#{to}' || substr(identifier, #{String.length("Elixir." <> from) + 1})
    WHERE starts_with(identifier, 'Elixir.#{from}')
    """)
  end
end
