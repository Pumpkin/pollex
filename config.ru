require './lib/pollex'

public_file_urls = Dir['public/**/*'].select {|x| File.file?(x) }
                                     .map {|s| s.sub(/^public/, '') }
use Rack::Static, urls: public_file_urls, root: 'public'
run Pollex::Middleware
