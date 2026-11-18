class PagesController < ApplicationController
  WET_COMPONENT_BACKLOG = [
    {
      name: "Alert module",
      slug: "alerts",
      reference_url: "https://wet-boew.github.io/wet-boew-legacy/v3.1/demos/guide-design/components-en.html#message-box-modules",
      status: :done
    },
    {
      name: "Featured link",
      slug: "gc-featured-link",
      reference_url: "https://github.com/wet-boew/GCWeb/tree/master/components/gc-featured-link",
      status: :in_progress
    },
    {
      name: "Most requested",
      slug: "gc-most-requested",
      reference_url: "https://github.com/wet-boew/GCWeb/tree/master/components/gc-most-requested",
      status: :planned
    },
    {
      name: "Services and information",
      slug: "gc-srvinfo",
      reference_url: "https://github.com/wet-boew/GCWeb/tree/master/components/gc-srvinfo",
      status: :planned
    },
    {
      name: "Table of contents",
      slug: "gc-toc",
      reference_url: "https://github.com/wet-boew/GCWeb/tree/master/components/gc-toc",
      status: :planned
    },
    {
      name: "Pagination",
      slug: "pagination",
      reference_url: "https://github.com/wet-boew/GCWeb/tree/master/components/pagination",
      status: :planned
    }
  ].freeze

  def index
    @wet_component_backlog = WET_COMPONENT_BACKLOG
  end
end
