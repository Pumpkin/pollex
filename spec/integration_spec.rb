require 'helper'
require 'pollex'
require 'rack/test'
require 'webmock/rspec'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
end

describe Pollex, type: :feature do
  include Rack::Test::Methods
  let(:app) { Pollex::Middleware }

  it 'thumbnails a PNG' do
    VCR.use_cassette('png') do
      get '/2I3x0X0N3G3Q'
      expect(last_response).to be_ok
      expect(last_response.headers['content-length']).to eq('8090')
    end
  end

  it 'thumbnails the first frame of an animated GIF' do
    VCR.use_cassette('gif') do
      get '/1H0H0a2M0X2r'
      expect(last_response).to be_ok
      expect(last_response.headers['content-length']).to eq('1530')
    end
  end

  it 'returns icon for a bookmark' do
    VCR.use_cassette('bookmark') do
      get '/1H1U0d0M2L0V'
      expect(last_response).to be_redirect
      expect(last_response.headers['location']).to eq('/icons/bookmark.png')
    end
  end

  it 'redirects to icon for non-image file' do
    VCR.use_cassette('file') do
      get '/3D2J1c292Q2h'
      expect(last_response).to be_redirect
      expect(last_response.headers['location']).to eq('/icons/text.png')
    end
  end

  it 'returns icon for a nonexistent drop' do
    VCR.use_cassette('nonexistent') do
      get '/nonexistent'
      expect(last_response).to be_not_found
      expect(last_response.headers['content-type']).to eq('text/html')
    end
  end

  it 'returns icon for an unprocessable image' do
    VCR.use_cassette('error') do
      get '/3t3Q3t3y171P'
      expect(last_response).to be_server_error
      expect(last_response.headers['content-type']).to eq('text/html')
    end
  end
end
