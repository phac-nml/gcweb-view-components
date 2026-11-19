// gcweb_view_components — Stimulus controllers.
//
//   import { Application } from "@hotwired/stimulus"
//   import { registerGcwebControllers } from "gcweb_view_components"
//
//   const application = Application.start()
//   registerGcwebControllers(application)
//
// Controller identifiers are prefixed with "gcweb--" (Stimulus' convention for
// a folder namespace), matching the data-controller values the components
// render.

import FeaturedLinkController from "./controllers/featured_link_controller.js"

export const controllers = {
  "gcweb--featured-link": FeaturedLinkController
}

export function registerGcwebControllers(application) {
  for (const [identifier, controller] of Object.entries(controllers)) {
    application.register(identifier, controller)
  }
}

export { FeaturedLinkController }
