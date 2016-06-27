require "./test_helper"
require "../raml/parser"
require "../raml/api"

class VariablesTest < Minitest::Test

  def setup
    @api = load_parser("test_variables").api as RAML::Api
  end
  
  def api : RAML::Api
    @api as RAML::Api
  end
  
  def resource(url)
    api.all_resources[url]
  end

  
  def resource
    resource("/books")
  end

  def test_var_resp_type_query_parameters
    resource.requests.each do |request|
      assert request.query_parameters.as(Hash).has_key? "title"
      assert request.query_parameters.as(Hash).has_key? "digest_all_fields"
    end
  end
  
  def test_var_resp_type_description
    params = resource.requests[0].query_parameters.as(Hash)
    title_descr = "Return books that have their title matching the given value"
    assert_equal title_descr, params["title"].as(Hash)["description"]
    fb_descr = "If no values match the value given for title, use digest_all_fields instead"
    assert_equal fb_descr, params["digest_all_fields"].as(Hash)["description"]
  end

  def test_var_traits_query_parameters
    resource.requests.each do |request|
      assert request.query_parameters.as(Hash).has_key? "access_token"
      assert request.query_parameters.as(Hash).has_key? "numPages"
    end
  end
  
  def test_var_traits_description
    params = resource.requests[0].query_parameters.as(Hash)
    access_token_descr = "A valid access_token is required"
    assert_equal access_token_descr, params["access_token"].as(Hash)["description"]
    num_pages_descr = "The number of pages to return, not to exceed 10"
    assert_equal num_pages_descr, params["numPages"].as(Hash)["description"]
  end


  
end
