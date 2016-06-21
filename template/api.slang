html
  head
    title API Doc
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
              | API Doc
              small
                | version
                ==api.version
      .row
        .col-md-3
          ul
            - nav_tree.each do |url, value|
              li class=nav_class(value)
                a href="##{html_id(url)}" data-toggle="collapse"
                  ==url
                - if value.is_a? Hash
                  ul.collapse.in id=html_id(url)
                    - value.each do |url, resource|
                      li class=nav_class(resource)
                        a.endpoint onclick="toggleNav(this, '#{html_id((resource as RAML::Resource).url)}')"
                          ==url
                          span.pull-right
                            - (resource as RAML::Resource).requests.each do |rq|
                              span.badge =rq.verb

        .col-md-9
          - resources.each do |r|
            .resource id=html_id(r.url) style="display: none;"
              .requests
                - r.requests.each do |rq|
                  .request
                    h4
                      =="#{rq.verb.upcase} #{r.url}"
                    p ==rq.description
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
                        - rq.queryParameters.each do |name, type|
                          li
                            span.name ==name
                            span.type ==type
                      .tab-pane role="tabpanel" id="#{id}_responses"
                        - rq.responses.each do |resp|
                          h5 ==resp.code
                          p ==resp.description
                          ul 
                            - resp.body.each do |mime, body|
                              li
                                == mime
                                ul
                                  - (body as Hash).each do |k, v|
                                    li
                                      span.name ==k
                                      span.type ==v
  
                          

