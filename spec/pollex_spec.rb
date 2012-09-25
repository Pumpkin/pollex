require 'spec_helper'
require 'rack/test'
require 'support/vcr'

require 'pollex'

describe Pollex do
  include Rack::Test::Methods
  def app() Pollex end

  it 'redirects the home page to the CloudApp product page' do
    get '/'

    assert { last_response.redirect? }

    headers = last_response.headers
    assert { headers['Location'] == 'http://getcloudapp.com' }
    assert { Time.now - Time.parse(headers['Date']) < 2.0 }
    assert { headers['Cache-Control'] == 'public, max-age=31557600' }
  end

  it 'returns thunbnail for drop' do
    VCR.use_cassette 'small' do
      EM.synchrony do
        get '/hhgttg'
        EM.stop

        assert { last_response.ok? }

        headers = last_response.headers
        assert { headers['Content-Type'] == 'image/png' }
        assert { headers['Content-Disposition'] == 'inline' }
        assert { Time.now - Time.parse(headers['Date']) < 2.0 }
        assert { headers['Cache-Control'] == 'public, max-age=900' }
        assert { headers['Last-Modified'] == 'Fri, 25 Mar 2011 19:04:30 GMT' }
      end
    end
  end

  it 'returns a not modified response for cached drop' do
    VCR.use_cassette 'small' do
      EM.synchrony do
        header 'If-Modified-Since', 'Fri, 25 Mar 2011 19:04:30 GMT'
        get '/image/hhgttg'
        EM.stop

        assert { last_response.status == 304 }
        assert { last_response.empty? }
        assert { Time.now - Time.parse(last_response.headers['Date']) < 2.0 }
      end
    end
  end

  it 'returns thunbnail for a typed drop' do
    VCR.use_cassette 'small' do
      EM.synchrony do
        get '/image/hhgttg'
        EM.stop

        assert { last_response.ok? }
        assert { last_response.headers['Content-Type'] == 'image/png' }
      end
    end
  end

  it 'returns not found for a nonexistent drop' do
    VCR.use_cassette 'nonexistent' do
      EM.synchrony do
        get '/hhgttg'
        EM.stop

        assert { last_response.not_found? }
        assert { last_response.body.include?('Sorry, no drops live here') }
      end
    end
  end

  it 'redirects to the icon for a non-image drop' do
    VCR.use_cassette 'text' do
      EM.synchrony do
        get '/hhgttg'
        EM.stop

        assert { last_response.redirect? }

        headers = last_response.headers
        assert { headers['Location'] == 'http://example.org/icons/text.png' }
        assert { Time.now - Time.parse(headers['Date']) < 2.0 }
        assert { headers['Cache-Control'] == 'public, max-age=31557600' }
      end
    end
  end

  it 'redirects to the unknown icon for a file type without an icon' do
    VCR.use_cassette 'pdf' do
      EM.synchrony do
        get '/hhgttg'
        EM.stop

        assert { last_response.redirect? }

        headers = last_response.headers
        assert { headers['Location'] == 'http://example.org/icons/unknown.png' }
        assert { Time.now - Time.parse(headers['Date']) < 2.0 }
        assert { headers['Cache-Control'] == 'public, max-age=31557600' }
      end
    end
  end
end
