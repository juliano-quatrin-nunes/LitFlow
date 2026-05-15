// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "toast"
import "turbo_confirm"

Turbo.StreamActions.dispatch_event = function () {
  const name = this.getAttribute("name")
  const detail = JSON.parse(this.getAttribute("detail") || "{}")
  this.targetElements.forEach((element) => {
    element.dispatchEvent(new CustomEvent(name, { detail }))
  })
}
