import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  
  async copyLink(event) {
    event.preventDefault()
    
    const url = this.urlValue || window.location.href
    
    try {
      await navigator.clipboard.writeText(url)
      this.showToast("Link copied to clipboard!")
      
      // Change button text temporarily
      const button = event.currentTarget
      const originalText = button.innerHTML
      button.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        Copied!
      `
      button.classList.add('btn-success')
      
      setTimeout(() => {
        button.innerHTML = originalText
        button.classList.remove('btn-success')
      }, 2000)
    } catch (err) {
      console.error('Failed to copy:', err)
      this.showToast("Failed to copy link", "error")
    }
  }
  
  async share(event) {
    event.preventDefault()
    
    const url = this.urlValue || window.location.href
    const title = document.title
    
    if (navigator.share) {
      try {
        await navigator.share({
          title: title,
          url: url
        })
      } catch (err) {
        console.log('Share cancelled or failed:', err)
      }
    } else {
      // Fallback to copy
      this.copyLink(event)
    }
  }
  
  showToast(message, type = "success") {
    // Create a toast notification
    const toast = document.createElement('div')
    toast.className = `alert alert-${type} fixed bottom-4 right-4 z-50 max-w-sm shadow-lg`
    toast.innerHTML = `
      <span>${message}</span>
    `
    
    document.body.appendChild(toast)
    
    // Auto-remove after 3 seconds
    setTimeout(() => {
      toast.remove()
    }, 3000)
  }
}