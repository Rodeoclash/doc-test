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

alias Backend.Documents.Document
alias Backend.Organisations.Organisation
alias Backend.Repo
alias Backend.SectionTags.SectionTag

now = DateTime.utc_now() |> DateTime.truncate(:second)
timestamps = %{inserted_at: now, updated_at: now}

organisation =
  Repo.insert!(
    %Organisation{id: 1, name: "SuperAPI"} |> Map.merge(timestamps),
    on_conflict: :replace_all,
    conflict_target: :id
  )

Repo.insert!(
  %SectionTag{
    name: "4 Context of the Organization",
    description:
      "Understanding the organization and its context, the needs and expectations of interested parties, and determining the scope of the ISMS.",
    organisation_id: organisation.id
  },
  on_conflict: :nothing
)

Repo.insert!(
  %SectionTag{
    name: "5 Leadership",
    description:
      "Top management leadership and commitment, establishing the information security policy, and assigning organizational roles, responsibilities and authorities.",
    organisation_id: organisation.id
  },
  on_conflict: :nothing
)

Repo.insert!(
  %SectionTag{
    name: "6 Planning",
    description:
      "Actions to address risks and opportunities, information security risk assessment and risk treatment, and information security objectives and planning to achieve them.",
    organisation_id: organisation.id
  },
  on_conflict: :nothing
)

document_content = %{
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

Repo.insert!(
  %Document{id: 1, name: "ISMS Plan", content: document_content, organisation_id: organisation.id}
  |> Map.merge(timestamps),
  on_conflict: :replace_all,
  conflict_target: :id
)
