import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "feedback", "tip"]
  
  open(event) {
    event.preventDefault()
    
    // Determine which modal to open based on data attribute
    const modalType = event.currentTarget.dataset.modalTarget
    let modalId = "modal_general"
    
    if (modalType === "feedback") {
      modalId = "modal_feedback"
    } else if (modalType === "tip") {
      modalId = "modal_tip"
    }
    
    const modal = document.getElementById(modalId)
    if (modal) {
      modal.showModal()
    }
  }
  
  close(event) {
    const modal = event.target.closest('dialog')
    if (modal) {
      modal.close()
    }
  }
  
  closeOnBackdrop(event) {
    // Close modal when clicking outside of it
    const dialogDimensions = event.target.getBoundingClientRect()
    if (
      event.clientX < dialogDimensions.left ||
      event.clientX > dialogDimensions.right ||
      event.clientY < dialogDimensions.top ||
      event.clientY > dialogDimensions.bottom
    ) {
      event.target.close()
    }
  }
}