require "yaml"

module RAML
  
  module CommonMethods
    
    def description
      @spec["description"]?
    end
    
    def interpolate(string : String)
      string.scan(/\{([^\}]*)\}/).each do |match|
        if val = @spec[match[1]]?
          string = string.gsub match[0], val
        end
      end
      string
    end
    
  end
  
  class Api
    include CommonMethods
      
    alias TreeType = String | RAML::Resource | Hash(String, TreeType)

    getter :resources, :spec

    def initialize
      @spec = Hash(YAML::Type, YAML::Type).new
      @resources = Hash(String, TreeType).new
    end
        
    def base_uri
      interpolate @spec["baseUri"]? as String
    end
    
    def types
      @spec["types"] as Hash(YAML::Type, YAML::Type)
    end

    def empty_hash
      Hash(YAML::Type, YAML::Type).new
    end
    
    def empty_array
      Array(YAML::Type).new
    end

    def add_leaf(tree : Hash, name : String)
      tree[name] = Hash(String, TreeType).new unless tree[name]?
      tree[name] as Hash
    end
  
    def add_namespace(spec, namespace)
      traversed = empty_hash
      (spec as Hash).each do |key, value|
        val = {"#{namespace}#{key.to_s}" as YAML::Type => value as YAML::Type}
        traversed.merge!(val)
      end
      traversed
    end

    def add_resource(url, tree, spec)
      resource = RAML::Resource.new(url, spec)
      tree["endpoint"] = resource if resource.endpoint?
      resource
    end

    def add_directive(directive, spec, namespace = "")
      if val = (spec as Hash)[directive]?
        case val.class
        when Hash.class
          @spec[directive] = empty_hash unless @spec[directive]? 
          (@spec[directive] as Hash).merge! add_namespace(val, namespace)
        when Array.class
          @spec[directive] = empty_array unless @spec[directive]? 
          (@spec[directive] as Array(YAML::Type)).concat((val as Array(YAML::Type)))
        when String.class
          @spec[directive] = val as String
        end
      end
    end

  end

  class Resource
    include CommonMethods

    getter :requests, :url

    def initialize(@url : String, @spec :  Hash(YAML::Type, YAML::Type))
      if resourceType = @spec.delete("type")
        merge_resource_type(resourceType)
      end
      @requests = Array(RAML::Request).new
      @spec.each do |key, value|
        @requests << RAML::Request.new(key as String, value as Hash(YAML::Type, YAML::Type)) if key.to_s[0] != '/'
      end
    end
    
    def merge_resource_type(resourceType)
      
    end

    def endpoint?
      @requests.any?
    end

  end
  
  class Request
    include CommonMethods
  
    getter :verb, :request, :responses
    
    def initialize(@verb : String, @spec : Hash(YAML::Type, YAML::Type))
      @responses = Array(RAML::Response).new
      if resp = spec.delete("responses") as Hash
        resp.each do |code, spec|
          @responses << RAML::Response.new(code.to_s, spec as Hash)
        end
      end
    end
    
    def queryParameters
      @spec["queryParameters"]? ? @spec["queryParameters"] as Hash(YAML::Type, YAML::Type) : Hash(YAML::Type, YAML::Type).new
    end
    
    def body
      @spec["body"]? ? @spec["body"] as Hash(YAML::Type, YAML::Type) : Hash(YAML::Type, YAML::Type).new
    end
  end

  class Response
    include CommonMethods
    
    getter :code
    
    def initialize(@code : String, @spec : Hash(YAML::Type, YAML::Type))
    end
    
    def body
      @spec["body"]? ? @spec["body"] as Hash(YAML::Type, YAML::Type) : Hash(YAML::Type, YAML::Type).new
    end

  end
end