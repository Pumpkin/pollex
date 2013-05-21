require 'helper'
require 'rack/test'
require 'webmock/rspec'
require 'vcr'
require 'pollex'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
end
