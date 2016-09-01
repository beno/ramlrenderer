html
  head
    title ==api("title")
    link rel="stylesheet" href="src/bootstrap.min.css"
    link rel="stylesheet" href="api.css"
    script src="src/jquery.min.js" type="text/javascript"
    script src="src/bootstrap.min.js" type="text/javascript"
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
                small
                  =="#{api("protocols")} #{api("baseUri")}"
                span ==api("description")
                a.small href="raml_spec.zip" [Download RAML]
      .row
        .col-md-3
          ul
            - nav_tree.each do |uri, value|
              - nav_cl = nav_class(value)
              - if  nav_cl == "endpoint"
                li class=nav_class(value)
                  span.pull-right
                    - (value as RAML::Resource).requests.each do |rq|
                      span.badge =rq.verb
                  a.endpoint onclick=="toggleNav(this, '#{html_id((value as RAML::Resource).uri)}')"
                    ==uri
              - if  nav_cl == "parent"
                li class=nav_class(value)
                  a href="##{html_id(uri)}" data-toggle="collapse"
                    ==uri
                  - if value.is_a? Hash
                    ul.collapse.in id=html_id(uri)
                      - value.each do |uri, resource|
                        li class=nav_class(resource)
                          span.pull-right
                            - (resource as RAML::Resource).requests.each do |rq|
                              span.badge =rq.verb
                          a.endpoint onclick=="toggleNav(this, '#{html_id((resource as RAML::Resource).uri)}')"
                            ==uri
        .col-md-9
          - api.all_resources.each do |uri, r|
            .resource.collapse id==html_id(r.uri)
              .requests
                - r.requests.each do |rq|
                  .request
                    a href="##{html_id(r.uri,rq.verb)}" data-toggle="collapse"
                      h3
                        =="#{rq.verb.upcase} #{r.uri}"
                        .description ==rq.spec("description")
                  .collapse id==html_id(r.uri,rq.verb)
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
                                span.prop_type ==property_name(name, spec) 
                                span.prop_type ==type_declaration(spec) 
                                span.description ==spec.as(Hash)["description"]? || ""
                                - if spec.as(Hash)["example"]?
                                  span.example =spec.as(Hash)["example"]
                        - if rq.uri_parameters.any?
                          h5 URI Parameters
                          ul
                          - rq.uri_parameters.as(Hash).each do |name, spec|
                            li
                              .property
                                span.prop_name ==property_name(name, spec)
                                span.prop_type ==type_declaration(spec) 
                                span.description ==spec.as(Hash)["description"]? || ""
                                - if spec.as(Hash)["example"]?
                                  span.example =spec.as(Hash)["example"]
                        - if rq.query_parameters.any?
                          h5 Query Parameters
                          ul
                          - rq.query_parameters.as(Hash).each do |name, spec|
                            li
                              .property
                                span.prop_name ==property_name(name, spec)
                                span.prop_type ==type_declaration(spec) 
                                span.description ==spec.as(Hash)["description"]? || ""
                                - if spec.as(Hash)["example"]?
                                  span.example =spec.as(Hash)["example"]
                        - if rq.query_string.as(RAML::QueryString).property_sets.any?
                          h5 Query String
                          - rq.query_string.as(RAML::QueryString).property_sets.each do |properties|
                            ul
                              - if rq.query_string.as(RAML::QueryString).property_sets.size > 1
                                li.option Option
                              - properties.each do |name, spec|
                                li
                                  .property
                                    span.prop_name ==property_name(name, spec)
                                    span.prop_type ==type_declaration(spec)
                          - rq.query_string.as(RAML::QueryString).examples.each do |example|
                            span.example =example
                          span.description ==rq.query_string.as(RAML::QueryString).spec("description") || ""
                        - if rq.body.serializations.any?
                          h5 Body
                          ul
                            - rq.body.serializations.each do |serialization|
                              li
                                span.media-type
                                  ==serialization.format
                                .properties
                                  .col-md-5
                                    h5 Properties
                                    - serialization.data_type.properties.each do |name,spec|
                                      .property
                                        span.prop_name ==property_name(name, spec)
                                        span.prop_type ==type_declaration(spec)
                                  .col-md-7
                                    h5 Example
                                    - serialization.examples.each do |example|
                                      pre =example.value
                                  .clearfix

                      .tab-pane role="tabpanel" id="#{id}_responses"
                        - rq.responses.each do |resp|
                          h5
                            | Status 
                            ==resp.code
                            .description ==resp.spec("description")
                          ul 
                            - resp.body.serializations.each do |serialization|
                              li
                                span.media-type
                                  ==serialization.format
                                .properties
                                  .col-md-5
                                    h5 Properties
                                    - serialization.data_type.properties.each do |name,spec|
                                      .property
                                        span.prop_name ==property_name(name, spec)
                                        span.prop_type ==type_declaration(spec)
                                  .col-md-7
                                    h5 Example
                                    - serialization.examples.each do |example|
                                      pre =example.value
                                  .clearfix

                                
                               
  
                          

