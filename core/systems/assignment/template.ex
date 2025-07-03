defprotocol Systems.Assignment.Template do
  alias Systems.Assignment.Template

  @type title :: binary()
  @type tabs :: [
          settings: {title(), Template.Flags.Settings.t()} | nil,
          import: {title(), Template.Flags.Import.t()} | nil,
          criteria: {title(), Template.Flags.Criteria.t()} | nil,
          participants: {title(), Template.Flags.Participants.t()} | nil,
          affiliate: {title(), Template.Flags.Affiliate.t()} | nil,
          workflow: {title(), Template.Flags.Workflow.t()} | nil,
          monitor: {binary(), Template.Flags.Monitor.t()} | nil
        ]

  @spec title(t) :: binary()
  def title(t)

  @spec tabs(t) :: tabs()
  def tabs(t)

  @spec workflow_config(t) :: Systems.Workflow.Config.t()
  def workflow_config(t)
end

defmodule Systems.Assignment.Template.Flags do
  @moduledoc """
  A macro for creating flag structs that control feature availability.

  This module provides a macro that generates flag structs with opt-in behavior:
  - By default, all flags are disabled (false)
  - Use `opt_in: [list_of_flags]` to enable specific flags
  - `opt_out` is deprecated but still supported with warnings

  ## Usage

      defmodule MyFlags do
        use Systems.Assignment.Template.Flags, [:feature_a, :feature_b, :feature_c]
      end

      # Create with all flags disabled (default)
      flags = MyFlags.new()

      # Create with specific flags enabled
      flags = MyFlags.new(opt_in: [:feature_a, :feature_c])
  """

  defmacro __using__(list_of_available_flags) do
    quote do
      @available_flags unquote(list_of_available_flags)

      @typedoc """
      A struct containing boolean flags for controlling feature availability.
      Each flag can be true (enabled) or false (disabled).
      """
      @type t :: %__MODULE__{
              unquote_splicing(
                for flag_name <- list_of_available_flags do
                  {flag_name, {:boolean, [], []}}
                end
              )
            }

      defstruct unquote(list_of_available_flags)

      @doc """
      Returns the complete list of available flags for this module.
      Useful for introspection and validation.
      """
      @spec flags() :: [atom()]
      def flags, do: @available_flags

      @doc """
      Creates a new flags struct with specified options.

      ## Options

      * `:opt_in` - List of flags to enable (recommended)
      * `:opt_out` - List of flags to disable (deprecated)

      ## Examples

          iex> #{inspect(__MODULE__)}.new(opt_in: [:flag1, :flag2])
          %#{inspect(__MODULE__)}{flag1: true, flag2: true, ...}

          iex> #{inspect(__MODULE__)}.new()
          %#{inspect(__MODULE__)}{flag1: false, flag2: false, ...}
      """
      @spec new(keyword()) :: t()
      def new(options_list \\ []) do
        # Check for deprecated opt_out usage and warn user
        _warn_if_using_deprecated_opt_out(options_list)
        # Determine which approach to use based on provided options
        cond do
          _has_opt_in_option?(options_list) ->
            _create_struct_with_opt_in_flags(options_list, unquote(list_of_available_flags))

          _has_opt_out_option?(options_list) ->
            _create_struct_with_opt_out_flags(options_list, unquote(list_of_available_flags))

          true ->
            _create_struct_with_all_flags_disabled(unquote(list_of_available_flags))
        end
      end

      # Private helper functions for better readability

      defp _warn_if_using_deprecated_opt_out(options_list) do
        if Keyword.has_key?(options_list, :opt_out) do
          IO.warn(":opt_out is deprecated for #{inspect(__MODULE__)}; use :opt_in instead.")
        end
      end

      defp _has_opt_in_option?(options_list) do
        Keyword.has_key?(options_list, :opt_in)
      end

      defp _has_opt_out_option?(options_list) do
        Keyword.has_key?(options_list, :opt_out)
      end

      defp _create_struct_with_opt_in_flags(options_list, all_available_flags) do
        flags_to_enable = Keyword.get(options_list, :opt_in, [])
        enabled_flags_set = MapSet.new(flags_to_enable)

        flags_with_boolean_values =
          all_available_flags
          |> Enum.map(fn flag_name ->
            is_flag_enabled = MapSet.member?(enabled_flags_set, flag_name)
            {flag_name, is_flag_enabled}
          end)
          |> Enum.into(%{})

        struct(__MODULE__, flags_with_boolean_values)
      end

      defp _create_struct_with_opt_out_flags(options_list, all_available_flags) do
        flags_to_disable = Keyword.get(options_list, :opt_out, [])
        disabled_flags_set = MapSet.new(flags_to_disable)

        flags_with_boolean_values =
          all_available_flags
          |> Enum.map(fn flag_name ->
            is_flag_disabled = MapSet.member?(disabled_flags_set, flag_name)
            is_flag_enabled = not is_flag_disabled
            {flag_name, is_flag_enabled}
          end)
          |> Enum.into(%{})

        struct(__MODULE__, flags_with_boolean_values)
      end

      defp _create_struct_with_all_flags_disabled(all_available_flags) do
        # Default behavior: all flags start as false (opt-in approach)
        flags_with_boolean_values =
          all_available_flags
          |> Enum.map(fn flag_name -> {flag_name, false} end)
          |> Enum.into(%{})

        struct(__MODULE__, flags_with_boolean_values)
      end

      # Implement Access behavior for backward compatibility with flags[:key] syntax
      @behaviour Access

      @doc """
      Access.fetch/2 implementation - retrieves a flag value by key.
      Returns {:ok, value} if key exists, :error otherwise.
      """
      @impl Access
      def fetch(flags_struct, flag_key) do
        Map.fetch(flags_struct, flag_key)
      end

      @doc """
      Access.get_and_update/3 implementation - gets current value and updates it.
      Allows pattern: get_and_update(flags, :flag_name, fn current -> {current, new_value} end)
      """
      @impl Access
      def get_and_update(flags_struct, flag_key, update_function) do
        Map.get_and_update(flags_struct, flag_key, update_function)
      end

      @doc """
      Access.pop/3 implementation - removes a key and returns {value, new_struct}.
      Allows pattern: {value, new_flags} = pop(flags, :flag_name, default_value)
      """
      @impl Access
      def pop(flags_struct, flag_key, default_value_if_missing \\ nil) do
        Map.pop(flags_struct, flag_key, default_value_if_missing)
      end
    end
  end
end

defmodule Systems.Assignment.Template.Flags.Settings do
  @moduledoc """
  Feature flags for controlling template settings functionality.

  Available flags:
  - `:branding` - Show custom branding settings
  - `:information` - Show information/description fields
  - `:privacy` - Show privacy policy settings
  - `:consent` - Show consent form configuration
  - `:helpdesk` - Show helpdesk/support contact options
  - `:affiliate` - Show affiliate/partner settings
  """
  use Systems.Assignment.Template.Flags, [
    :branding,
    :information,
    :privacy,
    :consent,
    :helpdesk,
    :affiliate
  ]
end

defmodule Systems.Assignment.Template.Flags.Participants do
  @moduledoc """
  Feature flags for controlling participant management functionality.

  Available flags:
  - `:expected` - Show expected completion time/duration
  - `:language` - Show language selection options
  - `:advert_in_pool` - Allow advertising in participant pool
  - `:invite_participants` - Enable participant invitation features
  - `:affiliate` - Show affiliate/partner participant options
  """
  use Systems.Assignment.Template.Flags, [
    :expected,
    :language,
    :advert_in_pool,
    :invite_participants,
    :affiliate
  ]
end

defmodule Systems.Assignment.Template.Flags.Import do
  @moduledoc """
  Feature flags for controlling data import functionality.
  Currently has no flags defined.
  """
  use Systems.Assignment.Template.Flags, []
end

defmodule Systems.Assignment.Template.Flags.Criteria do
  @moduledoc """
  Feature flags for controlling participant criteria functionality.
  Currently has no flags defined.
  """
  use Systems.Assignment.Template.Flags, []
end

defmodule Systems.Assignment.Template.Flags.Workflow do
  @moduledoc """
  Feature flags for controlling workflow functionality.

  Available flags:
  - `:library` - Enable workflow library features
  """
  use Systems.Assignment.Template.Flags, [:library]
end

defmodule Systems.Assignment.Template.Flags.Affiliate do
  @moduledoc """
  Feature flags for controlling affiliate/partner functionality.
  Currently has no flags defined.
  """
  use Systems.Assignment.Template.Flags, []
end

defmodule Systems.Assignment.Template.Flags.Monitor do
  @moduledoc """
  Feature flags for controlling monitoring and tracking functionality.

  Available flags:
  - `:consent` - Enable consent tracking and monitoring
  """
  use Systems.Assignment.Template.Flags, [:consent]
end
