require "json"
require "commander"
require "./raml/parser"
require "./raml/renderer"

cli = Commander::Command.new do |cmd|
  cmd.use = "ramlrenderer"
  cmd.long = "HTML documentation renderer for RAML 1.0 files"

  cmd.flags.add do |flag|
    flag.name = "input"
    flag.short = "-i"
    flag.long = "--input"
    flag.default = "api.raml"
    flag.description = "The input RAML API specification file."
  end

  cmd.flags.add do |flag|
    flag.name = "output"
    flag.short = "-o"
    flag.long = "--output"
    flag.default = "./site/api.html"
    flag.description = "The output HTML file."
  end
  
  cmd.flags.add do |flag|
    flag.name = "bundle"
    flag.short = "-b"
    flag.long = "--bundle"
    flag.default = "true"
    flag.description = "Bundle all files in a single HTML file. Set to false for individual files."
  end
  
  cmd.run do |options, arguments|
    input = arguments.first? && arguments.first || options.string["input"]
    unless File.exists?(input)
      puts "RAML file \"#{input}\" not found"
      next
    end
    
    path = arguments.first? && "" || options.string["output"]
    parser = RAML::Parser.new(input)
    renderer = RAML::Renderer.new(parser.api)
    if path == ""
      html = renderer.render_docs
      html = options.string["bundle"] == "true" ? renderer.bundle_dependencies(html) : html
      puts html
    else
      options.string["bundle"] == "true" ? renderer.bundle(path) : renderer.write(path)
      puts "HTML written to #{path}"
    end
  end
end
Commander.run(cli, ARGV)
