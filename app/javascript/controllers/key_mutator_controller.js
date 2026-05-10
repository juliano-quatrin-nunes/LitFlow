import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Simple helper to prevent the dropdown from opening when clicking the 'x'
  stop(event) {
    event.stopPropagation()
  }
}
