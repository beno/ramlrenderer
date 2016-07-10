require "yaml"
require "./shared"

module RAML
  
  class Api
    include CommonMethods
    
    getter :resources, :data_types

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
  
    def add_namespace(spec, namespace)
      traversed = empty_hash
      spec.as(Hash).each do |key, value|
        val = {"#{namespace}#{key.to_s}" as YAML::Type => value as YAML::Type}
        traversed.merge!(val)
      end
      traversed
    end
    
    def add_resource(uri, spec)
      resource = Resource.new(self, uri, spec)
      endpoint = @resources.ensure_path!(uri)
      endpoint["endpoint"] = resource if resource.endpoint?
      resource
    end
    
    def build_data_types
      if types = @spec["types"]?
        hash!(types).each do |key, value|
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
      root.each do |uri, value|
        if value.is_a? Hash
          if value.as(Hash)["endpoint"]?
            if resource = value.as(Hash)["endpoint"]
              res[resource.as(Resource).uri] = resource.as(Resource)
            end
          end
          res.deep_merge! all_resources(value)
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
      if @spec = hash!(@spec)["type"]?
        case @spec
        when Hash
          @spec.as(Hash).each do |key, val|
            @parameters.deep_merge! val.as(Hash)
          end
        end
      end
    end
         
  end

  class Resource
    include CommonMethods

    getter :requests, :api, :uri, :spec, :resource_type_spec
    
    def initialize(@api : Api, @uri : String, @spec : YAML::Type)
      @resource_type_spec = TypeSpec.new(@spec)
      @requests = Array(Request).new
      @spec.as(Hash).deep_merge!(resource_type)
      @spec.as(Hash).each do |key, spec|
        @requests << Request.new(self, key.to_s, spec.as(Hash)) if Request::VERBS.includes?(key.to_s.downcase)
      end
    end
    
    def resource_type
      api.spec("resourceTypes").as(Hash)[@resource_type_spec._type]? if api.spec("resourceTypes")
    end
    
    def endpoint?
      @requests.any?
    end

  end
  
  class Request
    include CommonMethods

    VERBS = %w{ get post put patch delete options head }

    getter :verb, :resource, :request, :responses, :uri_parameters, :headers, :query_string
    
    def initialize(@resource : Resource, @verb : String, @spec : Hash(YAML::Type, YAML::Type))
      @parameters = empty_hash.as(Hash(YAML::Type, YAML::Type))
      @uri_parameters = empty_hash.as(Hash(YAML::Type, YAML::Type))
      @headers = empty_hash.as(Hash(YAML::Type, YAML::Type))
      merge_traits(@resource.spec)
      merge_traits(@spec)
      parse_uri_parameters
      @responses = Array(Response).new
      if resp = spec("responses")
        resp.as(Hash).each do |code, spec|
          @responses << Response.new(self, code.to_s, spec as Hash)
        end
      end
      parse_query_string
    end
    
    def merge_traits(source_spec)
      if traits = hash!(source_spec)["is"]?
       array!(traits).each do |spec|
          name = case spec
          when Hash
            n = spec.as(Hash).first_key
            @parameters.deep_merge! spec.as(Hash)[n].as(Hash)
            n
          when String
            spec
          end
          if trait = api.spec("traits").as(Hash)[name]?
            @spec.deep_merge!(trait)
          end
        end
      end
    end
    
    def parse_uri_parameters
      params = @resource.uri.scan(/\{([^\}]*)\}/).map do |match|
        match[1]
      end.each do |param|
        @uri_parameters[param] = if uri_params_spec = @resource.spec("uriParameters")
          if spec = uri_params_spec.as(Hash)[param]?
            interpolate_hash spec.as(Hash(YAML::Type, YAML::Type))
          else
            {"type".as(YAML::Type) => "string".as(YAML::Type)}
          end
        else
          {"type".as(YAML::Type) => "string".as(YAML::Type)}
        end
      end
    end
    
    def parse_query_string
      spec = if query_string = @spec["queryString"]?
        hash!(query_string)
      else
        empty_hash
      end
      @query_string = QueryString.new(self, spec)
    end
    
    def query_parameters
      interpolate_hash (@spec["queryParameters"]? || empty_hash).as(Hash)
    end
    
    def headers
      interpolate_hash (@spec["headers"]? || empty_hash).as(Hash)
    end
    
    def api
      @resource.api
    end
    
    def uri
      @resource.uri
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
    
    def uri
      @request.resource.uri
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
    
    def uri
      @response.request.resource.uri
    end
    
    def example(_spec = spec("example"))
      case _spec
      when String
        parameter?(_spec) || _spec
      when Hash
        _spec
      when Nil
#        example @response.request.resource.resource_type_spec["example"]
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
        @spec[key] = empty_hash unless @spec[key]?
        @spec[key].as(Hash).deep_merge!(value)
      end
    end
    
    def properties
      (spec("properties") || Hash(YAML::Type, YAML::Type).new) as Hash
    end
    
  end
  
  alias MatrixType = String | Array(MatrixType)

  class QueryString
    include CommonMethods
    
    getter :property_sets
        
    def initialize(@request : Request, @spec : Hash(YAML::Type, YAML::Type) )
      p @spec
      @property_sets = Array((Hash(YAML::Type, YAML::Type))).new
      if type_spec = hash!(@spec)["type"]?
        case type_spec
        when Array
          merge_data_types type_spec
        when String
          merge_data_types [type_spec]
        end
      end
    end
    
    def properties(index = 0)
      if @property_sets[index]?
        @property_sets[index]
      else
        empty_hash
      end.as(Hash)
    end
    
    def combine_unions(unions)
      if unions.size == 1
        unions.first.map {|type| {type} }
      else
        unions.first.product *Tuple(Array(String)).from(unions[1..-1])
      end
    end
    
    def parse_type_spec(type_spec)
      skalars = Array(String).new
      unions = Array(Array(String)).new
      type_sets = Array(Array(String)).new
      array!(type_spec).each do |type|
        if type.as(String).match /\|/
          types = type.as(String).split "|"
          unions << types.map {|t| t.as(String).strip}
        else
          skalars << type.as(String).strip
        end
      end
      if unions.any?
        union_sets = combine_unions(unions)
        union_sets.each do |union_set|
          type_sets << (skalars.dup.concat union_set)
        end
      else
        type_sets = [skalars]
      end
      type_sets
    end
    
    
    def merge_data_types(type_spec)
      type_sets = parse_type_spec(type_spec)
      type_sets.each do |type_set|
        property_set = empty_hash.as(Hash(YAML::Type, YAML::Type))
        type_set.each do |type|
          if data_type = @request.resource.api.data_types[type]?
            property_set.merge! data_type.properties
          end
        end
        @property_sets << property_set
      end
    end

  end
end