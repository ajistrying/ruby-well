import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  updateQuery(event) {
    const searchInput = document.querySelector('[data-search-target="input"]')

    if (searchInput) {
      const currentQuery = searchInput.value.trim()
      const link = event.currentTarget
      const url = new URL(link.href)

      if (currentQuery) {
        url.searchParams.set('query', currentQuery)
      } else {
        url.searchParams.delete('query')
      }

      link.href = url.toString()
    }
  }
}