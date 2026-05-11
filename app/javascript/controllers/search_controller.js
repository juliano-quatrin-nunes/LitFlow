import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 300)
  }

  // Ensure the input keeps focus after Turbo replaces the frame
  connect() {
    if (this.hasInputTarget && this.inputTarget.value.length > 0) {
      this.inputTarget.focus()
      // Move cursor to end
      const length = this.inputTarget.value.length
      this.inputTarget.setSelectionRange(length, length)
    }
  }
}
