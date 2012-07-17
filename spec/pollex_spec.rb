require 'spec_helper'
require 'rack/test'
require 'support/vcr'

require 'pollex'

describe Pollex do
  include Rack::Test::Methods
  def app() Pollex end

  after do $stdout = STDOUT end

  it 'redirects the home page to the CloudApp product page' do
    get '/'

    assert { last_response.redirect? }

    headers = last_response.headers
    assert { headers['Location'] == 'http://getcloudapp.com' }
    assert { headers['Cache-Control'] == 'public, max-age=31557600' }
  end

  it 'returns thunbnail for drop' do
    VCR.use_cassette 'small' do
      EM.synchrony do
        $stdout = StringIO.new
        get '/hhgttg'
        EM.stop

        assert { last_response.ok? }

        headers = last_response.headers
        assert { headers['Content-Type'] == 'image/png' }
        assert { headers['Content-Disposition'] == 'inline' }
        assert { headers['Cache-Control'] == 'private, max-age=86400' }
      end
    end
  end

  it 'returns thunbnail for a typed drop' do
    VCR.use_cassette 'small' do
      EM.synchrony do
        $stdout = StringIO.new
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
        assert { headers['Cache-Control'] == 'public, max-age=31557600' }
      end
    end
  end

end
