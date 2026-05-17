import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 4000 } }

  connect() {
    this.timeoutId = setTimeout(() => this.dismiss(), this.durationValue)
  }

  disconnect() {
    if (this.timeoutId) clearTimeout(this.timeoutId)
  }

  dismiss() {
    this.element.remove()
  }
}
