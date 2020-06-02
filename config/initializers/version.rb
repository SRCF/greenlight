# frozen_string_literal: true

module Greenlight
  class Application
    VERSION = ENV["VERSION_CODE"] || `git describe --tags`
  end
end
