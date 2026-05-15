// Inject a toast into the existing flash <turbo-frame id="flash">.
// Server-side flashes use the same wrapper, so the look is consistent.

const VARIANT_CLASSES = {
  success: 'bg-info text-white',
  info: 'bg-info text-white',
  notice: 'bg-info text-white',
  error: 'bg-destructive text-white',
  alert: 'bg-destructive text-white'
}

export function showToast (message, options = {}) {
  const frame = document.getElementById('flash')
  if (!frame) return

  const variant = options.variant || 'success'
  const duration = options.duration ?? 5000
  const variantClass = VARIANT_CLASSES[variant] || VARIANT_CLASSES.info

  const toast = document.createElement('div')
  toast.className = `relative w-full py-3 pl-4 pr-12 min-w-xs text-sm transition duration-300 rounded-xl md:max-w-lg md:w-fit ${variantClass}`

  const body = document.createElement('div')
  body.className = 'flex-1'
  if (options.html) {
    body.innerHTML = message
  } else {
    body.textContent = message
  }
  toast.appendChild(body)

  const closeBtn = document.createElement('button')
  closeBtn.type = 'button'
  closeBtn.setAttribute('aria-label', 'Fechar')
  closeBtn.className = 'absolute top-2.5 right-3 text-white transition duration-300 focus:outline-none opacity-80 hover:opacity-100'
  closeBtn.innerHTML = '<span class="icon icon-x-mark size-5"></span>'
  closeBtn.addEventListener('click', () => removeToast(toast))
  toast.appendChild(closeBtn)

  frame.appendChild(toast)

  if (duration > 0) {
    setTimeout(() => removeToast(toast), duration)
  }

  return toast
}

function removeToast (toast) {
  if (!toast.isConnected) return
  toast.classList.add('opacity-0')
  setTimeout(() => toast.remove(), 200)
}

// Expose globally so legacy scripts and inline handlers can call it.
window.showToast = showToast
