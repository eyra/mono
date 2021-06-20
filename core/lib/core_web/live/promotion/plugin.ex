defmodule CoreWeb.Promotion.Plugin do
  @moduledoc """
  Generic behaviour of a Tool
  """
  alias Core.Promotions.CallToAction
  alias Phoenix.Socket

  @type socket :: Socket.t()
  @type promotion :: binary
  @type event :: binary
  @type highlight :: %{title: binary, text: binary}
  @type info_result :: %{call_to_action: CallToAction.t(), highlights: list(highlight), devices: list(atom)}

  @type handle_event_result :: {:ok, socket} | {:error, binary}

  @doc """
  Delivers info to embed the tool on the public promotions page
  """
  @callback info(promotion, socket) :: info_result

  @doc """
  Handles event from call to action
  """

  @callback handle_event(promotion, event, socket) :: handle_event_result
end
