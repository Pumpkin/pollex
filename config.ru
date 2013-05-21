require 'rack-timeout'
require 'pollex'
require 'pollex/exception_tracking'
require 'pollex/instrumentation'

Pollex::ExceptionTracking.setup(self)
Pollex::Instrumentation.setup(self)

public_file_urls = Dir['public/**/*'].select {|x| File.file?(x) }
                                     .map {|s| s.sub(/^public/, '') }
use Rack::Static, urls: public_file_urls, root: 'public'

# Stop trying to thumbnail after 15 seconds
use Rack::Timeout
Rack::Timeout.timeout = 15

run Pollex::Middleware
