require 'integration_helper'

describe Pollex, type: :feature do
  include Rack::Test::Methods
  let(:app) { Rack::Lint.new(Pollex::Middleware) }

  it 'thumbnails a JPG' do
    VCR.use_cassette('jpg') do
      get '/2I3x0X0N3G3Q'
      expect(last_response).to be_ok
      content_length = last_response.headers['content-length'].to_i
      expect(content_length).to be_within(10).of(11527)
    end
  end

  it 'thumbnails the first frame of an animated GIF' do
    VCR.use_cassette('gif') do
      get '/1H0H0a2M0X2r'
      expect(last_response).to be_ok
      content_length = last_response.headers['content-length'].to_i
      expect(content_length).to be_within(10).of(1530)
    end
  end

  it 'thumbnails an image format without magic number identifier' do
    VCR.use_cassette('ico') do
      get '/27433B1O0x0O'
      expect(last_response).to be_ok
    end
  end

  it 'thumbnails an image with a too long file name' do
    VCR.use_cassette('too_long') do
      get '/0j0T2z0E3T2c'
      expect(last_response).to be_ok
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
      expect { get '/3t3Q3t3y171P' }.to raise_error(ArgumentError)
    end
  end

  it 'handles drops with disallowed characters in its url' do
    VCR.use_cassette('disallowed_characters') do
      get '/2g2H3M3S0Y2m'
      expect(last_response).to be_ok
    end
  end
end
