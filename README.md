# OpenAPI 3 Parser


[![Build Status](https://travis-ci.org/kevindew/openapi3_parser.svg?branch=master)](https://travis-ci.org/kevindew/openapi3_parser)

This a Ruby based parser/validator for [OpenAPI 3][openapi-3]. It is used to
convert an OpenAPI file (can be a local file, a URL, a string or even a Ruby
hash) into an object graph with a simple API that follows the [OpenAPI
specification][openapi-3-spec].

Basic example:

```ruby
require "openapi3_parser"

document = Openapi3Parser.load_url("https://raw.githubusercontent.com/OAI/OpenAPI-Specification/master/examples/v3.0/petstore.yaml")

document.paths["/pets"].get.summary
# => "List all pets"
```

It aims to support 100% of the OpenAPI 3.0 specification, with key features
being:

- Supports loading a specification by path to a file, URL, Ruby file objects,
  and strings in YAML and JSON formats, it even supports loading via a Ruby hash;
- Support for loading references from external files including URLs;
- Handles recursive references;
- All of OpenAPI specification mapped to Ruby objects, providing a natural
  Ruby interface that maps clearly to the specification;
- OpenAPI files validated with a simple API to quickly and simply see all
  problems with a file
- Built-in Markdown to HTML conversion;
- Documentation for the API to navigate the OpenAPI nodes is available on
  [rubydoc.info][docs].

I've wrote a blog post reflecting on the decisions involved in building this
parser in [How to write an OpenAPI 3 parser][blog].

[openapi-3]: https://github.com/OAI/OpenAPI-Specification
[openapi-3-spec]: https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#specification
[docs]: http://www.rubydoc.info/github/kevindew/openapi3_parser/Openapi3Parser/Node/Openapi
[blog]: https://kevindew.me/post/188611423231/how-to-write-an-openapi-3-parser

## Usage

### Loading a specification

```ruby
# by URL
Openapi3Parser.load_url("https://raw.githubusercontent.com/kevindew/openapi3_parser/master/spec/support/examples/petstore-expanded.yaml")

# by path to file
Openapi3Parser.load_file("spec/support/examples/uber.yaml")

# by File
Openapi3Parser.load(File.open("spec/support/examples/uber.yaml"))

# by String
Openapi3Parser.load('{ "openapi": "3.0.0", "info": { "title": "API", "version": "1.0.0" }, "paths": {}  }')

# by Hash
Openapi3Parser.load(openapi: "3.0.0", info: { title: "API", version: "1.0.0" }, paths: {})

```

### Validating

```ruby
document = Openapi3Parser.load(openapi: "3.0.0", info: {}, paths: {})
document.valid?
# => false
document.errors
# => Openapi3Parser::Validation::ErrorCollection(errors: {"#/info"=>["Missing required fields: title and version"]})
```

### Traversing

```ruby
document = Openapi3Parser.load_url("https://raw.githubusercontent.com/kevindew/openapi3_parser/master/spec/support/examples/petstore-expanded.yaml")

# by objects

document.info.terms_of_service
# => "http://swagger.io/terms/"

document.paths.keys
# => ["/pets", "/pets/{id}"]

document.paths["/pets"].get.parameters.map(&:name)
# => ["tags", "limit"]

# by hash syntax

document["info"]["termsOfService"]
=> "http://swagger.io/terms/"

document["paths"].keys
# => ["/pets", "/pets/{id}"]

document["paths"]["/pets"]["get"]["parameters"].map(&:name)
# => ["tags", "limit"]

# by a path to a node
document.node_at("#/paths/%2Fpets/get/operationId")
=> "findPets"

document.node_at("#/components/schemas/Pet/allOf/0/required/0")
=> "name"

# or combining

document.components.schemas["Pet"].node_at("#../NewPet")
=> Openapi3Parser::Node::Schema(#/components/schemas/NewPet)
```

You can learn more about the API on [rubydoc.info][docs]

## Installation

You can install this gem into your bundler application by adding this line to
your Gemfile:

```
gem "openapi3_parser", "~> 0.8.0"
```

and then running `$ bundle install`

Or install the gem onto your machine via `$ gem install openapi3_parser`

## Status

This is currently a work in progress and will remain so until it reaches 1.0.

See [TODO](TODO.md) for details of the features still to implement.

## Licence

[MIT License](LICENCE)
