import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "filters", "advanced", "hiddenType", "hiddenCategory"]
  
  connect() {
    // Initialize search on page load if query exists
    const urlParams = new URLSearchParams(window.location.search)
    if (urlParams.has('query')) {
      this.inputTarget.value = urlParams.get('query')
    }
  }
  
  search(event) {
    // Form will submit naturally via Turbo
  }
  
  handleInput(event) {
    // Debounced search could be implemented here
    // For now, let user press Enter or click Search
  }
  
  toggleFilters(event) {
    event.preventDefault()
    if (this.hasFiltersTarget) {
      this.filtersTarget.classList.toggle('hidden')
    }
  }
  
  toggleAdvanced(event) {
    event.preventDefault()
    if (this.hasAdvancedTarget) {
      this.advancedTarget.classList.toggle('hidden')
    }
  }
  
  fillSuggestion(event) {
    event.preventDefault()
    const suggestion = event.currentTarget.dataset.suggestion
    this.inputTarget.value = suggestion
    this.inputTarget.focus()
  }
  
  clearSearch(event) {
    event.preventDefault()
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }
  
  applyFilter(event) {
    // Used for sidebar filters
    event.preventDefault()
    const form = this.element
    form.requestSubmit()
  }
}