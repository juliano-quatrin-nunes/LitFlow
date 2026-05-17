import { Controller } from '@hotwired/stimulus'

const OVERFLOW_THRESHOLD = 32

export default class SlideSectionEditorController extends Controller {
  static targets = ['linesField', 'hints', 'labelField']

  connect () {
    this.refresh()
  }

  refresh () {
    if (!this.hasLinesFieldTarget || !this.hasHintsTarget) return

    const lines = this.linesFieldTarget.value.split('\n')
    const overflowing = []
    lines.forEach((line, idx) => {
      if (line.length > OVERFLOW_THRESHOLD) overflowing.push(idx + 1)
    })

    this.hintsTarget.innerHTML = ''
    if (overflowing.length === 0) return

    const chip = document.createElement('span')
    chip.className = 'inline-flex items-center gap-1.5 text-xs bg-yellow-50 border border-yellow-200 text-yellow-900 px-2 py-1 rounded'

    const icon = document.createElement('span')
    icon.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>'
    chip.appendChild(icon)

    const text = document.createElement('span')
    const noun = overflowing.length === 1 ? 'A linha' : 'As linhas'
    const verb = overflowing.length === 1 ? 'pode' : 'podem'
    text.textContent = `${noun} ${this.#formatList(overflowing)} ${verb} ultrapassar o limite do slide`
    chip.appendChild(text)

    this.hintsTarget.appendChild(chip)
  }

  syncTabLabel () {
    if (!this.hasLabelFieldTarget) return
    const id = this.element.dataset.sectionId
    if (!id) return
    const tab = document.querySelector(`[data-tab-for="${id}"] [data-tab-label]`)
    if (tab) tab.textContent = this.labelFieldTarget.value || id
  }

  #formatList (numbers) {
    if (numbers.length === 1) return String(numbers[0])
    if (numbers.length === 2) return `${numbers[0]} e ${numbers[1]}`
    return `${numbers.slice(0, -1).join(', ')} e ${numbers[numbers.length - 1]}`
  }
}
