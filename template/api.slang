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
            - nav_tree.each do |url, value|
              - nav_cl = nav_class(value)
              - if  nav_cl == "endpoint"
                li class=nav_class(value)
                  a.endpoint onclick="toggleNav(this, '#{html_id((value as RAML::Resource).url)}')"
                    ==url
                    span.pull-right
                      - (value as RAML::Resource).requests.each do |rq|
                        span.badge =rq.verb
              - if  nav_cl == "parent"
                li class=nav_class(value)
                  a href="##{html_id(url)}" data-toggle="collapse"
                    ==url
                  - if value.is_a? Hash
                    ul.collapse.in id=html_id(url)
                      - value.each do |url, resource|
                        - p resource
                        li class=nav_class(resource)
                          a.endpoint onclick="toggleNav(this, '#{html_id((resource as RAML::Resource).url)}')"
                            ==url
                            span.pull-right
                              - (resource as RAML::Resource).requests.each do |rq|
                                span.badge =rq.verb

        .col-md-9
          - api.all_resources.each do |url, r|
            .resource.collapse id=html_id(r.url)
              .requests
                - r.requests.each do |rq|
                  .request
                    h4
                      =="#{rq.verb.upcase} #{r.url}"
                    p ==rq.spec("description")
                    ul.nav.nav-tabs role="tablist"
                      - id = "#{html_id(r.url)}_#{rq.verb}"
                      li role="presentation"
                        a href="##{id}_request" aria-controls="#{id}_request" role="tab" data-toggle="tab" Request
                      li role="presentation"
                        a href="##{id}_responses" aria-controls="#{id}_responses" role="tab" data-toggle="tab" Responses
                    .clearfix
                    .tab-content
                      .tab-pane role="tabpanel" id="#{id}_request"
                        h5 Query Parameters
                        ul
                        - (rq.query_parameters as Hash).each do |name, spec|
                          li
                            .property
                              span.prop_name ==name
                              span.prop_type ==(spec as Hash)["type"]? || "string" 
                              span.prop_description ==(spec as Hash)["description"]? || ""
                      .tab-pane role="tabpanel" id="#{id}_responses"
                        - rq.responses.each do |resp|
                          h3
                            ==resp.code
                            small ==resp.spec("description")
                          ul 
                            - resp.media_types.each do |mime, media_type|
                              li
                                span.media-type
                                  ==mime + ": "
                                a href="##{html_id(r.url + media_type.data_type.name)}" data-toggle="collapse"
                                  span.data-type == media_type.data_type.name
                                ul.collapse id="#{html_id(r.url + media_type.data_type.name)}"
                                  - media_type.data_type.properties.each do |name,type|
                                    .property
                                      span.prop_name ==name
                                      span.prop_type ==type 
                                
                               
  
                          

