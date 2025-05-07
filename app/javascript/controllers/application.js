import { Application } from "@hotwired/stimulus"
// to use bootstrap
import "bootstrap"
import "bootstrap/dist/css/bootstrap.min.css"


const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
