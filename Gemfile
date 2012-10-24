source :gemcutter

gem 'rake'
gem 'em-http-request', '~> 1.0'
gem 'em-synchrony',    '~> 1.0'
gem 'hitimes'
gem 'metriks'
gem 'metriks-middleware', github: 'lmarburger/metriks-middleware'
gem 'mini_magick',     git:    'https://github.com/lmarburger/mini_magick.git',
                       branch: 'refactor_system_call'
gem 'rack-fiber_pool'
gem 'sinatra'
gem 'thin'
gem 'yajl-ruby'

gem 'airbrake'
gem 'newrelic_rpm'

gem 'foreman', group: 'development'

group :test do
  gem 'rack-test'
  gem 'vcr', '~> 1.11.3'
  gem 'webmock'
  gem 'wrong', git:    'https://github.com/sconover/wrong.git',
               branch: 'rb-1.9.3-p0'
end
