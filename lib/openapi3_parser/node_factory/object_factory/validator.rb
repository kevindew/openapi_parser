# frozen_string_literal: true

require "forwardable"

require "openapi3_parser/array_sentence"
require "openapi3_parser/error"
require "openapi3_parser/validation/validatable"
require "openapi3_parser/validators/mutually_exclusive_fields"
require "openapi3_parser/validators/required_fields"
require "openapi3_parser/validators/unexpected_fields"

module Openapi3Parser
  module NodeFactory
    module ObjectFactory
      class Validator
        private_class_method :new
        attr_reader :factory, :validatable, :building_node

        def self.call(*args)
          new(*args).call
        end

        def initialize(factory, building_node)
          @factory = factory
          @building_node = building_node
          @validatable = Validation::Validatable.new(factory)
        end

        def call
          check_required_fields
          check_unexpected_fields
          check_mutually_exclusive_fields
          check_invalid_fields
          check_factory_validations
          validatable.collection
        end

        private

        def check_required_fields
          Validators::RequiredFields.call(
            validatable,
            required_fields: factory.required_fields,
            raise_on_invalid: building_node
          )
        end

        def check_unexpected_fields
          Validators::UnexpectedFields.call(
            validatable,
            allow_extensions: factory.allowed_extensions?,
            allowed_fields: factory.allowed_fields,
            raise_on_invalid: building_node
          )
        end

        def check_mutually_exclusive_fields
          Validators::MutuallyExclusiveFields.call(
            validatable,
            mutually_exclusive_fields: factory.mutually_exclusive_fields,
            raise_on_invalid: building_node
          )
        end

        def check_invalid_fields
          CheckInvalidFields.call(self)
        end

        def check_factory_validations
          CheckFactoryValidations.call(self)
        end

        class CheckInvalidFields
          extend Forwardable
          attr_reader :validator
          def_delegators :validator, :factory, :building_node, :validatable
          private_class_method :new

          def self.call(validator)
            new(validator).call
          end

          def initialize(validator)
            @validator = validator
          end

          def call
            factory.data.each do |name, field|
              # references can reference themselves and become in a loop
              next if in_recursive_loop?(field)
              has_factory_errors = handle_factory_checks(name)

              next if has_factory_errors || !field.respond_to?(:errors)

              # We don't add errors when we're building a node as they will
              # be raised when that child node is built
              validatable.add_errors(field.errors) unless building_node
            end
          end

          private

          def handle_factory_checks(name)
            field_errors = if factory.field_configs[name]
                             check_field(name, factory.field_configs[name])
                           end

            (field_errors || []).any?
          end

          def in_recursive_loop?(field)
            field.respond_to?(:in_recursive_loop?) && field.in_recursive_loop?
          end

          def check_field(name, field_config)
            return if factory.raw_input[name].nil?

            field_validatable = Validation::Validatable.new(
              factory,
              context: Context.next_field(factory.context, name)
            )

            valid_input_type = field_config.check_input_type(field_validatable,
                                                             building_node)

            if valid_input_type
              field_config.validate_field(field_validatable, building_node)
            end

            validatable.add_errors(field_validatable.errors)
            field_validatable.errors
          end
        end

        class CheckFactoryValidations
          private_class_method :new

          def self.call(validator)
            new.call(validator)
          end

          def call(validator)
            run_validations(validator)

            errors = validator.validatable.errors

            return if errors.empty? || !validator.building_node

            location_summary = errors.first.context.location_summary
            raise Error::InvalidData,
                  "Invalid data for #{location_summary}: "\
                  "#{errors.first.message}"
          end

          private

          def run_validations(validator)
            validator.factory.validations.each do |validation|
              if validation.respond_to?(:call)
                validation.call(validator.validatable)
              elsif validation.is_a?(Symbol)
                validator.factory.send(validation, validator.validatable)
              else
                raise Error::NotCallable, "expected a symbol or a callable"
              end
            end
          end
        end
      end
    end
  end
end
