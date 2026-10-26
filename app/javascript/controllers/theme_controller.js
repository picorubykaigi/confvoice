import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "confvoice-theme"
export default class extends Controller {
  static targets = ["lightLabel", "darkLabel"]

  connect() {
    this.sync()
  }

  toggle() {
    this.setTheme(this.dark ? "light" : "dark")
  }

  setTheme(theme) {
    try {
      localStorage.setItem(STORAGE_KEY, theme)
    } catch (_) {
      // Ignore storage failures; the current page can still switch themes.
    }

    document.documentElement.classList.toggle("dark", theme === "dark")
    document.documentElement.dataset.theme = theme
    this.sync()
  }

  sync() {
    const dark = this.dark

    this.element.setAttribute("aria-pressed", dark ? "true" : "false")
    this.setLabelState(this.lightLabelTarget, !dark)
    this.setLabelState(this.darkLabelTarget, dark)
  }

  setLabelState(label, active) {
    label.classList.toggle("is-active", active)
  }

  get dark() {
    return document.documentElement.classList.contains("dark")
  }
}
