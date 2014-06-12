# encoding: utf-8
#

require 'spec_helper'
require 'mmthumb'

describe 'MMThumb' do
  it 'should have a VERSION constant' do
    expect(MMThumb::VERSION).to_not be_empty
    expect(MMThumb::VERSION).to be_a(String)
  end

  it 'should have a FORMAT constant' do
    expect(MMThumb::FORMAT).to_not be_empty
    expect(MMThumb::FORMAT).to be_a(String)
  end

  it 'should have a QUALITY constant' do
    expect(MMThumb::QUALITY).to_not be_empty
    expect(MMThumb::QUALITY).to be_a(String)
  end

  context 'Error' do
    it 'should be a subclass of StandardError' do
      expect(MMThumb::Error.new).to be_a(StandardError)
    end
  end

  context 'Converter' do
    before(:all) do
      @mmt = MMThumb::Converter.new
      @target = File.dirname(__FILE__)
      @test_image = File.join(@target, 'test.jpg')
      Dir.glob(File.join(@target, 'test_*')).each {|path| File.delete(path) }
    end

    it 'should accept preprocessing' do
      expect(@mmt.preprocess?).to be_false
      @mmt.preprocess {|img| img.sharpen '2x2' }
      expect(@mmt.preprocess?).to be_true
    end

    it 'should accept postprocessing' do
      expect(@mmt.postprocess?).to be_false
      @mmt.postprocess do |img|
        img.vignette '2x3+2+2'
        img.draw 'text 10,10 "TEST TEST TEST"'
      end
      expect(@mmt.postprocess?).to be_true
    end

    it 'should accept outputs' do
      @mmt.add_output(:thumb) do |img|
        img.resize('320x256>')
      end
      @mmt.add_output(:full) do |img|
        img.resize('1024x768>')
      end
      expect(@mmt.outputs.length).to eq 2
    end

    it 'should convert properly' do
      res = @mmt.convert(@test_image)
      res.each_value do |info|
        expect(info[:done]).to be_true
        expect(File.exists?(info[:path])).to be_true
      end
    end

    it 'should reset to defaults' do
      default = @mmt.reset!
      expect(default[:format]).to eq MMThumb::FORMAT
      expect(default[:quality]).to eq MMThumb::QUALITY
      expect(default[:prefix]).to eq ''
      expect(@mmt.preprocess?).to be_false
      expect(@mmt.postprocess?).to be_false
      expect(@mmt.outputs).to be_empty
    end

    it 'should correctly use options' do
      target = File.join(@target, 'test_changed_suffix.gif')

      @mmt.config[:format] = 'gif'
      @mmt.config[:prefix] = 'test_'
      @mmt.config[:basename] = 'changed'
      @mmt.config[:suffix] = '_suffix'

      @mmt.add_output(:test) {|img| img.resize('160x160>') }

      res = @mmt.convert(@test_image)
      expect(res[:test][:done]).to be_true
      expect(res[:test][:path]).to eq target
      expect(File.exists?(target)).to be_true
    end

    it 'should pass options to blocks' do
      @mmt.reset!
      @mmt.add_output(:named) do |img, opts|
        expect(opts[:text]).to eq 'This is a test'
        img.draw "text 10,10 '#{opts[:text]}'"
      end

      res = @mmt.convert(@test_image, :text => 'This is a test')
      expect(res[:named][:done]).to be_true
    end

    it 'should raise exception on unreadable file' do
      expect{ @mmt.convert('non_existent') }.to raise_error(MMThumb::Error)
    end

    it 'should not raise exceptions during processing' do
      @mmt.reset!
      @mmt.add_output(:broken) do |img|
        this_should_fail
      end

      res = @mmt.convert(@test_image)
      expect(res.values.length).to eq 1
      expect(res.values.any? {|e| e[:done] }).to be_false
      expect(res[:broken][:error]).to be_a(StandardError)
    end

  end
end
