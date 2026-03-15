defmodule BackendWeb.Helpers.Markdown do
  @moduledoc false

  def to_html(markdown) when is_binary(markdown) do
    markdown
    |> Earmark.as_html!()
    |> Phoenix.HTML.raw()
  end

  def to_html(nil), do: Phoenix.HTML.raw("")
end
