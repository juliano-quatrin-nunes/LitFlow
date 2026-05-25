import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.element.dataset.autoDownloadFired === "true") return
    this.element.dataset.autoDownloadFired = "true"

    // If it's a hidden anchor, try to click it.
    // Some browsers block .click() if not user-initiated.
    // We can also try window.location.assign if it's a direct link.
    const url = this.element.getAttribute("href")
    if (url) {
      window.location.assign(url)
    } else {
      this.element.click()
    }
  }
}
