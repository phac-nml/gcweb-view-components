import { fileURLToPath } from "node:url"
import { defineConfig } from "vite"
import RubyPlugin from "vite-plugin-ruby"

// The demo consumes the gem the way a Vite host app would: by importing its
// SCSS sources and Stimulus controllers from the gem root.
const gemRoot = fileURLToPath(new URL("..", import.meta.url))

export default defineConfig({
  plugins: [RubyPlugin()],
  resolve: {
    alias: {
      gcweb_view_components: `${gemRoot}app/assets/javascripts/gcweb_view_components/index.js`,
      "gcweb_view_components-scss": `${gemRoot}app/assets/stylesheets/gcweb_view_components`
    }
  },
  server: {
    fs: { allow: [gemRoot] }
  }
})
