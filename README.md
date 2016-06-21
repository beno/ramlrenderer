# RAMLRenderer
## HTML documentation builder for RAML 1.0

### Usage

#### Install

    $ crystal dep
    
#### Run

    $ crystal compile ramlrenderer.cr
    $ ./ramlrenderer -i api.raml -o docs.html   #with flags
    $ ./ramlrenderer api.raml > docs.html       #alternative
    
or (dev):

    $ crystal ramlrenderer.cr -- -i api.raml -o docs.html
    
    
#### Limitation

This is only a partial implementation so far. More to come.

Due to Crystal's macro implementation the template name has to be hard coded (./template/api.slang). So for different layouts, this file must be edited/replaced.
