require 'integration_helper'

describe Pollex::Homepage, type: :feature do
  include Rack::Test::Methods

  let(:app)        { Rack::Lint.new(Pollex::Homepage.new(downstream)) }
  let(:downstream) { ->(env) { [200, {}, ['42']] }}

  it 'redirects home page requests' do
    get '/'
    expect(last_response).to be_redirect
    expect(last_response['location']).to eq('http://getcloudapp.com')
    expect(last_response['cache-control']).to eq('public, max-age=86400')
    date = Time.httpdate(last_response['date'])
    expect(date).to be_within(2).of(Time.now)
  end

  it 'calls downstream app for other requests' do
    get '/path'
    expect(last_response).to be_ok
  end
end
