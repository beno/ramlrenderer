# RAMLRenderer
## HTML documentation builder for RAML 1.0

### Usage

#### Install

    $ crystal dep
    
#### Compile

    $ crystal compile ramlrenderer.cr

#### Run

    $ ./ramlrenderer -i api.raml -o docs.html   #with flags
    $ ./ramlrenderer api.raml > docs.html       #alternative
        
#### Develop

    $ crystal ramlrenderer.cr -- -i api.raml -o docs.html
    
    
#### Limitation

This is only a partial implementation so far. More to come.

Due to Crystal's macro implementation the template name has to be hard coded (./template/api.slang). So for different layouts, this file must be edited/replaced and the program must be recompiled.


#### Roadmap

The plan is to grow this into a fully compliant RAML 1.0 parser. Next steps:

- merge includes (done)
- merge resourceTypes & traits into resources (done)
- merge data types (done)
- interpolate <\<variables>> in resourceTypes, traits, etc (done)
- handle examples (done)
- handle headers (done)
- handle query strings (done)
- handle security setting
- error handling (done)
