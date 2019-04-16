defmodule Radiator.Directory.EpisodePermission do
  use Ecto.Schema
  import Ecto.Changeset

  alias Radiator.Auth
  alias Radiator.Directory.Episode
  alias Radiator.Perm.Ecto.PermissionType

  schema "episodes_perm" do
    belongs_to :user, Auth.User
    belongs_to :episode, Episode
    field :permission, PermissionType, default: :readonly

    timestamps()
  end

  def changeset(perm, params) when is_map(params) do
    perm
    |> cast(params, [:permission])
    |> validate_required([:permission])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:episode_id)
  end
end
