import { Controller } from "@hotwired/stimulus"

// Reloads the comparison frame until the job finishes. The panel only carries
// this controller while the comparison is still running, so once the finished
// panel is swapped in, disconnect() stops the timer.
export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 2000 } }

  connect() {
    this.timer = setInterval(() => this.refresh(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  refresh() {
    const frame = this.element.closest("turbo-frame")
    if (!frame) return

    // Assigning the same src again is a no-op, so reload() after the first fetch.
    if (frame.src !== this.urlValue) {
      frame.src = this.urlValue
    } else {
      frame.reload()
    }
  }
}
