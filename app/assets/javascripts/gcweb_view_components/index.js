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
import FormValidationController from "./controllers/form_validation_controller.js"
import OverlayController from "./controllers/overlay_controller.js"
import TabsController from "./controllers/tabs_controller.js"
import ToggleController from "./controllers/toggle_controller.js"

export const controllers = {
  "gcweb--featured-link": FeaturedLinkController,
  "gcweb--form-validation": FormValidationController,
  "gcweb--overlay": OverlayController,
  "gcweb--tabs": TabsController,
  "gcweb--toggle": ToggleController
}

export function registerGcwebControllers(application) {
  for (const [identifier, controller] of Object.entries(controllers)) {
    application.register(identifier, controller)
  }
}

export { FeaturedLinkController, FormValidationController, OverlayController, TabsController, ToggleController }
