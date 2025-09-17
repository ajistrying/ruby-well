import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "filters", "advanced", "hiddenType", "hiddenCategory", "hiddenDateFrom", "hiddenDateTo", "hiddenFilters"]
  
  connect() {
    // Initialize search on page load if query exists
    const urlParams = new URLSearchParams(window.location.search)
    if (urlParams.has('query')) {
      this.inputTarget.value = urlParams.get('query')
    }
  }
  
  search(event) {
    // Form will submit naturally via Turbo
    console.log("Searching for:", this.inputTarget.value)
  }
  
  handleInput(event) {
    // Debounced search could be implemented here
    // For now, let user press Enter or click Search
  }
  
  toggleAdvanced(event) {
    event.preventDefault()
    if (this.hasAdvancedTarget) {
      this.advancedTarget.classList.toggle('hidden')
      
      // Hide/show hidden filter fields based on advanced section visibility
      if (this.hasHiddenFiltersTarget) {
        const isAdvancedHidden = this.advancedTarget.classList.contains('hidden')
        // Only show hidden fields when advanced section is hidden
        this.hiddenFiltersTarget.style.display = isAdvancedHidden ? 'block' : 'none'
      }
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