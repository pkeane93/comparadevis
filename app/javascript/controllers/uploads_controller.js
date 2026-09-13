import { Controller } from "@hotwired/stimulus"

const FILLED = ["border-solid", "border-cyan-400"]
const EMPTY = ["border-dashed", "border-slate-700"]

// Adds and removes upload zones between a minimum and a maximum, and shows
// the chosen filename in place of the hint once a file is picked.
export default class extends Controller {
  static targets = ["zones", "zone", "add", "remove", "title", "hint", "form", "panel", "submit", "reset"]
  static values = { max: Number, min: Number, hint: String, quoteLabel: String }

  connect() {
    this.syncAddCard()
    this.syncRemoveButtons()
  }

  // Swaps Compare for Reset the moment a comparison is submitted — Turbo
  // handles the actual request, this just reacts to the same submit event.
  onSubmit() {
    this.submitTarget.hidden = true
    this.resetTarget.hidden = false
  }

  // Clears the uploads and the comparison panel without a page reload.
  reset(event) {
    event.preventDefault()

    this.formTarget.reset()
    this.zoneTargets.slice(this.minValue).forEach((zone) => zone.remove())
    this.zoneTargets.forEach((zone) => this.markEmpty(zone))
    this.renumber()
    this.syncAddCard()
    this.syncRemoveButtons()

    this.panelTarget.innerHTML = ""
    this.submitTarget.hidden = false
    this.resetTarget.hidden = true
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
      file ? file.name : this.hintValue
  }

  markEmpty(zone) {
    zone.classList.remove(...FILLED)
    zone.classList.add(...EMPTY)
    zone.querySelector("[data-uploads-target~=hint]").textContent = this.hintValue
  }

  // quoteLabelValue carries a "%{n}" placeholder from the server-rendered
  // translation (e.g. "Quote %{n}"), swapped for the real number here.
  renumber() {
    this.zoneTargets.forEach((zone, index) => {
      zone.querySelector("[data-uploads-target~=title]").textContent =
        this.quoteLabelValue.replace("%{n}", index + 1)
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
