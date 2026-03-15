defmodule BackendWeb.ChatLive.SidebarTest do
  use BackendWeb.ConnCase

  import Backend.Factory
  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  setup %{user: user} do
    organisation = insert(:organisation)
    insert(:organisation_user, organisation: organisation, user: user)
    document = insert(:document, organisation: organisation)

    %{organisation: organisation, document: document}
  end

  defp open_sidebar(%{conn: conn, organisation: org, document: doc}) do
    {:ok, view, _html} =
      live(conn, ~p"/organisations/#{org.id}/documents/#{doc.id}")

    sidebar = find_live_child(view, "chat-sidebar")
    {view, sidebar}
  end

  describe "empty state" do
    test "shows empty state when no messages exist", ctx do
      {_view, sidebar} = open_sidebar(ctx)

      assert render(sidebar) =~ "Send a message to get started."
    end
  end

  describe "sending messages" do
    test "user message appears in the chat", ctx do
      {_view, sidebar} = open_sidebar(ctx)

      Req.Test.stub(:anthropic, fn conn ->
        Req.Test.json(conn, %{
          "content" => [%{"type" => "text", "text" => "Hi"}],
          "stop_reason" => "end_turn",
          "usage" => %{"input_tokens" => 10, "output_tokens" => 5}
        })
      end)

      sidebar
      |> element("form")
      |> render_submit(%{"content" => "Hello there"})

      html = render(sidebar)
      assert html =~ "Hello there"
      refute html =~ "Send a message to get started."
    end

    test "shows loading state while waiting for response", ctx do
      {_view, sidebar} = open_sidebar(ctx)

      # Stub that sleeps to keep the task in flight
      Req.Test.stub(:anthropic, fn conn ->
        Process.sleep(500)

        Req.Test.json(conn, %{
          "content" => [%{"type" => "text", "text" => "Hi"}],
          "stop_reason" => "end_turn",
          "usage" => %{"input_tokens" => 10, "output_tokens" => 5}
        })
      end)

      sidebar
      |> element("form")
      |> render_submit(%{"content" => "Hello"})

      # Immediately after submit, loading state should be visible
      html = render(sidebar)
      assert html =~ "Thinking..."
      assert html =~ "disabled"

      # After the task completes, loading state should clear
      assert_eventually(fn ->
        html = render(sidebar)
        html =~ "Hi" && not (html =~ "Thinking...")
      end)
    end

    test "displays Claude response after sending a message", ctx do
      {_view, sidebar} = open_sidebar(ctx)

      Req.Test.stub(:anthropic, fn conn ->
        Req.Test.json(conn, %{
          "content" => [%{"type" => "text", "text" => "Hello! How can I help?"}],
          "stop_reason" => "end_turn",
          "usage" => %{"input_tokens" => 10, "output_tokens" => 8}
        })
      end)

      sidebar
      |> element("form")
      |> render_submit(%{"content" => "Hi there"})

      assert_eventually(fn ->
        html = render(sidebar)
        html =~ "Hi there" && html =~ "Hello! How can I help?"
      end)
    end

    test "empty message does nothing", ctx do
      {_view, sidebar} = open_sidebar(ctx)

      sidebar
      |> element("form")
      |> render_submit(%{"content" => ""})

      assert render(sidebar) =~ "Send a message to get started."
    end
  end

  describe "error handling" do
    test "shows error when API call fails", ctx do
      {_view, sidebar} = open_sidebar(ctx)

      # Stub Anthropic to return an error
      Req.Test.stub(:anthropic, fn conn ->
        conn
        |> Plug.Conn.put_status(500)
        |> Req.Test.json(%{
          "error" => %{"type" => "api_error", "message" => "Internal server error"}
        })
      end)

      sidebar
      |> element("form")
      |> render_submit(%{"content" => "Hello"})

      # Wait for the async task to complete
      assert_eventually(fn ->
        html = render(sidebar)
        html =~ "Something went wrong"
      end)
    end

    test "clears error when sending a new message", ctx do
      {_view, sidebar} = open_sidebar(ctx)

      # First request fails
      Req.Test.stub(:anthropic, fn conn ->
        conn
        |> Plug.Conn.put_status(500)
        |> Req.Test.json(%{
          "error" => %{"type" => "api_error", "message" => "Internal server error"}
        })
      end)

      sidebar
      |> element("form")
      |> render_submit(%{"content" => "Hello"})

      assert_eventually(fn ->
        html = render(sidebar)
        html =~ "Something went wrong"
      end)

      # Second request succeeds — stub a good response
      Req.Test.stub(:anthropic, fn conn ->
        Req.Test.json(conn, %{
          "content" => [%{"type" => "text", "text" => "Hi there"}],
          "stop_reason" => "end_turn",
          "usage" => %{"input_tokens" => 10, "output_tokens" => 5}
        })
      end)

      sidebar
      |> element("form")
      |> render_submit(%{"content" => "Try again"})

      # Error should be cleared immediately on submit
      html = render(sidebar)
      refute html =~ "Something went wrong"
    end
  end

  defp assert_eventually(fun, timeout \\ 2000) do
    end_time = System.monotonic_time(:millisecond) + timeout

    do_assert_eventually(fun, end_time)
  end

  defp do_assert_eventually(fun, end_time) do
    if fun.() do
      :ok
    else
      if System.monotonic_time(:millisecond) > end_time do
        flunk("Condition was not met within timeout")
      else
        Process.sleep(50)
        do_assert_eventually(fun, end_time)
      end
    end
  end
end
