import { Controller } from "@hotwired/stimulus"

const FILLED = ["border-solid", "border-cyan-400"]
const EMPTY = ["border-dashed", "border-slate-700"]

// Adds and removes upload zones between a minimum and a maximum, and shows
// the chosen filename in place of the hint once a file is picked.
export default class extends Controller {
  static targets = ["zones", "zone", "add", "remove", "title", "hint"]
  static values = { max: Number, min: Number }

  connect() {
    this.syncAddCard()
    this.syncRemoveButtons()
  }

  add() {
    if (this.zoneTargets.length >= this.maxValue) return

    const blank = this.zoneTargets[0].cloneNode(true)
    blank.querySelector("input[type=file]").value = ""
    this.markEmpty(blank)

    this.zonesTarget.insertBefore(blank, this.addTarget)
    this.renumber()
    this.syncAddCard()
    this.syncRemoveButtons()
  }

  // The remove button sits inside the zone's <label>, so its click must be
  // stopped here or it bubbles to the label and opens the file picker.
  remove(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.zoneTargets.length <= this.minValue) return

    event.target.closest("[data-uploads-target~=zone]").remove()
    this.renumber()
    this.syncAddCard()
    this.syncRemoveButtons()
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

  syncAddCard() {
    this.addTarget.hidden = this.zoneTargets.length >= this.maxValue
  }

  syncRemoveButtons() {
    const show = this.zoneTargets.length > this.minValue
    this.removeTargets.forEach((button) => { button.hidden = !show })
  }
}
