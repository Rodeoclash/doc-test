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

alias Backend.Repo
alias Backend.Organisations.Organisation
alias Backend.SectionTags.SectionTag
alias Backend.Documents.Document

organisation = Repo.insert!(%Organisation{name: "SuperAPI"})

Repo.insert!(%SectionTag{
  name: "4 Context of the Organization",
  description:
    "Understanding the organization and its context, the needs and expectations of interested parties, and determining the scope of the ISMS.",
  organisation_id: organisation.id
})

Repo.insert!(%SectionTag{
  name: "5 Leadership",
  description:
    "Top management leadership and commitment, establishing the information security policy, and assigning organizational roles, responsibilities and authorities.",
  organisation_id: organisation.id
})

Repo.insert!(%SectionTag{
  name: "6 Planning",
  description:
    "Actions to address risks and opportunities, information security risk assessment and risk treatment, and information security objectives and planning to achieve them.",
  organisation_id: organisation.id
})

Repo.insert!(%Document{
  name: "ISMS Plan",
  content: %{},
  organisation_id: organisation.id
})
