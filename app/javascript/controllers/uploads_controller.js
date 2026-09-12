import { Controller } from "@hotwired/stimulus"

const FILLED = ["border-solid", "border-cyan-400"]
const EMPTY = ["border-dashed", "border-slate-700"]

// Adds upload zones up to a maximum, and shows the chosen filename in place
// of the hint once a file is picked.
export default class extends Controller {
  static targets = ["zones", "zone", "add", "title", "hint"]
  static values = { max: Number }

  connect() {
    this.syncAddButton()
  }

  add() {
    if (this.zoneTargets.length >= this.maxValue) return

    const blank = this.zoneTargets[0].cloneNode(true)
    blank.querySelector("input[type=file]").value = ""
    this.markEmpty(blank)

    this.zonesTarget.appendChild(blank)
    this.renumber()
    this.syncAddButton()
  }

  pick(event) {
    const zone = event.target.closest("[data-uploads-target~=zone]")
    const file = event.target.files[0]

    if (file) {
      zone.classList.remove(...EMPTY)
      zone.classList.add(...FILLED)
    } else {
      this.markEmpty(zone)
    }

    zone.querySelector("[data-uploads-target~=hint]").textContent =
      file ? file.name : "PDF — click or drop"
  }

  markEmpty(zone) {
    zone.classList.remove(...FILLED)
    zone.classList.add(...EMPTY)
    zone.querySelector("[data-uploads-target~=hint]").textContent = "PDF — click or drop"
  }

  renumber() {
    this.zoneTargets.forEach((zone, index) => {
      zone.querySelector("[data-uploads-target~=title]").textContent = `Quote ${index + 1}`
    })
  }

  syncAddButton() {
    this.addTarget.hidden = this.zoneTargets.length >= this.maxValue
  }
}
