
export default helexia_map_hook = {
  mounted() {
    const locations = JSON.parse(this.el.dataset.locations || "[]")

    this.map = L.map(this.el, {
      zoomControl: false,
      scrollWheelZoom: false,
    }).setView([-4.1006, 39.6619], 14)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors",
    }).addTo(this.map)

    L.control.zoom({ position: "bottomright" }).addTo(this.map)

    const activeIcon = L.divIcon({
      className: "",
      html: `
        <div style="
          width:42px;height:42px;border-radius:999px;
          background:#7dd3fc;color:#061427;
          display:grid;place-items:center;
          font-weight:900;font-size:18px;
          box-shadow:0 0 35px rgba(125,211,252,.65);
          border:6px solid rgba(125,211,252,.18);
        ">+</div>
      `,
      iconSize: [42, 42],
      iconAnchor: [21, 21],
    })

    this.markers = L.markerClusterGroup()

    locations.forEach(loc => {
      const marker = L.marker([loc.lat, loc.lng], { icon: activeIcon })

      marker.bindPopup(`
        <strong>${loc.name}</strong><br/>
        HELEXIA+ Healthcare Network<br/>
        ${loc.type || "Pilot Zone"}<br/>
        Status: ${loc.status || "Active"}
      `)

      this.markers.addLayer(marker)
    })

    this.map.addLayer(this.markers)

    setTimeout(() => {
      this.map.invalidateSize()
    }, 200)

    window.updateHelexiaMap = (lat, lng, label) => {
      this.map.setView([lat, lng], 15)

      setTimeout(() => {
        this.map.invalidateSize()
      }, 100)

      L.popup()
        .setLatLng([lat, lng])
        .setContent(`<strong>${label}</strong><br/>Likoni, Mombasa`)
        .openOn(this.map)
    }
  },

  destroyed() {
    if (this.map) {
      this.map.remove()
    }
  },
}