source 'http://rubygems.org'

group :development do
	gem 'json'

	require 'rbconfig'
	if RbConfig::CONFIG['target_os'] =~ /darwin/i
		gem 'rb-fsevent', '>= 0.4.0', :require => false
	end
	gem 'guard-coffeescript'

	gem 'sprockets'
	gem 'guard-sprockets'
end
