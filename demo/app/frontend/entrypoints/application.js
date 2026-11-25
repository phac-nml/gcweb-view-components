// Demo host entrypoint: wires the gem in exactly as a Vite app would.
import "gcweb_view_components-scss/gcweb.scss"

import * as Turbo from "@hotwired/turbo"
import { Application } from "@hotwired/stimulus"
import { registerGcwebControllers } from "gcweb_view_components"

// Frames only (data tables): the other previews load and submit as usual.
Turbo.session.drive = false

const application = Application.start()
registerGcwebControllers(application)
