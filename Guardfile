# Guardfile
# More info at https://github.com/guard/guard#readme

guard 'coffeescript', :input => 'src/coffeescripts', :output => 'build/javascripts'
guard 'sprockets', :destination => "public/javascripts" do
  watch('src/javascripts/argure.js')
	watch (%r{^build/javascripts/.+\.js$}) { 'src/javascripts/argure.js' }
end
guard 'compass', :configuration_file => "compass.rb" do
	watch(%r{^src/stylesheets/(.*)\.s[ac]ss})
end
	
