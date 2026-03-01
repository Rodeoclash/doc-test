defmodule BackendWeb.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import BackendWeb.ChannelCase
      import Phoenix.ChannelTest

      @endpoint BackendWeb.Endpoint
    end
  end

  setup tags do
    Backend.DataCase.setup_sandbox(tags)
    :ok
  end
end
