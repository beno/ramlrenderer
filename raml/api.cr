require "yaml"

module RAML
  
  module CommonMethods
    
    def interpolate(string : String)
      string.scan(/\{([^\}]*)\}/).each do |match|
        if val = @spec[match[1]]?
          string = string.sub match[0], val
        end
      end
      string
    end
    
    def spec(name)
      if val = @spec[name]?
        case val
        when String
          interpolate val
        else
          val
        end
      end
    end
        
    def merge_traits(source_spec, target_spec, api)
      if traits = (source_spec as Hash).delete("is")
        (traits as Array).each do |name|
          if trait = (api.spec("traits") as Hash)[name]? as Hash 
            trait.each do |key, val|
              (target_spec as Hash)[key] = (target_spec as Hash)[key]? ? (val as Hash).merge((target_spec as Hash)[key] as Hash) : val
            end
          end
        end
      end
      target_spec as Hash(YAML::Type, YAML::Type)
    end

  end
  
  class Api
    include CommonMethods
      
    alias TreeType = String | RAML::Resource | Hash(String, TreeType)

    getter :resources

    def initialize
      @spec = Hash(YAML::Type, YAML::Type).new
      @resources = Hash(String, TreeType).new
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
      resource = RAML::Resource.new(self, url, spec)
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
    
    VERBS = %w{ get post put patch delete options head }

    def initialize(api : RAML::Api, @url : String, spec)
      @spec = merge_resource_type(spec, api) as Hash(YAML::Type, YAML::Type)
      @requests = Array(RAML::Request).new
      @spec.each do |key, spec|
        @requests << RAML::Request.new(api, key as String, merge_traits(@spec, spec, api)) if VERBS.includes?(key.to_s.downcase)
      end
    end
    
    def merge_resource_type(spec, api)
      if name = (spec as Hash).delete("type")
        if resource_type = (api.spec("resourceTypes") as Hash)[name]?
          VERBS.each do |verb|
            if val = (resource_type as Hash).delete(verb)
              spec[verb] = spec[verb]? ? (val as Hash).merge(spec[verb] as Hash) : val
            end
          end
          spec = (resource_type as Hash).merge(spec as Hash) 
        end
      end
      spec
    end

    
    def endpoint?
      @requests.any?
    end

  end
  
  class Request
    include CommonMethods
  
    getter :verb, :request, :responses
    
    def initialize(api : RAML::Api, @verb : String, spec : Hash(YAML::Type, YAML::Type))
      @spec = merge_traits(spec, spec, api) as Hash(YAML::Type, YAML::Type)
      @responses = Array(RAML::Response).new
      if resp = @spec.delete("responses") as Hash
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