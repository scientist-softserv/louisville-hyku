# OVERRIDE IIIFManifest v0.5.0: Add sequence['viewingHint'] = 'paged' to Sequences for two-page view

module IIIFManifest
  class ManifestBuilder
    class SequenceBuilder
      attr_reader :work, :canvas_builder_factory, :sequence_factory
      def initialize(work, canvas_builder_factory:, sequence_factory:)
        @work = work
        @canvas_builder_factory = canvas_builder_factory
        @sequence_factory = sequence_factory
      end

      def apply(manifest)
        manifest.sequences += [sequence] unless empty?
        manifest
      end

      def empty?
        sequence.canvases.empty?
      end

      private

        def canvas_builder
          canvas_builder_factory.from(work)
        end

        def sequence
          @sequence ||=
            begin
              sequence = sequence_factory.new
              sequence['@id'] ||= work.manifest_url + '/sequence/normal'
              sequence['rendering'] ||= populate_sequence_rendering
              # OVERRIDE: add viewingHint = paged for two page view
              sequence['viewingHint'] ||= 'paged'
              canvas_builder.apply(sequence)
              sequence
            end
        end

        def populate_sequence_rendering
          if work.respond_to?(:sequence_rendering)
            work.sequence_rendering.each(&:to_h)
          else
            []
          end
        end
    end
  end
end
