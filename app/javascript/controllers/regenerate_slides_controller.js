import { Controller } from '@hotwired/stimulus'

export default class RegenerateSlidesController extends Controller {
  static values = {
    url: String,
    message: { type: String, default: 'Regenerar irá substituir o conteúdo dos slides e redefinir a sequência. Continuar?' }
  }

  async trigger (event) {
    event.preventDefault()
    if (!window.confirm(this.messageValue)) return

    const token = document.querySelector('meta[name="csrf-token"]')?.content

    const response = await fetch(this.urlValue, {
      method: 'POST',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': token
      }
    })

    if (response.ok) {
      const html = await response.text()
      window.Turbo?.renderStreamMessage(html)
    }
  }
}
