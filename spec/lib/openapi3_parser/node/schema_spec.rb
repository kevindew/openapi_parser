# frozen_string_literal: true

RSpec.describe Openapi3Parser::Node::Schema do
  describe "#name" do
    it "returns the key of the context when the item is defined within components/schemas" do
      node_context = create_node_context(
        {},
        pointer_segments: %w[components schemas Pet]
      )
      instance = described_class.new({}, node_context)
      expect(instance.name).to eq "Pet"
    end

    it "returns nil when a schema is defined outside of components/schemas" do
      node_context = create_node_context(
        {},
        pointer_segments: %w[content application/json schema]
      )
      instance = described_class.new({}, node_context)
      expect(instance.name).to be_nil
    end
  end

  describe "#requires?" do
    let(:node) do
      input = {
        "type" => "object",
        "required" => %w[field_a],
        "properties" => {
          "field_a" => { "type" => "string" },
          "field_b" => { "type" => "string" }
        }
      }

      factory_context = create_node_factory_context(input)
      Openapi3Parser::NodeFactory::Schema
        .new(factory_context)
        .node(node_factory_context_to_node_context(factory_context))
    end

    context "when enquiring with a field name" do
      it "returns true when a field name is required" do
        expect(node.requires?("field_a")).to be true
      end

      it "returns false when a field name is not required" do
        expect(node.requires?("field_b")).to be false
      end
    end

    context "when enquiring with a schema object" do
      it "returns true when the schema is required" do
        expect(node.requires?(node.properties["field_a"])).to be true
      end

      it "returns false when the schema is not required" do
        expect(node.requires?(node.properties["field_b"])).to be false
      end
    end

    context "when comparing referenced schemas" do
      let(:node) do
        input = {
          "type" => "object",
          "required" => %w[field_a],
          "properties" => {
            "field_a" => { "$ref" => "#/referenced_item" },
            "field_b" => { "$ref" => "#/referenced_item" }
          }
        }

        document_input = {
          "referenced_item" => { "type" => "string" }
        }

        factory_context = create_node_factory_context(input, document_input: document_input)
        Openapi3Parser::NodeFactory::Schema
          .new(factory_context)
          .node(node_factory_context_to_node_context(factory_context))
      end

      it "returns true for the required reference field" do
        expect(node.requires?(node.properties["field_a"])).to be true
      end

      it "returns false for the reference field that isn't required" do
        expect(node.requires?(node.properties["field_b"])).to be false
      end
    end
  end
end
