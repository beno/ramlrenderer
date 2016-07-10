html
  head
    title ==api("title")
    link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css"
    link rel="stylesheet" href="api.css"
    script src="https://code.jquery.com/jquery-2.2.4.min.js" type="text/javascript"
    script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js" type="text/javascript"
    script src="api.js" type="text/javascript"
  body
    .container
      .row
        .col-md-12
          .page-header
            h1
              ==api("title")
              small
                | version 
                ==api("version")
            p ==api("description")
      .row
        .col-md-3
          ul
            - nav_tree.each do |uri, value|
              - nav_cl = nav_class(value)
              - if  nav_cl == "endpoint"
                li class=nav_class(value)
                  a.endpoint onclick=="toggleNav(this, '#{html_id((value as RAML::Resource).uri)}')"
                    ==uri
                    span.pull-right
                      - (value as RAML::Resource).requests.each do |rq|
                        span.badge =rq.verb
              - if  nav_cl == "parent"
                li class=nav_class(value)
                  a href="##{html_id(uri)}" data-toggle="collapse"
                    ==uri
                  - if value.is_a? Hash
                    ul.collapse.in id=html_id(uri)
                      - value.each do |uri, resource|
                        li class=nav_class(resource)
                          a.endpoint onclick=="toggleNav(this, '#{html_id((resource as RAML::Resource).uri)}')"
                            ==uri
                            span.pull-right
                              - (resource as RAML::Resource).requests.each do |rq|
                                span.badge =rq.verb
        .col-md-9
          - api.all_resources.each do |uri, r|
            .resource.collapse id==html_id(r.uri)
              .requests
                - r.requests.each do |rq|
                  .request
                    h3
                      =="#{rq.verb.upcase} #{r.uri}"
                      small.description ==rq.spec("description")
                    ul.nav.nav-tabs role="tablist"
                      - id = "#{html_id(r.uri)}_#{rq.verb}"
                      li role="presentation"
                        a href="##{id}_request" aria-controls="#{id}_request" role="tab" data-toggle="tab" Request
                      li role="presentation"
                        a href="##{id}_responses" aria-controls="#{id}_responses" role="tab" data-toggle="tab" Responses
                    .clearfix
                    .tab-content
                      .tab-pane role="tabpanel" id="#{id}_request"
                        - if rq.headers.any?
                          h5 Headers
                          ul
                          - (rq.headers as Hash).each do |name, spec|
                            li
                              .property
                                span.prop_name ==name
                                span.prop_type ==type_declaration(spec) 
                                span.description ==spec.as(Hash)["description"]? || ""
                                - if spec.as(Hash)["example"]?
                                  span.example ==spec.as(Hash)["example"]
                        - if rq.uri_parameters.any?
                          h5 URI Parameters
                          ul
                          - rq.uri_parameters.as(Hash).each do |name, spec|
                            li
                              .property
                                span.prop_name ==name
                                span.prop_type ==type_declaration(spec) 
                                span.description ==spec.as(Hash)["description"]? || ""
                                - if spec.as(Hash)["example"]?
                                  span.example ==spec.as(Hash)["example"]
                        - if rq.query_parameters.any?
                          h5 Query Parameters
                          ul
                          - rq.query_parameters.as(Hash).each do |name, spec|
                            li
                              .property
                                span.prop_name ==name
                                span.prop_type ==type_declaration(spec) 
                                span.description ==spec.as(Hash)["description"]? || ""
                                - if spec.as(Hash)["example"]?
                                  span.example ==spec.as(Hash)["example"]
                        - if rq.query_string.as(RAML::QueryString).property_sets.any?
                          h5 Query String
                          - rq.query_string.as(RAML::QueryString).property_sets.each do |properties|
                            ul
                            - properties.each do |name, spec|
                              li
                                .property
                                  span.prop_name ==name
                                  span.prop_type ==type_declaration(spec)
                          span.description ==rq.query_string.as(RAML::QueryString).spec("description") || ""
                          - if rq.query_string.as(RAML::QueryString).spec("examples")
                            span.example ==rq.query_string.as(RAML::QueryString).spec("examples")

                      .tab-pane role="tabpanel" id="#{id}_responses"
                        - rq.responses.each do |resp|
                          h4
                            ==resp.code
                            small.description ==resp.spec("description")
                          ul 
                            - resp.media_types.each do |mime, media_type|
                              li
                                span.media-type
                                  ==mime + ": "
                                a href="##{html_id(r.uri, resp.code, media_type.data_type.name)}" data-toggle="collapse"
                                  span.data-type == media_type.data_type.name
                                .collapse id="#{html_id(r.uri, resp.code, media_type.data_type.name)}"
                                  .col-md-6
                                    h5 Properties
                                    - media_type.data_type.properties.each do |name,type|
                                      .property
                                        span.prop_name ==name
                                        span.prop_type ==type 
                                  .col-md-6
                                    h5 Example
                                    ==media_type.example
                                  .clearfix

                                
                               
  
                          

