import { Controller } from '@hotwired/stimulus'

export default class SlideSectionTabsController extends Controller {
  static targets = ['tab', 'panel']

  connect () {
    const initial = this.tabTargets.findIndex((t) => t.dataset.active === 'true')
    this.activate(initial < 0 ? 0 : initial)
  }

  select (event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    if (index >= 0) this.activate(index)
  }

  activate (index) {
    this.tabTargets.forEach((tab, i) => {
      const active = i === index
      tab.dataset.active = active ? 'true' : 'false'
      tab.setAttribute('aria-selected', active ? 'true' : 'false')
    })
    this.panelTargets.forEach((panel, i) => {
      panel.dataset.active = i === index ? 'true' : 'false'
    })
  }
}
