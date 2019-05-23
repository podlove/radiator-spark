defmodule Radiator.Directory.Editor do
  @moduledoc """
  The Editor context for querying and modifying data as an authorized user.

  It is the single point of access for all actions requiring an authenticated user.
  """

  import Ecto.Query, warn: false
  import Radiator.Auth.Permission

  alias Radiator.Auth

  alias Radiator.Repo
  alias Radiator.Directory.{Network, Podcast, Episode}

  alias Radiator.Directory.Editor

  alias Radiator.Media

  @not_authorized {:error, :not_authorized}
  @not_found {:error, :not_found}

  @doc """
  Returns a list of networks the actor has at least `:readonly` permissions on.

  ## Examples

      iex> list_networks(me)
      [%Network{}, ...]

  """

  def list_networks(actor = %Auth.User{}) do
    query =
      from n in Network,
        join: p in "networks_perm",
        where: n.id == p.subject_id,
        where: p.user_id == ^actor.id,
        order_by: n.title

    query
    |> Repo.all()
  end

  @doc """
  Gets a single network.

  ## Examples

      iex> get_network(me, 123)
      %Network{}

      iex> get_network(unauthorized_me, 123)
      {:error, :not_authorized}

      iex> get_network(oblivious_me, 999_998)
      {:error, :not_found}

  """
  def get_network(actor = %Auth.User{}, id) do
    case Repo.get(Network, id) do
      nil ->
        @not_found

      network = %Network{} ->
        if has_permission(actor, network, :readonly) do
          network
        else
          @not_authorized
        end
    end
  end

  @doc """
  Creates a network.

  ## Examples

      iex> create_network(me, %{title: "My First Network"})
      {:ok, %Network{}}

      iex> create_network(me, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_network(actor = %Auth.User{}, attrs) do
    case Editor.Owner.create_network(actor, attrs) do
      {:ok, %{network: network}} -> {:ok, network}
      {:error, :network, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Creates a network.

  ## Examples

      iex> update_network(me, network, %{title: "Professionals United"})
      {:ok, %Network{}}

      iex> update_network(me, network, %{title: nil})
      {:error, %Ecto.Changeset{}}

      iex> update_network(me, readonly_network, %{title: "Hostile Takeover 1"})
      {:error, :not_authorized}
  """
  def update_network(actor = %Auth.User{}, network = %Network{}, attrs) do
    if has_permission(actor, network, :own) do
      Editor.Owner.update_network(network, attrs)
    else
      @not_authorized
    end
  end

  def create_podcast(actor = %Auth.User{}, network = %Network{}, attrs) do
    if has_permission(actor, network, :manage) do
      Editor.Manager.create_podcast(network, attrs)
    else
      @not_authorized
    end
  end

  def get_podcast!(actor = %Auth.User{}, id) do
    podcast = Repo.get!(Podcast, id)

    if has_permission(actor, podcast, :readonly) do
      podcast
    else
      @not_authorized
    end
  end

  @spec attach_audio_to_network(Network.t(), Media.AudioFile.t()) ::
          {:ok, Media.Attachment.t()} | {:error, Ecto.Changeset.t()}
  def attach_audio_to_network(network = %Network{}, audio = %Media.AudioFile{}) do
    network
    |> Ecto.build_assoc(:attachments, %{audio_id: audio.id})
    |> Media.Attachment.changeset(%{})
    |> Repo.insert_or_update()
  end

  @spec attach_audio_to_episode(Episode.t(), Media.AudioFile.t()) ::
          {:ok, Media.Attachment.t()} | {:error, Ecto.Changeset.t()}
  def attach_audio_to_episode(episode = %Episode{}, audio = %Media.AudioFile{}) do
    episode
    |> Ecto.build_assoc(:attachments, %{audio_id: audio.id})
    |> Media.Attachment.changeset(%{})
    |> Repo.insert_or_update()
  end

  @spec detach_all_audios_from_episode(Episode.t()) :: Episode.t()
  def detach_all_audios_from_episode(episode = %Episode{}) do
    Ecto.assoc(episode, :attachments) |> Repo.delete_all()
    episode
  end
end
