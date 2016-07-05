require "yaml"
require "./shared"

module RAML
  
  class Api
    include CommonMethods
      
    alias TreeType = String | Resource | Hash(String, TreeType)

    getter :resources

    def initialize
      @spec = Hash(YAML::Type, YAML::Type).new
      @resources = Hash(String, TreeType).new
      @data_types = Hash(String, DataType).new
    end
    
    def default_media_types
      media_types = Array(YAML::Type).new
      if types = @spec["mediaType"]?
        case types
        when String
          media_types << types.as(String)
        when Array
          media_types.concat types.as(Array(YAML::Type))
        end
      else
        media_types << "application/json"
      end
      media_types
    end
    
    def data_type(name)
      if match = name.to_s.match /(.*)\[\]$/
        name = match[1]
      end
      @data_types[name.to_s]?
    end

    def add_leaf(tree : Hash, name : String)
      tree[name] = Hash(String, TreeType).new unless tree[name]?
      tree[name] as Hash
    end
  
    def add_namespace(spec, namespace)
      traversed = empty_hash
      spec.as(Hash).each do |key, value|
        val = {"#{namespace}#{key.to_s}" as YAML::Type => value as YAML::Type}
        traversed.merge!(val)
      end
      traversed
    end
    
    def add_resource(url, tree, spec)
      resource = Resource.new(self, url, spec)
      tree["endpoint"] = resource if resource.endpoint?
      resource
    end
    
    def build_data_types
      if types = @spec["types"]?
        types.as(Hash).each do |key, value|
          @data_types[key.to_s] = DataType.new(key.to_s, value as Hash)
        end
        @data_types.each do |_, data_type|
          data_type.resolve(self)
        end
      end
    end

    def add_directive(directive, spec, namespace = "")
      if val = spec.as(Hash)[directive]?
        case val.class
        when Hash.class
          @spec[directive] = empty_hash unless @spec[directive]? 
          @spec[directive].as(Hash).merge! add_namespace(val, namespace)
        when Array.class
          @spec[directive] = empty_array unless @spec[directive]? 
          @spec[directive].as(Array(YAML::Type)).concat(val.as(Array(YAML::Type)))
        when String.class
          @spec[directive] = val as String
        end
      end
    end
    
    def all_resources(root = resources)
      res = Hash(String, Resource).new
      root.each do |url, value|
        if value.is_a? Hash
          if value.as(Hash)["endpoint"]?
            res[url] = value.as(Hash)["endpoint"] as Resource
          end
          res.merge! all_resources(value)
        end
      end
      res
    end
    
    def directive_spec(name)
      interpolate_directives(spec(name).to_s)
    end

  end
  
  class TypeSpec
    include CommonMethods
    
    getter :parameters
    
    def initialize(@spec : YAML::Type)
      @parameters = empty_hash as Hash(YAML::Type, YAML::Type)
      if @spec = @spec.as(Hash)["type"]?
        case @spec
        when Hash
          @spec.as(Hash).each do |key, val|
            @parameters = val.as(Hash).merge @parameters
          end
        end
      end
    end
         
  end

  class Resource
    include CommonMethods

    getter :requests, :api, :url, :spec, :resource_type_spec
    
    def initialize(@api : Api, @url : String, @spec : Hash(YAML::Type, YAML::Type))
      @resource_type_spec = TypeSpec.new(@spec)
      @requests = Array(Request).new
      @spec.deep_merge(resource_type)
      @spec.each do |key, spec|
        @requests << Request.new(self, key.to_s, spec.as(Hash)) if Request::VERBS.includes?(key.to_s.downcase)
      end
    end
    
    def resource_type
      api.spec("resourceTypes").as(Hash)[@resource_type_spec._type]?
    end
    
    def endpoint?
      @requests.any?
    end

  end
  
  class Request
    include CommonMethods

    VERBS = %w{ get post put patch delete options head }

    getter :verb, :resource, :request, :responses
    
    def initialize(@resource : Resource, @verb : String, @spec : Hash(YAML::Type, YAML::Type))
      @parameters = empty_hash as Hash(YAML::Type, YAML::Type)
      merge_traits(@resource.spec)
      merge_traits(@spec)
      @responses = Array(Response).new
      if resp = spec("responses")
        resp.as(Hash).each do |code, spec|
          @responses << Response.new(self, code.to_s, spec as Hash)
        end
      end
    end
    
    def merge_traits(source_spec)
      if traits = source_spec.as(Hash)["is"]?
       traits.as(Array).each do |name|
          _name = case name
          when Hash
            n = name.as(Hash).first_key
            @parameters = name.as(Hash)[n].as(Hash).merge @parameters
            n
          when String
            name
          end
          if trait = api.spec("traits").as(Hash)[_name]?
            @spec.deep_merge(trait)
          end
        end
      end
    end

 
    def query_parameters
      interpolate_hash (@spec["queryParameters"]? || empty_hash).as(Hash)
    end
    
    def api
      @resource.api
    end
    
    def url
      @resource.url
    end
    
    def parameters
      @resource.resource_type_spec.parameters.merge @parameters
    end
      
  end

  class Response
    include CommonMethods

    getter :code, :media_types, :request, :spec
    
    def initialize(@request : Request, @code : String, @spec : Hash(YAML::Type, YAML::Type))
      @media_types = Hash(String, MediaType).new
      add_media_types(@spec)
    end

    def add_media_types(@spec)
      case @spec["body"]?
      when String
        api.default_media_types.each do |media_type|
          @media_types[media_type.to_s] = MediaType.new self, media_type.to_s, @spec["body"]
        end
      when Hash
        @spec["body"].as(Hash).each do |media_type, spec|
          @media_types[media_type.to_s] = MediaType.new self, media_type.to_s, spec
        end
      end
    end
    
    def api
      @request.resource.api
    end
    
    def url
      @request.resource.url
    end
    
  end
  
  class MediaType
    include CommonMethods
    
    getter :media_type, :spec
    
    def initialize(@response : Response, @media_type : String, @spec : YAML::Type)
    end
    
    def data_type
      @data_type ||= _data_type || @response._data_type || DataType.new("Unknown", empty_hash)
    end
    
    def api
      @response.request.resource.api
    end
    
    def url
      @response.request.resource.url
    end
    
    def example(_spec = spec("example"))
      case _spec
      when String
        parameter?(_spec) || _spec
      when Hash
        _spec
      when Nil
        example @response.request.resource.resource_type_spec["example"]
      end
    end
    
    def parameters
      @response.request.resource.resource_type_spec.parameters
    end


  end
    
  class DataType
    include CommonMethods

    
    getter :spec, :name
        
    def initialize(@name : String, @spec : Hash(YAML::Type, YAML::Type) )
    end
    
    def resolve(api)
      if data_type = api.data_type(_type)
        inherit_from data_type.resolve(api)
      end
      self
    end
    
    def inherit_from(data_type : DataType)
      data_type.spec.each do |key, value|
        @spec[key] = @spec[key]? ? data_type.spec[key].as(Hash).merge(@spec[key].as(Hash)) : data_type.spec[key]
      end
    end
    
    def properties
      (spec("properties") || Hash(YAML::Type, YAML::Type).new) as Hash
    end
    
  end
end