import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.element.dataset.autoDownloadFired === "true") return
    this.element.dataset.autoDownloadFired = "true"

    // Small delay to ensure browser is ready and not blocking popups/downloads
    setTimeout(() => {
      const url = this.element.getAttribute("href")
      if (url) {
        // Try direct assignment first as it's more reliable for Active Storage downloads
        window.location.assign(url)
      } else {
        this.element.click()
      }
    }, 100)
  }
}
