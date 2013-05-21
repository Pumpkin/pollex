require 'rack-timeout'
require 'pollex'

# Catch exceptions and return a 500 downstream from metriks/middleware.
Pollex::Instrumentation.setup(self)
use Pollex::HandleExceptions
Pollex::ExceptionTracking.setup(self)

public_file_urls = Dir['public/**/*'].select {|x| File.file?(x) }
                                     .map {|s| s.sub(/^public/, '') }
use Rack::Static, urls: public_file_urls, root: 'public'

# Stop trying to thumbnail after 15 seconds
use Rack::Timeout
Rack::Timeout.timeout = 15

run Pollex::Middleware
