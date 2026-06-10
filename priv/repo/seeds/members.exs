defmodule Helexia.Seeds.Members do
  alias Helexia.Members.Member

  @data [
    %{
      level: 1,
      display_order: 1,
      status: "active",
      name: "Moses Ondicho",
      image_url: "/images/ceo0.png",
      email: "moses@sensspectra.com",
      title: "President & Co-Founder",
      expertise: ["Strategy", "Governance", "Fintech"]
    },
    %{
      level: 1,
      status: "active",
      display_order: 2,
      name: "Aishwariya Srinagesh",
      image_url: "/images/ceo1.png",
      email: "aishwariya@iappsafrica.com",
      title: "Chief Executive Officer & Co-Founder",
      expertise: ["Operations", "Management", "Solutions Expert"]
    },
    %{
      level: 2,
      status: "active",
      display_order: 3,
      title: "Group CTO",
      name: "Erik Rind ",
      email: "erikrind@gmil.com",
      image_url: "/images/cto.png",
      expertise: ["litigation", "conveyancing", "arbitration proceedings"]
    },
    %{
      level: 2,
      status: "active",
      display_order: 4,
      name: "Titus Njihigu",
      email: "titusnjihigu@gmil.com",
      image_url: "/images/uat_cs.png",
      expertise: ["Health", "Clinics"],
      title: "UAT & Clinical Systems QA"
    },
    %{
      level: 2,
      status: "active",
      display_order: 5,
      name: "Mercy Nasimiyu",
      email: "mercynasimiyu@gmil.com",
      image_url: "/images/co_nas.png",
      expertise: ["Nursing", "Health", "Patient Care"],
      title: "Clinical Operations & Nursing Adoption Support"
    },
    %{
      level: 3,
      status: "active",
      display_order: 6,
      name: "Peter Pushparaj",
      email: "peter@ainexus.com",
      title: "Advisory & Operations",
      image_url: "/images/advisor.png",
      expertise: ["Advisory", "Operations"]
    },
        %{
      level: 3,
      status: "active",
      display_order: 6,
      name: "Christopher Southgate",
      title: "Chief Commercial Officer",
      image_url: "/images/christopher.png",
      email: "christophersouthgate@ainexus.com",
      expertise: [" Commercial Partnerships", "Structural Frameworks"]
    }
  ]

  def run() do
    @data
    |> Enum.map(
      &Member.create(%Member{}, &1,
        on_conflict: {:replace_all_except, [:id]},
        conflict_target: [:email],
        returning: true
      )
    )
  end
end

require Logger

Helexia.Seeds.Members.run()
|> Enum.each(fn
  {:ok, member} -> Logger.info("[Seeds] for #{member.name} Helexia Member Seeded Successfully")
  {:error, _} -> Logger.error("[Seeds] Failed to seed Member")
end)
