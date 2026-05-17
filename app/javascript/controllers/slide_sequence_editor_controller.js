import { Controller } from '@hotwired/stimulus'

export default class SlideSequenceEditorController extends Controller {
  static targets = ['chips', 'hiddenField']

  serialize () {
    if (!this.hasHiddenFieldTarget || !this.hasChipsTarget) return
    const ids = Array.from(this.chipsTarget.querySelectorAll('[data-sortable-id]'))
      .map((el) => el.dataset.sortableId)
    this.hiddenFieldTarget.value = JSON.stringify(ids)
  }

  duplicate (event) {
    const id = event.currentTarget.dataset.id
    const sourceChip = event.currentTarget.closest('[data-sortable-id]')
    const clone = sourceChip.cloneNode(true)
    sourceChip.insertAdjacentElement('afterend', clone)
    this.serialize()
  }

  remove (event) {
    const chip = event.currentTarget.closest('[data-sortable-id]')
    chip.remove()
    this.serialize()
  }
}
