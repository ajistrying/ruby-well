import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { entryId: Number }
  
  recordClick(event) {
    // Track the click (could send to analytics or backend)
    const entryId = this.entryIdValue
    
    if (entryId) {
      // Could make an AJAX call to record the click
      // For now, just log it
      console.log(`Entry ${entryId} clicked`)
      
      // Store in localStorage for basic tracking
      const clicks = JSON.parse(localStorage.getItem('entry_clicks') || '{}')
      clicks[entryId] = (clicks[entryId] || 0) + 1
      localStorage.setItem('entry_clicks', JSON.stringify(clicks))
    }
  }
}