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
      email: "aishwariyasrinagesh@gmail.com",
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
