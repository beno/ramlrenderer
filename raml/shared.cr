class String
  
  def singularize
    self.sub(/(.*)ies$/, "\\1y").sub(/(.*)s$/, "\\1")
  end

  def pluralize
    self.singularize.sub(/(.*[^y])$/, "\\1s").sub(/(.*)y$/, "\\1ies")
  end
    
end

class Hash
  
  def deep_merge(source)
    self.dup.deep_merge!(source)
  end
  
  def deep_merge!(source)
    case source
    when Hash
      source.each do |key, val|
        self[key] = if _val = self[key]?
          if val.is_a?(Hash) && _val.is_a?(Hash)
            _val.deep_merge!(val)
          else
            val
          end
        else
          val
        end
      end
    end
    self
  end
  
  def ensure_path!(path, separator = "/")
    hash = self
    path.split(separator).each do |part|
      next if part == ""
      part = "#{separator}#{part}"
      hash.as(Hash)[part] = typeof(self).new unless hash.as(Hash)[part]?
      hash = hash.as(Hash)[part]
    end
    hash.as(Hash)
  end

end

module RAML
  
  alias TreeType = String | Resource | Hash(String, TreeType)

  
  module Utils
    def empty_hash : Hash(YAML::Type, YAML::Type)
      Hash(YAML::Type, YAML::Type).new
    end
    
    def empty_array : Array(YAML::Type)
      Array(YAML::Type).new
    end
    
    def hash!(hash) : Hash
      raise ParseException.new("#{hash} is not a Hash") unless hash.is_a?(Hash)
      hash.as(Hash)
    end
    
    def array!(array) : Array
      raise ParseException.new("#{array} is not an Array") unless array.is_a?(Array)
      array.as(Array)
    end

  end
  
  module CommonMethods
    
    include Utils
                
    def uri
      ""
    end
    
    def parameters
      empty_hash
    end

    def parameter?(name)
      case name
      when "resourcePath"
        uri
      when "resourcePathName"
        parts = uri.split("/").reverse
        parts.find {|part| !part.match(/\{.*\}/) }
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
          variable.singularize
        when "!pluralize"
          variable.pluralize
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
    
    def spec
      @spec
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
    
    def x_data_type
      api.data_type(_type)
    end
        
    def _type(spec = @spec, level=0)
      case spec
      when String
        interpolate_variables(spec)
      when Hash
        if type = spec.as(Hash)["type"]?
          _type(type, level+1)
        elsif level > 0
          _type(spec.as(Hash).first_key)
        else
          ""
        end
      else
        ""
      end
    end
    
    

  end

end