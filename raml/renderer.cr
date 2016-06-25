require "kilt/slang"
require "./api"

module RAML
      
  class Renderer
    
    getter :nav_tree, :api
        
    def initialize(@api : RAML::Api)
      @nav_tree = Hash(String, RAML::Api::TreeType).new
      parse_nav_tree("", @api.resources)
    end
    
    def render
      Kilt.render "./template/api.slang"
    end
    
    def api(name)
      @api.spec(name)
    end
    
    def write(path)
      html = render
      dir = File.dirname(path)
      Dir.mkdir_p(dir)
      File.write path, html
      copy_file dir, "js"
      copy_file dir, "css"
    end
    
    def copy_file(dir, extension)
      File.write File.join(dir, "api.#{extension}"), File.read(File.expand_path("../../template/api.#{extension}", __FILE__))
    end
    
    def parse_nav_tree(url : String, tree : Hash, root = @nav_tree)
      tree.each do |key, value|
        if key.to_s[0] == '/'
          old_url = url
          url += key
          if val = (value as Hash)["endpoint"]?
            (root as Hash)[url] = val
            parse_nav_tree(url, value as Hash, (root as Hash))
          else
            (root as Hash)[url] = Hash(String, RAML::Api::TreeType).new
            parse_nav_tree(url, value as Hash, (root as Hash)[url])
          end
          url = old_url
        end
      end
    end
          
    def html_id(*elements)
      elements.map do |element|
        element.downcase.tr("/{}.", "_")
      end.join("_")
    end
    
    def nav_class(resource)
      resource.class == RAML::Resource && (resource as RAML::Resource).endpoint? ? "endpoint" : "parent"
    end
            
  end
  
end