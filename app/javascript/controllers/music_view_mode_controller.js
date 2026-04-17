import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["musician", "projection", "button"]
  static classes = ["active"]

  connect() {
    this.showMusician()
  }

  showMusician() {
    this.musicianTarget.classList.remove("hidden")
    this.projectionTarget.classList.add("hidden")
    this.updateButtons("musician")
  }

  showProjection() {
    this.musicianTarget.classList.add("hidden")
    this.projectionTarget.classList.remove("hidden")
    this.updateButtons("projection")
  }

  updateButtons(mode) {
    this.buttonTargets.forEach(button => {
      if (button.dataset.mode === mode) {
        button.classList.add(...this.activeClasses)
      } else {
        button.classList.remove(...this.activeClasses)
      }
    })
  }
}
