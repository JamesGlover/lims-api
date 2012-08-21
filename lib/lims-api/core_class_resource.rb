require 'lims-core'
require 'lims-api/json_encoder'
require 'lims-api/json_decoder'

require 'lims-api/resource'

module Lims
  module Api
    class CoreClassResource
      include Resource

      attr_reader :name, :model

      # @param [Class] model underlying model, part of the core
      # @param [String] name used to generate url
      def initialize(context, model, name)
        @model = model
        @name = name
        super(context)
      end

      def actions
        %w[create read first last] 
      end

      #==================================================
      # Actions
      #==================================================

      create_action(:reader) do |session|
        self
      end



      # Move in Json encoder
      #create_action(:creator) do |session, attributes|
      def creator(attributes)
        lambda do 
          action = model::Create.new( :store => @context.store) do |a, session|
            recursively_load_uuid(attributes, session) .each do |k,v|
              a[k] = v
            end
          end
          r = @context.execute_action(action)
          uuid = r.delete(:uuid)
          type = r.keys.first
          object = r[type]
          @context.resource_for(object, type, uuid)
        end
      end


      #==================================================
      # Encoders
      #==================================================

      # Specific encoder
      module  Encoder
        include Resource::Encoder
        def to_struct
          {
            object.name => {
            :actions => object.actions.mash { |a| [a, url_for_action(a)] }
          }}
        end

        def url_for_action(action)
          url_for(
            case action
            when "first" then "#{object.name}?page=1"
            when "last" then "#{object.name}?page=-1"
            when "read", "create" then "#{object.name}"
            else
              "#{object.name}/#{action}"
        end
        )
        end
      end

      Encoders = [
        class JsonEncoder
          include Encoder
          include Lims::Api::JsonEncoder
        end
      ]
      def self.encoder_class_map 
        @encoder ||= Encoders.mash { |k| [k::ContentType, k] }
      end

      #==================================================
      # Decoders
      #==================================================

      # Specific decoder
      module  Decoder
        include Resource::Decoder
        def to_struct
          {
            object.name => {
            :actions => object.actions.mash { |a| [a, url_for_action(a)] }
          }}
        end

        def url_for_action(action)
          url_for("#{object.name}/#{action}")
            end
        end

        Decoders = [
          class JsonDecoder
            include Decoder
            include Lims::Api::JsonDecoder
          end
        ]
        def self.decoder_class_map 
          @decoder ||= Decoders.mash { |k| [k::ContentType, k] }
        end
      end
    end
  end
