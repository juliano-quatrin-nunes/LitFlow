import { Controller } from '@hotwired/stimulus'
import { showToast } from 'toast'

export default class ClipboardController extends Controller {
  static values = {
    content: String,
    sourceId: String,
    htmlContent: String,
    htmlSourceId: String,
    successText: { type: String, default: 'Copiado!' }
  }

  async copy (event) {
    event?.preventDefault?.()
    const text = this.#getContent()
    const html = this.#getHtmlContent()

    try {
      if (html) {
        const textBlob = new Blob([text], { type: 'text/plain' })
        const htmlBlob = new Blob([html], { type: 'text/html' })
        
        await navigator.clipboard.write([
          new ClipboardItem({
            'text/plain': textBlob,
            'text/html': htmlBlob
          })
        ])
      } else {
        await navigator.clipboard.writeText(text)
      }

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

  #getHtmlContent () {
    if (this.hasHtmlSourceIdValue) {
      const el = document.getElementById(this.htmlSourceIdValue)
      return el?.innerHTML ?? el?.value ?? el?.textContent ?? ''
    }
    return this.hasHtmlContentValue ? this.htmlContentValue : null
  }
}
