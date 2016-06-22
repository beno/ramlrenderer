require "yaml"
require "./api"

module RAML
    
  class Parser
    
    getter :api
  
    def initialize(path)
      @api = RAML::Api.new
      load_file(path)
    end
    
    def load_libraries(spec, directory)
      if spec["uses"]?
        spec["uses"].each do |key, value|
          path = File.join(directory, value.to_s)
          load_file(path, "#{key.to_s}.")
        end
      end
    end
    
    DIRECTIVES = %w{ types traits resourceTypes annotationTypes securitySchemes \
                     title description version baseUri baseUriParameters mediaType protocols }
    
    def load_directives(spec, namespace)
      DIRECTIVES.each do |directive|
        @api.add_directive directive, spec, namespace
      end
    end
    
    def load_resources(spec, tree = @api.resources, url = "")
      spec.each do |key, value|
        if key.to_s[0] == '/'
          url += key.to_s
          tree = @api.add_leaf tree, key.to_s
          @api.add_resource(url, tree, value.raw as Hash(YAML::Type, YAML::Type) )
          load_resources value, tree as Hash, url
        end
      end
    end
    
    def load_file(path, namespace = "")
      if File.exists?(path)
        dir = File.dirname path
        spec = YAML.parse File.read(path)
        load_libraries(spec, dir)
        load_directives(spec, namespace)
        load_resources(spec)
      else
        puts "File not found: #{path}"
      end
    end
    
  end  
    
end