# frozen_string_literal: false
require 'rss/2.0'

module RSS
  PODCAST_PREFIX = 'podcast'
  PODCAST_URI = 'https://podcastindex.org/namespace/1.0'

  Rss.install_ns(PODCAST_PREFIX, PODCAST_URI)

  module PodcastModelUtils
    include Utils

    def def_class_accessor(klass, name, type, *args)
      normalized_name = name.gsub(/-/, "_")
      full_name = "#{PODCAST_PREFIX}_#{normalized_name}"
      klass_name = "Podcast#{Utils.to_class_name(normalized_name)}"

      case type
      when :element, :attribute
        klass::ELEMENTS << full_name
        def_element_class_accessor(klass, name, full_name, klass_name, *args)
      when :elements
        klass::ELEMENTS << full_name
        def_elements_class_accessor(klass, name, full_name, klass_name, *args)
      else
        klass.install_must_call_validator(PODCAST_PREFIX, PODCAST_URI)
        klass.install_text_element(normalized_name, PODCAST_URI, "?",
                                   full_name, type, name)
      end
    end

    def def_element_class_accessor(klass, name, full_name, klass_name,
                                   recommended_attribute_name=nil)
      klass.install_have_child_element(name, PODCAST_PREFIX, "?", full_name)
    end

    def def_elements_class_accessor(klass, name, full_name, klass_name,
                                    plural_name, recommended_attribute_name=nil)
      full_plural_name = "#{PODCAST_PREFIX}_#{plural_name}"
      klass.install_have_children_element(name, PODCAST_PREFIX, "*",
                                          full_name, full_plural_name)
    end
  end

  module PodcastBaseModel
    extend PodcastModelUtils

    ELEMENT = []

    ELEMENT_INFOS = [
                      ['person', :elements, 'people', :element],
                      ['location', :element],
                      ['license', :element],
                      # ['value'], # this is the crypto currency thing that requires special attention
                      ['images', :attribute, 'srcset'],
                      ['txt', :elements, 'txts', :element]
                    ]

    class PodcastPerson < Element
      include RSS09

      DEFAULT_ROLE = 'host'
      DEFAULT_GROUP = 'cast'

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['role', '', false],
        ['group', '', false],
        ['img', '', false],
        ['href', '', false],
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      content_setup

      alias name content

      def initialize(*args)
        super

        @role = DEFAULT_ROLE if @role.nil? || @role.empty?
        @group = DEFAULT_GROUP if @group.nil? || @group.empty?
      end
    end

    class PodcastLocation < Element
      include RSS09

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['geo', '', false],
        ['osm', '', false]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      content_setup
    end

    class PodcastLicense < Element
      include RSS09

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['url', '', false]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      content_setup
    end

    class PodcastImages < Element
      include RSS09

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['srcset', '', true]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end
    end

    class PodcastTxt < Element
      include RSS09

      MAX_PURPOSE_LENGTH = 128

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['purpose', '', false]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      content_setup

      def purpose=(value)
        if do_validate && !value.nil? && !value.empty? && value.length > MAX_PURPOSE_LENGTH
          raise ArgumentError, "invalid purpose: expected length <= #{MAX_PURPOSE_LENGTH} but was #{value.length}"
        end

        @purpose = value
      end
    end
  end

  module PodcastChannelModel
    extend BaseModel
    extend PodcastModelUtils
    include PodcastBaseModel

    ELEMENT = []

    class << self
      def append_features(klass)
        super

        return if klass.instance_of?(Module)
        ELEMENT_INFOS.each do |name, type, *additional_infos|
          def_class_accessor(klass, name, type, *additional_infos)
        end
      end
    end

    ELEMENT_INFOS = [
                      ['locked', :element],
                      ['funding', :element],
                      ['trailer', :elements, 'trailers', :element],
                      ['guid'],
                      ['medium'],
                      # ['liveItem', :elements, 'liveItems', :element], # requires sub-elements
                      ['block', :elements, 'blocks', :element],
                      # ['remoteItem'], # can bu used in multiple other elements
                      # ['podroll'], # requires sub-elements
                      ['updateFrequency', :element],
                      ['podping', :attribute, 'usesPodping']
                    ] + PodcastBaseModel::ELEMENT_INFOS


    class PodcastLocked < Element
      include RSS09

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['owner', '', false]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      content_setup

      yes_other_attr_reader(:content)

      alias value content?
      alias locked value
    end

    class PodcastPodping < Element
      include RSS09

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['usesPodping', '', true]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      boolean_writer(:usesPodping)

      alias uses_podping usesPodping
    end

    class PodcastFunding < Element
      include RSS09

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['url', '', true]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      uri_convert_attr_reader(:url)
      content_setup
    end

    class PodcastTrailer < Element
      include RSS09

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['url', '', true],
        ['pubdate', '', true],
        ['type', '', false],
        ['length', '', false],
        ['season', '', false]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      uri_convert_attr_reader(:url)
      date_writer(:pubdate, :rfc2822)
      integer_writer(:length)
      content_setup

      alias name content
    end

    class PodcastBlock < Element
      include RSS09

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['id', '', false]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      content_setup
      yes_other_attr_reader(:content)

      alias value content?
    end

    class PodcastUpdateFrequency < Element
      include RSS09

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['complete', '', false],
        ['dtstart', '', false],
        ['rrule', '', false]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      date_writer(:dtstart, :iso8601)
      boolean_writer(:complete)
      content_setup
    end
  end

  module PodcastItemModel
    extend BaseModel
    extend PodcastModelUtils
    include PodcastBaseModel

    ELEMENT_INFOS = [
                      ['transcript', :elements, 'transcripts', :element],
                      ['chapters', :element],
                      # ['soundbite', :elements, 'soundbites', :element],
                      ['season', :element],
                      ['episode', :element],
                      # ['alternateEnclosure', :elements, 'alternateEnclosures', :element],
                      ['socialInteract', :elements, 'socialInteracts', :element]
                    ] + PodcastBaseModel::ELEMENT_INFOS

    class << self
      def append_features(klass)
        super

        return if klass.instance_of?(Module)
        ELEMENT_INFOS.each do |name, type, *additional_infos|
          def_class_accessor(klass, name, type, *additional_infos)
        end
      end
    end

    class PodcastTranscript < Element
      include RSS09

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['url', '', true],
        ['type', '', true],
        ['language', '', false],
        ['rel', '', false]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      uri_convert_attr_reader(:url)
    end

    class PodcastChapters < Element
      include RSS09

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['url', '', true],
        ['type', '', true]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      uri_convert_attr_reader(:url)
    end

    class PodcastSeason < Element
      include RSS09

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['name', '', false]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      content_setup
      integer_writer(:content)

      alias number content
    end

    class PodcastEpisode < Element
      include RSS09

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['display', '', false]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      content_setup
      float_writer(:content)

      alias number content
    end

    class PodcastSocialInteract < Element
      include RSS09

      class << self
        def required_prefix
          PODCAST_PREFIX
        end

        def required_uri
          PODCAST_URI
        end
      end

      [
        ['url', '', true],
        ['protocol', '', true],
        ['accountId', '', false],
        ['accountUrl', '', false],
        ['priority', '', false]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      uri_convert_attr_reader(:url)
      uri_convert_attr_reader(:accountUrl)

      integer_writer(:priority)
    end
  end

  class Rss
    class Channel
      include PodcastChannelModel
      class Item; include PodcastItemModel; end
    end
  end

  element_infos =
    PodcastChannelModel::ELEMENT_INFOS + PodcastItemModel::ELEMENT_INFOS
  element_infos.each do |name, type|
    case type
    when :element, :elements, :attribute
      class_name = Utils.to_class_name(name)
      BaseListener.install_class_name(PODCAST_URI, name, "Podcast#{class_name}")
    else
      accessor_base = "#{PODCAST_PREFIX}_#{name.gsub(/-/, '_')}"
      BaseListener.install_get_text_element(PODCAST_URI, name, accessor_base)
    end
  end
end
