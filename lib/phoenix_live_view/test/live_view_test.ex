defmodule Phoenix.LiveViewTest do
  @moduledoc """
  TODO

  - timeouts
  """

  alias Phoenix.LiveViewTest.{View, ClientProxy}

  def instrument(:phoenix_controller_render, _, _, func), do: func.()
  def config(:live_view), do: [signing_salt: "11234567821234567831234567841234"]
  def config(:secret_key_base), do: "5678567899556789656789756789856789956789"
  @doc false
  def encode!(msg), do: msg

  def mount_disconnected(view_module, opts) do
    ref = make_ref()
    timeout = opts[:timeout] || 5000
    endpoint = __MODULE__
    live_opts = [
      session: opts[:session] || %{},
      caller: opts[:caller] || {ref, self()},
    ]

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_private(:phoenix_endpoint, endpoint)
      |> Phoenix.LiveView.live_render(view_module, live_opts)

    html = Phoenix.ConnTest.html_response(conn, 200)
    receive do
      {^ref, {:mount_disconnected, token}} ->
        {:ok, View.build(ref: ref, token: token, module: view_module, endpoint: endpoint), html}
    after timeout ->
      {:error, :timeout}
    end
  end

  def mount(view, opts \\ [])

  def mount(view_module, opts) when is_atom(view_module) do
    with {:ok, view, _html} <- mount_disconnected(view_module, opts) do
      mount(view, opts)
    end
  end

  def mount(%View{ref: ref, topic: topic} = view, opts) do
    if View.connected?(view), do: raise ArgumentError, "view is already connected"
    timeout = opts[:timeout] || 5000

    case ClientProxy.start_link(caller: {ref, self()}, view: view, timeout: timeout) do
      {:ok, proxy_pid} ->
        receive do
          {^ref, :mounted, view_pid, html} ->
            view = %View{view | pid: view_pid, proxy: proxy_pid, topic: topic}
            {:ok, view, html}
        end

      :ignore ->
        receive do
          {^ref, reason} -> {:error, reason}
        end
    end
  end

  def render_click(view, event, value \\ %{}) do
    render_event(view, :click, event, value)
  end
  def render_event(view, type, event, value) do
    {:ok, html} = GenServer.call(view.proxy, {:render_event, view, type, event, value})
    html
  end

  # todo kill this
  def assert_receive_mount(%View{ref: ref} = view, child_module, opts \\ []) do
    timeout = opts[:timeout] || 5000

    receive do
      {^ref, {:nested_mount, ^child_module, token}} ->
        nested_view = View.build(ref: ref, token: token, module: child_module, endpoint: view.endpoint)
        mount(nested_view)
    after timeout ->
      {:error, :timeout}
    end
  end


  def children(%View{} = parent) do
    GenServer.call(parent.proxy, {:children, parent})
  end

  def render(%View{} = view) do
    {:ok, html} = GenServer.call(view.proxy, {:render_tree, view})
    html
  end
end