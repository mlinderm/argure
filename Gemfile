source 'http://rubygems.org'

gem 'rack'

group :development do
	gem 'json'

	require 'rbconfig'
	if RbConfig::CONFIG['target_os'] =~ /darwin/i
		gem 'growl'
		gem 'rb-fsevent', '>= 0.4.0', :require => false
	end
	if RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
		gem 'win32console'
		gem 'rb-fchange', '>= 0.0.2', :require => false
	end
	gem 'guard'

	gem 'guard-coffeescript'
	gem 'guard-compass'
	
	gem 'sprockets', :git => "git://github.com/matehat/sprockets.git"
	gem 'guard-sprockets'
end
