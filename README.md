# MMThumb [![Gem](http://img.shields.io/gem/v/mmthumb.svg)](https://rubygems.org/gems/mmthumb) [![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://www.rubydoc.info/github/drbig/mmthumb/master)

* [Homepage](https://github.com/drbig/)
* [Documentation](http://rubydoc.info/gems/mmthumb/frames)

## Description

MMThumb is a sane and simple but flexible approach to automating the common 
tasks of
processing images for use in webpages. If your image workflow includes applying:

  * Pre-Processing
    ...sharpen 2x2, normalize levels
  * Generating a couple of different outputs
    ...thumbnail, preview, full-view
  * Post-Processing
    ...watermark, vignette

Then this gem will serve you right.

This gem has been written with the intent that you should write minimal code
to do what you want, but it should not limit you - configuration options are
chained, so you can have sane defaults and still easily handle corner cases.

It has also been written with the intent to be usable both as an offline batch
processor or as an engine for a long-running service process - therefore the
approach to exception handling may be slightly different than usual.

Current version uses the [mini_magick](http://rubygems.org/gems/mini_magick) 
gem and therefore you will need either [ImageMagick](http://www.imagemagick.org/) 
or [GraphicsMagick](www.graphicsmagick.org). This, in my humble opinion, gives you
by default the best trade-off between performance and functionality.

**Performance note:**

Due to how `mini_magick` works the `preprocess` and `postprocess` blocks will be
called *for each* `output` block, contrary to the intuition that they should run
once each (before and after outputs, respectively). In other words right now they
are mostly a visual convenience to separate things.

## Install

Dependencies:

  * [ImageMagick](http://www.imagemagick.org/) or [GraphicsMagick](www.graphicsmagick.org)
  * [mini_magick](http://rubygems.org/gems/mini_magick)

Install:

    $ gem install mmthumb

## Examples

First my personal most-common-ever use-case, as a simple CLI batch converter:

    #!/usr/bin/env ruby
    # encoding: utf-8
    #
    
    require 'mmthumb'
    
    conv = MMThumb::Converter.new
    conv.preprocess do |img, opts|
      if opts[:photo]
        img.normalize
        img.sharpen '2x2'
      end
    end
    conv.add_output(:thumb) {|img| img.resize('320x240>') }
    conv.add_output(:full)  {|img| img.resize('1024x768>') }
    
    ARGV.each do |path|
      puts path
    
      ext = File.extname(path).slice(1, 4).downcase
      ext = 'jpg' if ext == 'jpeg'
      opts = {
        :format => ext,
        :photo => ext == 'jpg',
      }
    
      begin
        res = conv.convert(path, opts)
      rescue MMThumb::Error => e
        STDERR.puts "ERROR: #{e}"
      else
        res.each do |key, info|
          if info[:done]
            puts info[:path]
          else
            STDERR.puts "ERROR: (#{key}) #{info[:error]}"
          end
        end
    
        File.delete(path) if res.values.all? {|e| e[:done] }
      end
    end

You can use everything `mini_magick` has to offer:

    # Configure
    conv = MMThumb::Converter.new
    conv.preprocess do |img|
      img.normalize
      img.sharpen '2x2'
    end
    conv.add_output(:thumb) do |img|
      img.resize '160x160>'
      img.vignette '2x3+2+2'
    end
    conv.add_output(:preview) do |img|
      img.resize '320x256>'
    end
    conv.add_output(:full) do |img|
      img.resize '1920x1080>'
      img.draw 'text 10, 10 "(C) Website"'
    end

Options are both chained and available for you inside the blocks:

    @conv = MMThumb::Converter.new(:path => '/static/assets')
    @conv.preprocess do |img, opts|
      img.sharpen '2x2' if opts[:photo]
    end
    @conv.add_output(:full) do |img, opts|
      img.resize '1920x1080>'
      img.draw "text 10,10 '(C) #{opts[:user]}'"
    end
    
    batch.each do |path, user|
      ext = File.extname(path).slice(1, 4).downcase
      ext = 'jpg' if ext == 'jpeg'
    
      opts = {
        :format => ext,
        :photo => ext == 'jpg',
        :user => user.fullname,
        :prefix => user.id,
      }
    
      res = @conv.convert(path, opts)
      if res.values.all? {|e| e[:done] }
        File.delete(path)
      else
        log :error, "Processing #{path} for #{user}"
        res.values.select {|e| e[:done] }.each {|e| File.delete(e[:path]) }
      end
    end

## Testing

I've included a rather large (2.3 MB) JPEG file for tests.

When you run `rake spec` a number of test images will be generated and left
in the `spec` folder, so that you can visually inspect that everything works
as advertised. These images are deleted before tests are run, but if you want
to clean them afterwards there is the `rake clean` task.

I believe the test don't cover everything, but they are helpful nonetheless.

*Trivia:* The box of [floppy disks](http://en.wikipedia.org/wiki/Floppy_disk) is about 
140 MB (or 172 MB if you use an [Amiga](http://en.wikipedia.org/wiki/Amiga_1200)). 
It weights a couple kg.

## Possible TODO

  * Add support for other converters (speed vs. functionality)
  * Make `pre` and `post` blocks run only once per image

## Copyright

Copyright (c) 2014 Piotr S. Staszewski

See {file:LICENSE.txt} for details.
