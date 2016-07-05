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
      @api.directive_spec(name)
    end
    
    def write_file(content, path)
      dir = File.dirname(path)
      Dir.mkdir_p(dir)
      File.write path, content
    end
    
    def write(path)
      html = render
      write_file html, path
      copy_file path, "js"
      copy_file path, "css"
    end
    
    def bundle(path)
      html = render
      js = File.read(File.expand_path("../../template/api.js", __FILE__))
      css = File.read(File.expand_path("../../template/api.css", __FILE__))
      html = html.sub "<script src=\"api.js\" type=\"text/javascript\"></script>", "<script type=\"text/javascript\">\n#{js}\n</script>"
      html = html.sub "<link rel=\"stylesheet\" href=\"api.css\">", "<style>\n#{css}\n</style>"
      write_file html, path
    end
    
    def copy_file(path, extension)
      dir = File.dirname(path)
      File.write File.join(dir, "api.#{extension}"), File.read(File.expand_path("../../template/api.#{extension}", __FILE__))
    end
    
    def parse_nav_tree(url : String, tree : Hash, root = @nav_tree)
      tree.each do |key, value|
        if key.to_s[0] == '/'
          old_url = url
          url += key
          if val = value.as(Hash)["endpoint"]?
            root.as(Hash)[url] = val
            parse_nav_tree(url, value.as(Hash), root.as(Hash))
          else
            root.as(Hash)[url] = Hash(String, RAML::Api::TreeType).new
            parse_nav_tree(url, value as Hash, root.as(Hash)[url])
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
      resource.class == RAML::Resource && resource.as(RAML::Resource).endpoint? ? "endpoint" : "parent"
    end
            
  end
  
end