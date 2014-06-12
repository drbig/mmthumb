# encoding: utf-8
#

require 'mini_magick'
require 'mmthumb/version'

# See {file:README.md} for practical examples.
module MMThumb
  # Default output format
  FORMAT = 'jpg'
  # Default output JPEG quality
  QUALITY = '80'

  # MMThumb generated errors
  class Error < StandardError; end

  # See {file:README.md} for practical examples.
  # @attr config [Hash] Instance configuration
  class Converter
    attr_accessor :config

    # New converter
    #
    # For options see `setup`. The options you pass here will be 
    # preserved as defaults.
    #
    # @see #setup
    # @param config [Hash] Configuration options
    def initialize(config = {})
      @default = config
      setup
    end

    # Reset instance config to defaults
    #
    # @see #setup
    # @see #initialize
    # @return [Hash] Configuration options
    def reset!; setup; end

    # Add preprocess block
    #
    # The block will be executed before outputs.
    #
    # @return [Block] Given block
    def preprocess(&blk); @before = blk; end

    # Remove preprocess block
    #
    # @return [nil]
    def del_preprocess!; @before = nil; end

    # Check if preprocess block is present
    #
    # @return [Boolean]
    def preprocess?; @before ? true : false; end

    # Add postprocess block
    #
    # The block will be executed after outputs.
    #
    # @return [Block] Given block
    def postprocess(&blk); @after = blk; end

    # Remove postprocess block
    #
    # @return [nil]
    def del_postprocess!; @after = nil; end

    # Check if postprocess block is present
    #
    # @return [Boolean]
    def postprocess?; @after ? true : false; end

    # Add output
    #
    # @see #setup
    # @param key [Symbol, String] Unique key for the output
    # @param opts [Hash] Configuration options
    # @param block [Block] Code for the output
    def add_output(key, opts = {}, &block)
      @outputs[key] = [opts, block]
    end

    # Remove output
    #
    # @return [Array, nil]
    def del_output(key); @outputs.delete(key); end

    # Get outputs
    #
    # @return [Hash<Symbol, Array>]
    def outputs; @outputs; end

    # Convert image to given outputs
    #
    # Configuration options are chained and calculated on each convert with
    # the following hierarchy: instance options - output options - convert
    # call options (this list is lowest-to-highest priority order). Thus you
    # can easily override any option.
    #
    # Will raise `Error` if given file is unreadable, it *won't* raise
    # exceptions on *any other errors*. Instead error information will
    # be returned with the result.
    #
    # The returned hash keys correspond to the output keys, and each
    # value will be another hash; which will contain either `:done => true`
    # and `:path => String` when successful, or `:done => false` and
    # `:error => Exception` if not.
    #
    # @see #setup
    # @param path [String] Path to file to convert
    # @param opts [Hash] Configuration options
    # @return [Hash<Symbol, Hash>] Results
    def convert(path, opts = {})
      return nil if @outputs.empty?

      input = File.absolute_path(path)
      raise Error, 'File is unreadable' unless File.readable? input

      res = Hash.new
      @outputs.each_pair do |key, (cfg, blk)|
        config = @config.merge(cfg).merge(opts)
        config[:path]     ||= File.dirname(input)
        config[:basename] ||= File.basename(path, File.extname(path))
        config[:suffix]   ||= '_' + key.to_s
        output = output_path(config)

        begin
          img = MiniMagick::Image.open(input)
          @before.call(img, config) if @before

          img.format(config[:format])
          blk.call(img, config) if blk

          @after.call(img, config) if @after

          img.quality(config[:quality])
          img.write(output)
        rescue StandardError => e
          res[key] = {
            :done => false,
            :error => e,
          }
        else
          res[key] = {
            :done => true,
            :path => output,
          }
        end
      end

      res
    end

    private

    # Setup instance
    #
    # You can keep any options you want inside the `@config` hash, but these
    # keys are used internally for:
    #
    #   * `:format` - output format as an extension without a dot (e.g. `'jpg'`)
    #   * `:quality` - string indicating JPEG quality (e.g. `'80'`)
    #   * `:path` - string indicating target directory
    #   * `:basename` - basename of the output file
    #   * `:prefix` - prefix to add to the output filename
    #   * `:suffix` - suffix to add to the output filename
    #
    # If `:path => nil` then outputs will be saved in the directory where the 
    # source file is located.
    #
    # If `:basename => nil` then the source file basename will be used.
    #
    # If `:suffix => nil` then the `:key` of the output will be added (after an 
    # `_`) to the output filename.
    #
    # @return [Hash] Configuration options
    def setup
      @before = nil
      @outputs = Hash.new
      @after = nil

      @config = {
        :format => FORMAT,
        :quality => QUALITY,
        :path => nil,
        :prefix => '',
      }.merge!(@default)
    end

    # Calculate output path
    #
    # @see #setup
    # @param opts [Hash] Configuration options
    # @return [String] Full output file path
    def output_path(opts)
      File.join(opts[:path], opts[:prefix] +\
                opts[:basename] +\
                opts[:suffix] + '.' +\
                opts[:format])
    end
  end
end
