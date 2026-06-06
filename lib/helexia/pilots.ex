defmodule Helexia.Pilots do
  @pilots [
    %{
      status: "active",
      slug: "likoni_mombasa",
      name: "Likoni, Mombasa",
      title: "Launching HELEXIA+ from Likoni, Mombasa",
      subtitle:
        "The HELEXIA+ pilot begins in Likoni as a practical healthcare intelligence deployment focused on connecting patients, healthcare workers, facilities, pharmacies, labs, and care programs into one coordinated digital health network.",
      location: %{
        country: "Kenya",
        county: "Mombasa",
        area: "Likoni Sub-County",
        map_url: "https://www.google.com/maps?q=Likoni,Mombasa,Kenya"
      },
      media: %{
        type: :video,
        src: "/videos/globe.mp4",
        fallback: "/images/globe.jpeg"
      },
      metrics: [
        %{
          tone: "sky",
          value: "305,000",
          icon: "hero-users",
          label: "Population Reached"
        },
        %{
          tone: "cyan",
          value: "600+",
          icon: "hero-briefcase",
          label: "Healthcare Workers"
        },
        %{
          tone: "emerald",
          icon: "hero-heart",
          value: "NCDs & MNCH",
          label: "Initial Care Segments"
        }
      ],
      care_segments: [
        %{
          name: "NCDs",
          tag: "Priority 01",
          description:
            "Supporting screening, continuity of care, patient follow-ups, and long-term condition management for non-communicable diseases."
        },
        %{
          name: "MNCH",
          tag: "Priority 02",
          description:
            "Improving maternal, newborn, and child health workflows through access, reminders, referrals, and community care support."
        },
        %{
          tag: "System Layer",
          name: "Connected Facility Operations",
          description:
            "Creating a shared operating layer for clinics, labs, pharmacies, and care teams participating in the pilot network."
        }
      ],
      objectives: [
        %{
          number: "01",
          title: "Patient Access",
          description:
            "Improve how patients discover, reach, and interact with healthcare services within the pilot zone."
        },
        %{
          number: "02",
          title: "Care Coordination",
          description:
            "Support referrals, follow-ups, and communication between healthcare facilities and care teams."
        },
        %{
          number: "03",
          title: "Worker Enablement",
          description:
            "Equip healthcare workers with practical digital tools for field and facility-based workflows."
        },
        %{
          number: "04",
          title: "Health Intelligence",
          description:
            "Generate insights that help identify demand, service gaps, program performance, and expansion opportunities."
        }
      ],
      events: [
        %{
          date: "2025-01-15",
          category: "Planning",
          title: "Pilot Planning & Local Mapping",
          description:
            "Initial mapping of care actors, patient access points, and priority workflows in Likoni."
        },
        %{
          date: "2025-02-10",
          category: "Engagement",
          title: "Healthcare Worker Engagement",
          description:
            "Engagement with healthcare workers and facility-level actors to validate workflow requirements."
        },
        %{
          date: "2025-03-01",
          category: "Implementation",
          title: "Digital Workflow Readiness",
          description:
            "Preparation of pilot workflows for patient access, referrals, care follow-ups, and reporting."
        }
      ],
      milestones: [
        %{
          step: "1",
          title: "Launch in Likoni",
          description:
            "Begin with the first active pilot location, establish local workflows, and onboard initial participating healthcare actors."
        },
        %{
          step: "2",
          title: "Validate care workflows",
          description:
            "Test patient access, healthcare worker tools, referrals, follow-ups, reporting, and care segment-specific workflows."
        },
        %{
          step: "3",
          title: "Measure intelligence signals",
          description:
            "Track service demand, engagement, access gaps, program performance, and operational readiness for wider deployment."
        },
        %{
          step: "4",
          title: "Expand across Mombasa",
          description:
            "Use validated pilot learnings to support expansion into additional communities, facilities, and care programs."
        }
      ]
    }
  ]

  def list_pilots, do: @pilots

  def get_pilot_by_slug!(slug), do: Enum.find(@pilots, &(&1.slug == slug))
end
