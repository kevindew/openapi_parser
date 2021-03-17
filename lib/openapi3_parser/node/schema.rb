# frozen_string_literal: true

require "openapi3_parser/node/object"

module Openapi3Parser
  module Node
    # @see https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#schemaObject
    # rubocop:disable Metrics/ClassLength
    class Schema < Node::Object
      # This is used to provide a name for the schema based on it's position in
      # an OpenAPI document.
      #
      # For example it's common to have an OpenAPI document structured like so:
      # components:
      #   schemas:
      #     Product:
      #       properties:
      #         product_id:
      #           type: string
      #         description:
      #           type: string
      #
      # and there is then implied meaning in the field name of Product, ie
      # that schema now represents a product. This data is not easily or
      # consistently made available as it is part of the path to the data
      # rather than the data itself. Instead the field that would be more
      # appropriate would be "title" within a schema.
      #
      # As this is a common pattern in OpenAPI docs this provides a method
      # to look up this contextual name of the schema so it can be referenced
      # when working with the document, it only considers a field to be
      # name if it is within a group called schemas (as is the case
      # in #/components/schemas)
      #
      # @return [String, nil]
      def name
        segments = node_context.source_location.pointer.segments
        segments[-1] if segments[-2] == "schemas"
      end

      # @return [String, nil]
      def title
        self["title"]
      end

      # @return [Numeric, nil]
      def multiple_of
        self["multipleOf"]
      end

      # @return [Integer, nil]
      def maximum
        self["maximum"]
      end

      # @return [Boolean]
      def exclusive_maximum?
        self["exclusiveMaximum"]
      end

      # @return [Integer, nil]
      def minimum
        self["minimum"]
      end

      # @return [Boolean]
      def exclusive_minimum?
        self["exclusiveMinimum"]
      end

      # @return [Integer, nil]
      def max_length
        self["maxLength"]
      end

      # @return [Integer]
      def min_length
        self["minLength"]
      end

      # @return [String, nil]
      def pattern
        self["pattern"]
      end

      # @return [Integer, nil]
      def max_items
        self["maxItems"]
      end

      # @return [Integer]
      def min_items
        self["minItems"]
      end

      # @return [Boolean]
      def unique_items?
        self["uniqueItems"]
      end

      # @return [Integer, nil]
      def max_properties
        self["maxProperties"]
      end

      # @return [Integer]
      def min_properties
        self["minProperties"]
      end

      # @return [Node::Array<String>, nil]
      def required
        self["required"]
      end

      # Returns whether a property is a required field or not. Can accept the
      # property name or a schema
      #
      # @param [String, Schema] property
      # @return [Boolean]
      def requires?(property)
        if property.is_a?(Schema)
          # compare node_context of objects to ensure references aren't treated
          # as equal - only direct properties of this object will pass.
          properties.to_h
                    .select { |k, _| required.to_a.include?(k) }
                    .any? { |_, schema| schema.node_context == property.node_context }
        else
          required.to_a.include?(property)
        end
      end

      # @return [Node::Array<Object>, nil]
      def enum
        self["enum"]
      end

      # @return [String, nil]
      def type
        self["type"]
      end

      # @return [Node::Array<Schema>, nil]
      def all_of
        self["allOf"]
      end

      # @return [Node::Array<Schema>, nil]
      def one_of
        self["oneOf"]
      end

      # @return [Node::Array<Schema>, nil]
      def any_of
        self["anyOf"]
      end

      # @return [Schema, nil]
      def not
        self["not"]
      end

      # @return [Schema, nil]
      def items
        self["items"]
      end

      # @return [Map<String, Schema>]
      def properties
        self["properties"]
      end

      # @return [Boolean]
      def additional_properties?
        self["additionalProperties"] != false
      end

      # @return [Schema, nil]
      def additional_properties_schema
        properties = self["additionalProperties"]
        return if [true, false].include?(properties)

        properties
      end

      # @return [String, nil]
      def description
        self["description"]
      end

      # @return [String, nil]
      def description_html
        render_markdown(description)
      end

      # @return [String, nil]
      def format
        self["format"]
      end

      # @return [Any]
      def default
        self["default"]
      end

      # @return [Boolean]
      def nullable?
        self["nullable"]
      end

      # @return [Discriminator, nil]
      def discriminator
        self["discriminator"]
      end

      # @return [Boolean]
      def read_only?
        self["readOnly"]
      end

      # @return [Boolean]
      def write_only?
        self["writeOnly"]
      end

      # @return [Xml, nil]
      def xml
        self["xml"]
      end

      # @return [ExternalDocumentation, nil]
      def external_docs
        self["externalDocs"]
      end

      # @return [Any]
      def example
        self["example"]
      end

      # @return [Boolean]
      def deprecated?
        self["deprecated"]
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
