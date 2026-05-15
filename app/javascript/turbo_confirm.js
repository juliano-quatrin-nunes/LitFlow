// Replace Turbo's native window.confirm() with a custom dialog that uses the
// app's modal style. Some browsers silently block native confirms (e.g. after
// a previous "block dialogs" choice), so we drive our own.

function buildDialog () {
  let dialog = document.getElementById('turbo-confirm-dialog')
  if (dialog) return dialog

  dialog = document.createElement('dialog')
  dialog.id = 'turbo-confirm-dialog'
  dialog.className = 'modal animate-slide-up w-md p-0 bg-popover text-foreground rounded-xl shadow-xl border border-border'
  dialog.innerHTML = `
    <form method="dialog" class="flex flex-col">
      <header class="px-6 pt-6 pb-2">
        <h2 class="text-lg font-bold" data-turbo-confirm-title>Tem certeza?</h2>
        <p class="text-sm text-muted-foreground mt-1" data-turbo-confirm-body></p>
      </header>
      <footer class="flex justify-end gap-2 px-6 py-4">
        <button type="submit" value="cancel"
                class="btn btn-outline btn-sm">
          Cancelar
        </button>
        <button type="submit" value="confirm"
                class="btn btn-sm bg-destructive text-white hover:bg-destructive-hover">
          Confirmar
        </button>
      </footer>
    </form>
  `

  // Close when clicking the backdrop
  dialog.addEventListener('click', (event) => {
    if (event.target === dialog) {
      dialog.returnValue = 'cancel'
      dialog.close()
    }
  })

  document.body.appendChild(dialog)
  return dialog
}

function setupConfirm () {
  const handler = (message) => new Promise((resolve) => {
    const dialog = buildDialog()
    dialog.querySelector('[data-turbo-confirm-body]').textContent = message || 'Esta ação não pode ser desfeita.'

    const onClose = () => {
      dialog.removeEventListener('close', onClose)
      resolve(dialog.returnValue === 'confirm')
    }

    dialog.addEventListener('close', onClose)
    dialog.returnValue = 'cancel'
    dialog.showModal()
  })

  // Turbo 8+ (forms.confirm) and earlier (setConfirmMethod) — set both for safety.
  if (window.Turbo) {
    if (window.Turbo.config && window.Turbo.config.forms) {
      window.Turbo.config.forms.confirm = handler
    }
    if (typeof window.Turbo.setConfirmMethod === 'function') {
      window.Turbo.setConfirmMethod(handler)
    }
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', setupConfirm)
} else {
  setupConfirm()
}
