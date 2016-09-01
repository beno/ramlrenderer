require "yaml"
require "json"
require "./shared"

module RAML
  
  class Api
    include CommonMethods
    

    getter :resources, :source_files, :default_serializations, :data_types
    
    def spec(name)
      @spec[name]?
    end
        
    def initialize
      @default_serializations = ["application/json".as(YAML::Type)]
      @data_types = Hash(String, DataType).new
      @source_files = Array(String).new
      @resources = Hash(String, TreeType).new
      @spec = Hash(YAML::Type, YAML::Type).new
      build_default_serializations
    end
    
    def build_default_serializations
      if types = @spec["mediaType"]?
        @default_serializations = Array(YAML::Type).new
        case types
        when String
          @default_serializations << types.as(String)
        when Array
          @default_serializations.concat types.as(Array(YAML::Type))
        end
      end
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
        case val
        when Hash
          @spec[directive] = empty_hash unless @spec[directive]? 
          @spec[directive].as(Hash).merge! add_namespace(val, namespace)
        when Array
          @spec[directive] = empty_array unless @spec[directive]? 
          @spec[directive].as(Array(YAML::Type)).concat(val.as(Array(YAML::Type)))
        when String
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
    
    def interpolate_directives(string : String)
      return string unless @spec.is_a? Hash
      string.scan(/\{([^\}]*)\}/).each do |match|
        if val = directive?(match[1])
          string = string.sub match[0], val
        end
      end
      string
    end

    def directive?(name, spec = @spec)
      return spec unless spec.is_a? Hash
      spec.as(Hash)[name]?
    end


  end
  
  class ResourceType
    include CommonMethods
    
    getter :parameters
    
    def initialize(@resource : Resource, @spec : YAML::Type)
      @parameters = empty_hash as Hash(YAML::Type, YAML::Type)
      if spec = hash!(@spec)["type"]?
        resource_type_name = case spec
        when String
          spec.as(String)
        when Hash
          @parameters.deep_merge! spec.as(Hash).first_value
          spec.as(Hash).first_key
        end
        unless @spec = source(resource_type_name)
          raise "Unkown resource type"
        end

      end
    end
    
    def source(name)
      api.spec("resourceTypes") && api.spec("resourceTypes").as(Hash)[name]?
    end
    
    def api
      @resource.api
    end
         
  end

  class Resource
    include CommonMethods

    getter :requests, :api, :uri, :spec
    
    def initialize(@api : Api, @uri : String, @spec : YAML::Type)
      @requests = Array(Request).new
      @resource_type = ResourceType.new(self, @spec)
      @spec.as(Hash).deep_merge!(resource_type.spec)
      @spec.as(Hash).each do |key, spec|
        @requests << Request.new(self, key.to_s, spec.as(Hash)) if Request::VERBS.includes?(key.to_s.downcase)
      end
    end
            
    def endpoint?
      @requests.any?
    end
    
    def resource_type : ResourceType
      @resource_type.as(ResourceType)
    end

  end
  
  class Request
    include CommonMethods

    VERBS = %w{ get post put patch delete options head }

    getter :verb, :resource, :request, :responses, :uri_parameters, :headers, :query_string, :body, :headers
    
    def initialize(@resource : Resource, @verb : String, @spec : Hash(YAML::Type, YAML::Type))
      @parameters = empty_hash.as(Hash(YAML::Type, YAML::Type))
      @uri_parameters = empty_hash.as(Hash(YAML::Type, YAML::Type))
      @responses = Array(Response).new
      @body = Body.new(@resource, spec("body"))
      @headers = Headers.new(@resource, spec("headers"))
      merge_traits(@resource.spec)
      merge_traits(@spec)
      parse_uri_parameters
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
      @resource.resource_type.parameters.merge @parameters
    end
      
  end

  class Response
    include CommonMethods

    getter :code, :request, :spec, :body, :headers
    
    def initialize(@request : Request, @code : String, @spec : Hash(YAML::Type, YAML::Type))
      @body = Body.new(@request.resource, spec("body"))
      @headers = Headers.new(@request.resource, spec("headers"))

    end
    

    
    def api
      @request.resource.api
    end
    
    def uri
      @request.resource.uri
    end
    
  end
  
  class Body
    include CommonMethods
    
    getter :examples, :serializations, :data_type
    
    def initialize(@resource : Resource, @spec : YAML::Type)
      @serializations = Array(Serialization).new
      @data_type = case @spec
      when String
        parse_data_type(@spec)
      when Hash
        if type_spec = @spec.as(Hash)["type"]?
          parse_data_type(type_spec)
        end
      end.as(DataType|Nil)
      add_serializations
    end
    
    def parse_data_type(type_spec)
      data_type = case type_spec
      when String
        api.data_type(interpolate_variables type_spec)
      when Hash
        data_type = api.data_type(interpolate_variables(type_spec.as(Hash).first_key.as(String))).as(DataType)
        data_type.spec.deep_merge!(type_spec.as(Hash).first_value)
        data_type
      else
        nil
      end
      data_type.as(DataType) if data_type
    end
            
    def add_serializations
      @serializations = Serialization.parse(@resource, @spec, @data_type)
    end
    
    def api
      @resource.api
    end
    
    def parameters
      @resource.resource_type.parameters
    end

    
  end
  
  class Headers
    include CommonMethods
    
    getter :examples
    
    def initialize(@resource : Resource, @spec : YAML::Type)
    end
    
    def parameters
      @resource.resource_type.parameters
    end

    
  end

  
  class Serialization
    include CommonMethods
    
    def self.parse(resource, spec, data_type) : Array(self)
      serializations = Array(self).new
      case spec
      when String
        resource.api.default_serializations.each do |serialization|
          serializations << Serialization.new resource, serialization.to_s, Hash(YAML::Type, YAML::Type).new, data_type
        end
      when Hash
        if type = spec.as(Hash)["type"]?
          resource.api.default_serializations.each do |serialization|
            serializations << Serialization.new resource, serialization.to_s, spec.as(Hash), nil
          end
        else
          spec.as(Hash).each do |serialization, _spec|
            serializations << Serialization.new resource, serialization.to_s, _spec.as(Hash), data_type
          end
        end
      end
      serializations
    end

    
    getter :data_type, :resource, :format, :examples
    
    def initialize(@resource : Resource, @format : String, @spec : Hash(YAML::Type, YAML::Type), data_type : DataType|Nil)
      @examples = Example.parse(@spec)
      @data_type = DataType.new "Unknown", empty_hash
      if data_type
        @data_type = data_type.as(DataType)
      end
      parse_data_type
      @examples.concat Example.parse(@data_type.spec) if @data_type
    end
    
    def parse_data_type
      data_type = case @spec
      when String
        api.data_type(interpolate_variables @spec.as(String))
      when Hash
        if spec = @spec.as(Hash)["type"]?
          api.data_type(interpolate_variables spec.as(String))
        end
      end
      if data_type
        @data_type = data_type.as(DataType)
      end
    end
    
    def api
      @resource.api
    end
    
    def uri
      @resource.uri
    end
        
    def parameters
      @resource.resource_type.parameters
    end


  end
  
  class Example
    include CommonMethods
    
    def self.parse(spec) : Array(self)
      examples = Array(self).new
      case spec        
      when Hash
        if example = spec.as(Hash)["examples"]?
          example.as(Hash).each do |name, spec|
            examples << Example.new(spec.as(Hash))
          end
        end
        if example = spec.as(Hash)["example"]?
          examples << Example.new(example.as(Hash))
        end
      end
      examples
    end

    getter :value
    
    def initialize(@spec : YAML::Type)
      value = @spec.as(Hash)["value"]? || @spec
      @value = case value
      when String
        parameter?(value).to_s || value.to_s
      when Array
        value.to_pretty_json
      when Hash
        value.to_pretty_json
      else
        ""
      end.as(String)
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
    
    getter :property_sets, :examples
        
    def initialize(@request : Request, @spec : Hash(YAML::Type, YAML::Type) )
      @examples = Example.parse(@spec)
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