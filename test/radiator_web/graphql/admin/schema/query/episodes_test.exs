defmodule RadiatorWeb.GraphQL.Admin.Schema.Query.EpisodesTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

  alias Radiator.Directory.Episode
  alias Radiator.Media

  @doc """
  Generate user and add auth token to connection.
  """
  def setup_user_and_conn(%{conn: conn}) do
    user = Radiator.TestEntries.user()

    [
      conn: Radiator.TestEntries.put_current_user(conn, user),
      user: user
    ]
  end

  setup :setup_user_and_conn

  @single_query """
  query ($id: ID!) {
    episode(id: $id) {
      id
      title
      enclosure {
        length
        type
        url
      }
      audio {
        chapters {
          image
          link
          start
          title
        }
      }
    }
  }
  """

  test "episode returns an episode", %{conn: conn, user: user} do
    podcast = insert(:podcast) |> owned_by(user)

    upload = %Plug.Upload{
      path: "test/fixtures/image.jpg",
      filename: "image.jpg"
    }

    audio = insert(:audio)

    {:ok, chapter} =
      Radiator.AudioMeta.create_chapter(audio, %{
        image: upload,
        link: "http://example.com",
        title: "An Example",
        start: 12345
      })

    image_url = Media.ChapterImage.url({chapter.image, chapter})

    episode =
      insert(:unpublished_episode,
        podcast: podcast,
        audio: audio
      )

    enclosure = Episode.enclosure(episode)

    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => episode.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "episode" => %{
                 "id" => Integer.to_string(episode.id),
                 "title" => episode.title,
                 "enclosure" => %{
                   "length" => enclosure.length,
                   "type" => enclosure.type,
                   "url" => enclosure.url
                 },
                 "audio" => %{
                   "chapters" => [
                     %{
                       "image" => image_url,
                       "link" => "http://example.com",
                       "title" => "An Example",
                       "start" => 12345
                     }
                   ]
                 }
               }
             }
           }
  end

  @single_guid_query """
  query ($guid: String!) {
    episode(guid: $guid) {
      id
      title
      guid
    }
  }
  """

  test "episode by guid returns an episode", %{conn: conn, user: user} do
    episode = insert(:published_episode, title: "Foo", guid: "guid-foo") |> owned_by(user)

    conn = get conn, "/api/graphql", query: @single_guid_query, variables: %{"guid" => "guid-foo"}

    assert json_response(conn, 200) == %{
             "data" => %{
               "episode" => %{
                 "id" => Integer.to_string(episode.id),
                 "title" => episode.title,
                 "guid" => "guid-foo"
               }
             }
           }
  end

  test "episode by guid returns an episode when non existent", %{conn: conn} do
    conn = get conn, "/api/graphql", query: @single_guid_query, variables: %{"guid" => "guid-foo"}

    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message =~ "not found"
  end

  test "episode by guid returns an episode when there is more than one episode with that guid", %{
    conn: conn,
    user: user
  } do
    _e1 = insert(:published_episode, title: "Foo 1", guid: "guid-foo") |> owned_by(user)
    _e2 = insert(:published_episode, title: "Foo 2", guid: "guid-foo") |> owned_by(user)
    conn = get conn, "/api/graphql", query: @single_guid_query, variables: %{"guid" => "guid-foo"}

    assert %{"errors" => [%{"message" => message}]} = json_response(conn, 200)
    assert message =~ "more than one"
  end

  @is_published_query """
  query ($id: ID!) {
    episode(id: $id) {
      id
      isPublished
    }
  }
  """

  describe "is_published" do
    test "is false for an unpublished episode", %{conn: conn, user: user} do
      episode = insert(:episode) |> owned_by(user)

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => episode.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "episode" => %{"id" => Integer.to_string(episode.id), "isPublished" => false}
               }
             }
    end

    test "is true for a published episode", %{conn: conn, user: user} do
      episode = insert(:episode, published_at: DateTime.utc_now()) |> owned_by(user)

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => episode.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "episode" => %{"id" => Integer.to_string(episode.id), "isPublished" => true}
               }
             }
    end

    test "is false for published_at dates in the future", %{conn: conn, user: user} do
      in_one_hour = DateTime.utc_now() |> DateTime.add(3600)
      episode = insert(:episode, published_at: in_one_hour) |> owned_by(user)

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => episode.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "episode" => %{"id" => Integer.to_string(episode.id), "isPublished" => false}
               }
             }
    end
  end

  @episodes_in_podcast_query """
  query ($podcast_id: ID!) {
    podcast(id: $podcast_id) {
      episodes {
        title
      }
    }
  }
  """

  test "episodes in podcast are ordered, latest first", %{conn: conn, user: user} do
    podcast = insert(:podcast) |> owned_by(user)
    timestamp = 1_500_000_000

    _ep1 =
      insert(:published_episode,
        title: "E001",
        published_at: DateTime.from_unix!(timestamp),
        podcast: podcast
      )

    _ep3 =
      insert(:published_episode,
        title: "E003",
        published_at: DateTime.from_unix!(timestamp + 20),
        podcast: podcast
      )

    _ep2 =
      insert(:published_episode,
        title: "E002",
        published_at: DateTime.from_unix!(timestamp + 10),
        podcast: podcast
      )

    conn =
      get conn, "/api/graphql",
        query: @episodes_in_podcast_query,
        variables: %{"podcast_id" => podcast.id}

    assert %{
             "data" => %{
               "podcast" => %{
                 "episodes" => [
                   %{"title" => "E003"},
                   %{"title" => "E002"},
                   %{"title" => "E001"}
                 ]
               }
             }
           } = json_response(conn, 200)
  end
end
