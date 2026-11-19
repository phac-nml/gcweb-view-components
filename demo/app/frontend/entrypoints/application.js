// Demo host entrypoint: wires the gem in exactly as a Vite app would.
import "gcweb_view_components-scss/gcweb.scss"

import { Application } from "@hotwired/stimulus"
import { registerGcwebControllers } from "gcweb_view_components"

const application = Application.start()
registerGcwebControllers(application)
