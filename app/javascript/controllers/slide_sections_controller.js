import { Controller } from '@hotwired/stimulus'

export default class SlideSectionsController extends Controller {
  static targets = ['card', 'hiddenField']
  static values = { hiddenName: String }

  serialize () {
    if (!this.hasHiddenFieldTarget) return

    const sections = this.cardTargets.map((card) => {
      const linesText = card.querySelector('[data-slide-section-editor-target="linesField"]')?.value || ''
      return {
        id: card.dataset.sectionId,
        type: card.querySelector('[data-slide-section-editor-target="typeField"]')?.value,
        label: card.querySelector('[data-slide-section-editor-target="labelField"]')?.value,
        lines: linesText.split('\n').filter((l) => l.trim().length > 0)
      }
    })

    this.hiddenFieldTarget.value = JSON.stringify(sections)
  }
}
