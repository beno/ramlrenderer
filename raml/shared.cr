#require "json"

module RAML
  
  module ResourceTypeTraitsMethods
    
    def deep_merge(source, target = @spec)
      case source
      when Hash
        source.each do |key, val|
          target.as(Hash)[key] = if _val = target[key]?
            if val.is_a?(Hash) && _val.is_a?(Hash)
              deep_merge(val, _val)
            else
              val
            end
          else
            val
          end
        end
        target
      end
    end
        
  end
  
  module CommonMethods
    
    def empty_hash : Hash(YAML::Type, YAML::Type)
      Hash(YAML::Type, YAML::Type).new
    end
    
    def empty_array : Array(YAML::Type)
      Array(YAML::Type).new
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
      return spec unless @spec.is_a? Hash
      spec.as(Hash)[name]?
    end
    
    def url
      ""
    end
    
    def parameters
      empty_hash
    end

    def parameter?(name)
      case name
      when "resourcePath"
        url
      when "resourcePathName"
        url.split("/").last
      else
        parameters[name]?
      end
    end
    
    def interpolate_variables(string : String)
      string.scan(/<<([^>]*)>>/).each do |match|
        string = string.sub match[0], process_variable(match[1])
      end
      string
    end
    
    def process_variable(variable)
      parts = variable.split("|").map {|v| v.strip}
      variable = parts.shift
      variable = (parameter?(variable) || variable).to_s
      parts.each do |operation|
        variable = case operation
        when "!singularize"
          variable.sub /(.*)s/, "\\1"
        when "!pluralize"
          variable.sub /(.*)s?/, "\\1s"
        when "!uppercase"
          variable.upcase
        when "!lowercase"	
          variable.downcase
        when "!lowercamelcase"
          variable.camelcase.sub {|c| c.downcase}
        when "!uppercamelcase"
          variable.camelcase
        when "!lowerunderscorecase"
          variable.underscore.downcase
        when "!upperunderscorecase"
          variable.underscore.upcase
        when "!lowerhyphencase"
          variable.underscore.downcase.tr "_", "-"
        when "!upperhyphencase"
          variable.underscore.upcase.tr "_", "-"
        else
          variable
        end
      end
      variable
    end
    
    def interpolate_hash(hash)
      new_hash = typeof(hash).new
      hash.each do |key, value|
        new_hash[interpolate_variables(key.as(String))] = case value
        when String
          interpolate_variables(value.as(String))
        when Hash
          interpolate_hash(value.as(Hash))
        end
      end
      new_hash
    end
      
    def replace(variable)
      variable
    end
    
    def [](name)
      spec(name)
    end
        
    def spec(name)
      return name unless @spec.is_a? Hash
      if val = @spec.as(Hash)[name]?
        case val
        when String
          interpolate_variables(val)
        else
          val
        end
      end
    end
    
    def _data_type
      api.data_type(_type)
    end
        
    def _type(spec = @spec)
      case spec
      when String
        interpolate_variables spec
      when Hash
        if data_type = spec.as(Hash)["type"]?
          _type(data_type)
        else
          _type(spec.as(Hash).first_key)
        end
      end
    end
    
  end

end