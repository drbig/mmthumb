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
