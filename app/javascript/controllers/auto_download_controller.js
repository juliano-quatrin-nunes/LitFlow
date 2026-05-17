import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.element.dataset.autoDownloadFired === "true") return
    this.element.dataset.autoDownloadFired = "true"
    this.element.click()
  }
}
