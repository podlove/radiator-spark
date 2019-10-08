defmodule RadiatorWeb.Api.AuthenticationController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Auth
  alias RadiatorWeb.Helpers.AuthHelpers
  alias RadiatorWeb.Helpers.EmailHelpers

  def create(conn, %{"name" => name, "password" => password}) do
    Auth.Register.get_user_by_credentials(name, password)
    |> case do
      nil ->
        send_resp(conn, 401, "Login failed")

      user ->
        token = Auth.Guardian.api_session_token(user)

        conn
        |> json(AuthHelpers.session_response(user, token))
    end
  end

  def create(conn, _) do
    send_resp(conn, 400, "Missing arguments")
  end

  def prolong(conn, _params) do
    user = current_user(conn)
    token = Auth.Guardian.api_session_token(user)

    conn
    |> json(AuthHelpers.session_response(user, token))
  end

  def signup(conn, params) do
    with name when is_binary(name) <- params["name"],
         email when is_binary(email) <- params["email"],
         password when is_binary(password) <- params["password"] do
      case EmailHelpers.singup_user(params) do
        {:ok, user} ->
          conn
          |> put_status(:created)
          |> json(%{
            user:
              Map.merge(
                Map.take(user.profile, [:display_name]),
                Map.take(user, [:name, :email])
              )
          })

        {:error, changeset} ->
          conn
          |> json(%{errors: RadiatorWeb.ChangesetView.translate_errors(changeset)})
      end
    else
      _ ->
        send_resp(conn, 400, "Missing arguments")
    end
  end
end
