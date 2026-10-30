defmodule Systems.Assignment.TemplateExtension do
  @moduledoc """
  An assignment template that a SaaS adds next to the built-in
  `Systems.Assignment.Templates`.

  A SaaS registers its templates in config:

      config :mica, :assignment_templates, [MySaaS.SomeTemplate]

  Each module defines the template struct (`defstruct [:id]`), implements
  `Systems.Assignment.Template` for it and implements this behaviour.
  """

  alias Systems.Assignment

  @doc "The template id, stored as the assignment's `special`."
  @callback id() :: atom()

  @doc "Whether researchers can create new assignments from this template."
  @callback enabled?() :: boolean()

  @doc """
  Start screen description of a task with this workflow item special, or nil
  to keep the tool's default.
  """
  @callback tool_description(special :: atom()) :: binary() | nil

  def all, do: Mica.Env.get(:assignment_templates, [])

  def enabled, do: Enum.filter(all(), & &1.enabled?())

  def get(id), do: Enum.find(all(), &(&1.id() == id))

  def template!(id) do
    case get(id) do
      nil -> raise ArgumentError, "Unknown assignment template: #{inspect(id)}"
      module -> struct!(module, id: id)
    end
  end

  def title(id), do: id |> template!() |> Assignment.Template.title()

  def tool_description(special) do
    Enum.find_value(all(), & &1.tool_description(special))
  end
end
