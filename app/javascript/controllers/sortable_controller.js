import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class SortableController extends Controller {
  static values = {
    url: String,
    handle: { type: String, default: '.sortable-handle' }
  }

  connect () {
    this.sortable = Sortable.create(this.element, {
      handle: this.handleValue,
      animation: 150,
      ghostClass: 'opacity-50',
      onEnd: this.#persistOrder.bind(this)
    })
  }

  disconnect () {
    this.sortable?.destroy()
  }

  async #persistOrder () {
    const ids = Array.from(this.element.querySelectorAll('[data-sortable-id]'))
      .map((el) => el.dataset.sortableId)
    const token = document.querySelector('meta[name="csrf-token"]')?.content

    await fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': token
      },
      body: JSON.stringify({ ids })
    })
  }
}
