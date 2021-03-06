defmodule Phoenix.LiveViewTest.LayoutLive do
  use Phoenix.LiveView, layout: {Phoenix.LiveViewTest.LayoutView, "live.html"}

  def render(assigns), do: ~L|The value is: <%= @val %>|

  def mount(session, socket) do
    socket
    |> assign(val: 123)
    |> maybe_put_layout(session)
  end

  def handle_event("double", _, socket) do
    {:noreply, update(socket, :val, & &1 * 2)}
  end

  defp maybe_put_layout(socket, %{"live_layout" => {mod, template}}) do
    {:ok, socket, layout: {mod, template}}
  end

  defp maybe_put_layout(socket, _session), do: {:ok, socket}
end
