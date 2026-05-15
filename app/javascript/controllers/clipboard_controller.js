import { Controller } from '@hotwired/stimulus'
import { showToast } from 'toast'

export default class ClipboardController extends Controller {
  static values = {
    content: String,
    sourceId: String,
    successText: { type: String, default: 'Copiado!' }
  }

  async copy (event) {
    event?.preventDefault?.()
    const text = this.#getContent()

    try {
      await navigator.clipboard.writeText(text)
      showToast(this.successTextValue, { variant: 'success' })
    } catch (err) {
      showToast('Não foi possível copiar.', { variant: 'error' })
      throw err
    }
  }

  #getContent () {
    if (this.hasSourceIdValue) {
      const el = document.getElementById(this.sourceIdValue)
      return el?.value ?? el?.textContent ?? ''
    }
    return this.contentValue
  }
}
