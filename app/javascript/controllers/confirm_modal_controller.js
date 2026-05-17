import { Controller } from '@hotwired/stimulus'

export default class ConfirmModalController extends Controller {
  static values = { message: String }

  confirm (event) {
    if (!window.confirm(this.messageValue)) {
      event.preventDefault()
    }
  }
}
