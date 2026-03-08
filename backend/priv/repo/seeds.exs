# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Backend.Repo.insert!(%Backend.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Backend.Accounts
alias Backend.Accounts.User
alias Backend.Documents.Document
alias Backend.Organisations.Organisation
alias Backend.Repo

now = DateTime.truncate(DateTime.utc_now(), :second)
timestamps = %{inserted_at: now, updated_at: now}

organisation =
  %Organisation{id: 1, name: "SuperAPI"}
  |> Map.merge(timestamps)
  |> Repo.insert!(
    on_conflict: :replace_all,
    conflict_target: :id
  )

# Initial Lexical editor state — kept for reference. Once the Yjs integration is
# complete, the editor state will be derived from yjs_state instead.
_lexical_content = %{
  "root" => %{
    "children" => [
      %{
        "type" => "paragraph",
        "version" => 1,
        "direction" => nil,
        "format" => "",
        "indent" => 0,
        "textFormat" => 0,
        "textStyle" => "",
        "children" => [
          %{
            "type" => "text",
            "version" => 1,
            "detail" => 0,
            "format" => 0,
            "mode" => "normal",
            "style" => "",
            "text" => "SuperAPI is the "
          },
          %{
            "type" => "change-delete",
            "version" => 1,
            "changeId" => "change-1",
            "direction" => nil,
            "format" => "",
            "indent" => 0,
            "children" => [
              %{
                "type" => "text",
                "version" => 1,
                "detail" => 0,
                "format" => 0,
                "mode" => "normal",
                "style" => "",
                "text" => "primary"
              }
            ]
          },
          %{
            "type" => "change-insert",
            "version" => 1,
            "changeId" => "change-1",
            "direction" => nil,
            "format" => "",
            "indent" => 0,
            "children" => [
              %{
                "type" => "text",
                "version" => 1,
                "detail" => 0,
                "format" => 0,
                "mode" => "normal",
                "style" => "",
                "text" => "main"
              }
            ]
          },
          %{
            "type" => "text",
            "version" => 1,
            "detail" => 0,
            "format" => 0,
            "mode" => "normal",
            "style" => "",
            "text" => " operating company..."
          }
        ]
      },
      %{
        "type" => "paragraph",
        "version" => 1,
        "direction" => nil,
        "format" => "",
        "indent" => 0,
        "textFormat" => 0,
        "textStyle" => "",
        "children" => [
          %{
            "type" => "text",
            "version" => 1,
            "detail" => 0,
            "format" => 0,
            "mode" => "normal",
            "style" => "",
            "text" => "Some other content here"
          }
        ]
      }
    ],
    "direction" => nil,
    "format" => "",
    "indent" => 0,
    "type" => "root",
    "version" => 1
  }
}

%Document{id: 1, name: "ISMS Plan", organisation_id: organisation.id}
|> Map.merge(timestamps)
|> Repo.insert!(
  on_conflict: :replace_all,
  conflict_target: :id
)

# Create a test user for development with a password for convenience.
{:ok, test_user} =
  case Accounts.register_user(%{email: "test@example.com", organisation_id: organisation.id}) do
    {:ok, user} -> {:ok, user}
    {:error, _changeset} -> {:ok, Accounts.get_user_by_email("test@example.com")}
  end

Accounts.update_user_password(test_user, %{password: "abcd12345678"})

# Create the AI agent for the organisation
Repo.insert!(%User{email: "agent@system.local", type: :agent, organisation_id: organisation.id},
  on_conflict: :nothing,
  conflict_target: :email
)
