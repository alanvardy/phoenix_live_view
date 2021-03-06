defmodule Phoenix.LiveView.Router do
  @moduledoc """
  Provides LiveView routing for Phoenix routers.
  """

  @doc """
  Defines a LiveView route.

  ## Layout

  When a layout isn't explicitly set, a default layout is inferred similar to
  controller actions. For example, the layout for the router `MyAppWeb.Router`
  would be inferred as `MyAppWeb.LayoutView` and would use the `:app` template.

  ## Options

    * `:session` - the optional list of keys to pull out of the Plug
      connection session and into the LiveView session.
      For example, the following would copy Plug's session current
      user ID and the `remember_me` value into the LiveView session:

          [:user_id, :remember_me]

      This also accepts key/value entries which are mapped directly into the
      LiveView session.  This is useful for identifying which `live` macro was
      matched.

          [action: :index]

    * `:layout` - the optional tuple for specifying a layout to render the
      LiveView. Defaults to `{LayoutView, :app}` where LayoutView is relative to
      your application's namespace.

    * `:container` - the optional tuple for the HTML tag and DOM attributes to
      be used for the LiveView container. For example: `{:li, style: "color: blue;"}`.
      See `Phoenix.LiveView.live_render/3` for more information on examples.

    * `:as` - optionally configures the named helper. Defaults to `:live`.

  ## Examples

      defmodule MyApp.Router
        use Phoenix.Router
        import Phoenix.LiveView.Router

        scope "/", MyApp do
          pipe_through [:browser]

          live "/thermostat", ThermostatLive
          live "/clock", ClockLive, session: [:user_id]
          live "/dashboard", DashboardLive, layout: {MyApp.AlternativeView, "app.html"}
        end
      end

      iex> MyApp.Router.Helpers.live_path(MyApp.Endpoint, MyApp.ThermostatLive)
      "/thermostat"

  """
  defmacro live(path, live_view, opts \\ []) do
    quote bind_quoted: binding() do
      live_opts = Keyword.put(opts, :router, __MODULE__)

      Phoenix.Router.get(
        path,
        Phoenix.LiveView.Plug,
        Phoenix.Router.scoped_alias(__MODULE__, live_view),
        private: %{phoenix_live_view: Phoenix.LiveView.Plug.__live_opts__(live_opts)},
        as: opts[:as] || :live,
        alias: false
      )
    end
  end
end
