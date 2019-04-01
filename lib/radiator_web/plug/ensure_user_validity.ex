defmodule RadiatorWeb.Plug.EnsureUserValidity do
  alias RadiatorWeb.Router.Helpers, as: Routes

  import Phoenix.HTML.Link

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    case Guardian.Plug.current_resource(conn) do
      %Radiator.Auth.User{status: :active} ->
        conn

      %Radiator.Auth.User{status: :unverified} = user ->
        conn
        |> Phoenix.Controller.put_flash(
          :info,
          [
            "Account needs verification. (",
            link("resend verification email",
              to:
                Routes.login_path(
                  conn,
                  :resend_verification_mail,
                  Radiator.Auth.User.email_verification_request_token(user)
                )
            ),
            ")"
          ]
        )
        |> Phoenix.Controller.redirect(to: Routes.login_path(conn, :login_form))
        |> Plug.Conn.halt()

      %Radiator.Auth.User{status: :suspended} = user ->
        conn
        |> Phoenix.Controller.put_flash(:error, "Account #{user.name} is suspended.")
        |> Phoenix.Controller.redirect(to: Routes.login_path(conn, :login_form))
        |> Plug.Conn.halt()
    end
  end
end
