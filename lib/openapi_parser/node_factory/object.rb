# frozen_string_literal: true

require "openapi_parser/node_factory"
require "openapi_parser/node_factory/field_config"
require "openapi_parser/node_factory/object/node_builder"
require "openapi_parser/node_factory/object/validator"

module OpenapiParser
  module NodeFactory
    module Object
      include NodeFactory

      module ClassMethods
        def field(name, **options)
          @field_configs ||= {}
          @field_configs[name] = FieldConfig.new(options)
        end

        def field_configs
          @field_configs || {}
        end

        def allow_extensions
          @allow_extensions = true
        end

        def disallow_extensions
          @allow_extensions = false
        end

        def allowed_extensions?
          @allow_extensions == true
        end
      end

      def self.included(base)
        base.extend(NodeFactory::ClassMethods)
        base.extend(ClassMethods)
        base.class_eval do
          input_type Hash
        end
      end

      def allowed_extensions?
        self.class.allowed_extensions?
      end

      def field_configs
        self.class.field_configs || {}
      end

      private

      def process_input(input)
        field_configs.each_with_object(input.dup) do |(field, config), memo|
          next if !config.factory? || !memo[field]
          next_context = context.next_namespace(field)
          memo[field] = config.initialize_factory(
            next_context, self
          )
        end
      end

      def validate_input(error_collection)
        super(error_collection)
        validator = Validator.new(processed_input, self)
        error_collection.tap { |ec| ec.append(*validator.errors) }
      end

      def build_node(input)
        data = NodeBuilder.new(input, self).data
        build_object(data, context)
      end

      def build_object(data, _context)
        data
      end
    end
  end
end