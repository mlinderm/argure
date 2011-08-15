class Application
  def initialize(opts = {})
		@path = opts[:path] || Dir.pwd
    @files = Rack::File.new(@path)
  end

  def call(env)
    # Get the request path
    request = Rack::Request.new(env)
    path_info = request.path_info

    # Check for paths we want to override
    if path_info == "/" or path_info == "/index.html"
      [200, {"Content-Type" => "text/html"}, ::File.open(File.join(@path, 'index.html'))]
    else
      # Delegate to Rack::File
      @files.call(env)
    end
  end
end

use Rack::Static, :urls => ["/public", "/spec"]
map "/" do
  run Application.new(:path => "examples/")
end
