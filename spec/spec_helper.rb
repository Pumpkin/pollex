require 'rubygems'
require 'bundler'
Bundler.setup :default, :test

require 'minitest/autorun'
require 'minitest/spec'

ENV['RACK_ENV'] = 'test'
