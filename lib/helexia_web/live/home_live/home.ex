defmodule HelexiaWeb.HomeLive.Home do
  use HelexiaWeb, :live_view

  def mount(_params, _session, socket) do
    assigns = [
      locations: [
        %{
          lat: -4.1006,
          lng: 39.6619,
          status: "active",
          name: "Likoni Pilot Hub",
          type: "Primary Pilot Zone"
        },
        %{
          lat: -4.0435,
          lng: 39.6682,
          status: "planned",
          type: "Expansion Zone",
          name: "Mombasa Island Hub"
        },
        %{
          lat: -4.0218,
          lng: 39.7201,
          status: "planned",
          name: "Nyali Care Node",
          type: "Clinic Network Zone"
        }
      ],
      patient_modules: patient_modules()
    ]

    {:ok, assign(socket, assigns)}
  end

  def patient_modules() do
    [
      {
        "Patient Care",
        "user-circle",
        "Digital patient records, appointments and connected care.",
        "https://images.unsplash.com/photo-1576091160550-2173dba999ef?q=80&w=1200&auto=format&fit=crop"
      },
      {
        "Pharma Care",
        "beaker",
        "Medicine access, prescriptions and pharmacy workflows.",
        "https://images.unsplash.com/photo-1587854692152-cbe660dbde88?q=80&w=1200&auto=format&fit=crop"
      },
      {
        "Lab Connect",
        "clipboard-document-check",
        "Laboratory diagnostics and real-time result delivery.",
        "https://images.unsplash.com/photo-1579154204601-01588f351e67?q=80&w=1200&auto=format&fit=crop"
      },
      {
        "Medi Pay",
        "credit-card",
        "Insurance claims, billing and healthcare payments.",
        "https://images.unsplash.com/photo-1556740749-887f6717d7e4?q=80&w=1200&auto=format&fit=crop"
      },
      {
        "AI Triage",
        "cpu-chip",
        "AI-powered patient risk analysis and care guidance.",
        "https://images.unsplash.com/photo-1677442136019-21780ecad995?q=80&w=1200&auto=format&fit=crop"
      },
      {
        "Remote Care",
        "globe-alt",
        "Connected healthcare access for remote communities.",
        "https://images.unsplash.com/photo-1526256262350-7da7584cf5eb?q=80&w=1200&auto=format&fit=crop"
      },
      {
        "Emergency",
        "bolt",
        "Rapid emergency coordination and critical response.",
        "https://images.unsplash.com/photo-1587745416684-47953f16f02f?q=80&w=1200&auto=format&fit=crop"
      },
      {
        "Health Analytics",
        "chart-bar",
        "Population health insights and predictive intelligence.",
        "https://images.unsplash.com/photo-1551288049-bebda4e38f71?q=80&w=1200&auto=format&fit=crop"
      }
    ]
  end
end
