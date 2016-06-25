module RAML
  
  module ResourceTypeTraitsMethods
    
    def replace(variable)
      case variable
      when "resourcePath"
        url
      when "resourcePathName"
        url.split("/").last
      else
        variable
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
  
  module CommonMethods
    
    def empty_hash
      Hash(YAML::Type, YAML::Type).new
    end
    
    def empty_array
      Array(YAML::Type).new
    end
    
    def interpolate_directives(string : String)
      return string unless @spec.is_a? Hash
      string.scan(/\{([^\}]*)\}/).each do |match|
        if val = (@spec as Hash)[match[1]]?
          string = string.sub match[0], val
        end
      end
      string
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
      variable = replace variable
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
      
    def replace(variable)
      variable
    end
    
    def [](name)
      spec(name)
    end
        
    def spec(name)
      return name unless @spec.is_a? Hash
      if val = (@spec as Hash)[name]?
        case val
        when String
          interpolate_variables interpolate_directives(val)
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
        interpolate_variables spec.to_s
      when Hash
        if data_type = (spec as Hash)["type"]?
          _type(data_type)
        else
          _type((spec as Hash).first_key)
        end
      end
    end
    
  end

end