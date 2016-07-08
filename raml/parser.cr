require "yaml"
require "./api"

module RAML
  
  class ParseException < Exception
  end
    
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
        
    def load_includes(spec, dir)
      case spec
      when String
        spec.to_s.match(/.raml$/) ? YAML.parse(File.read(File.join(dir, spec.to_s))).raw : spec
      when Hash
        spec.as(Hash).each do |k, v|
          spec[k.as(YAML::Type)] = load_includes(v, dir)
        end
      else
        spec 
      end as YAML::Type
    end
    
    DIRECTIVES = %w{ types traits resourceTypes annotationTypes securitySchemes \
      title description version baseUri baseUriParameters mediaType protocols }

    
    def load_directives(spec, namespace, dir)
      DIRECTIVES.each do |directive|
        spec.raw.as(Hash)[directive.as(YAML::Type)] = load_includes(spec.raw.as(Hash)[directive]?, dir) as YAML::Type
        @api.add_directive directive, spec.raw, namespace
      end
      @api.build_data_types
    end
    
    def load_resources(spec, url = "")
      hash!(spec)
      spec.each do |key, value|
        if key.to_s[0] == '/'
          old_url = url
          url += key.to_s
          @api.add_resource(url, hash!(value))
          load_resources(value, url)
          url = old_url
        end
      end
    end
        
    def hash!(hash)
      raise ParseException.new("#{hash} is not a Hash") unless hash.raw.is_a?(Hash)
      hash.raw
    end
    
    def load_file(path, namespace = "")
      if File.exists?(path)
        dir = File.dirname path
        spec = YAML.parse(File.read(path))
        load_libraries(spec, dir)
        load_directives(spec, namespace, dir)
        load_resources(spec)
      else
        puts "File not found: #{path}"
      end
    end
    
  end  
    
end