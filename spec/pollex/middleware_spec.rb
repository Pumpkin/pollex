require 'helper'
require 'pollex/middleware'

describe Pollex::Middleware do
  describe '#serve' do
    let(:path)        { "/#{slug}" }
    let(:slug)        { 'abc123' }
    let(:drop_class)  { double(:drop_class, new: drop) }
    let(:drop)        { double(:drop, file:      file,
                                      found?:    found,
                                      extension: extension,
                                      type:      drop_type) }
    let(:file)        { double(:file) }
    let(:extension)   { '.png' }
    let(:drop_type)   { 'image' }
    let(:found)       { true }
    let(:thumb_class) { double(:thumb_class, new: thumb) }
    let(:thumb)       { double(:thumb, success?: success, size: 42) }
    let(:success)     { true }
    subject { Pollex::Middleware.new(path).serve(drop_class, thumb_class) }

    context 'an image drop' do
      it 'creates a drop' do
        drop_class.should_receive(:new).with(slug)
        subject
      end

      it 'creates a thumbnail' do
        thumb_class.should_receive(:new).with(file, slug)
        subject
      end

      it 'serves the thumbnail' do
        expected = [ 200, { 'Content-Length' => '42' }, thumb ]
        expect(subject).to eq(expected)
      end
    end

    context 'a nonexistent drop' do
      let(:found) { false }

      it 'returns a not found response' do
        status, headers, body = subject
        expect(status).to eq(404)
        expect(headers).to eq('Content-Type' => 'text/html')
      end
    end

    context 'a non-image drop' do
      let(:extension) { '.txt' }
      let(:drop_type) { 'text' }

      it 'redirects to the icon' do
        expected = [ 307, { 'Location' => '/icons/text.png' }, [] ]
        expect(subject).to eq(expected)
      end
    end

    context 'an image drop with uppercase extension' do
      let(:extension) { '.JPG' }

      it 'serves the thumbnail' do
        expected = [ 200, { 'Content-Length' => '42' }, thumb ]
        expect(subject).to eq(expected)
      end
    end

    context 'an unknown file type' do
      let(:extension) { '' }
      let(:drop_type) { 'unknown' }

      it 'redirects to the icon' do
        expected = [ 307, { 'Location' => '/icons/unknown.png' }, [] ]
        expect(subject).to eq(expected)
      end
    end

    context 'an errant image' do
      let(:success) { false }

      it 'returns an error response' do
        status, headers, body = subject
        expect(status).to eq(500)
        expect(headers).to eq('Content-Type' => 'text/html')
      end
    end

    context 'a path containing a drop type' do
      let(:path) { "/image/#{slug}" }

      it 'finds the slug' do
        drop_class.should_receive(:new).with(slug)
        subject
      end
    end

    context 'a path containing a file name' do
      let(:path) { "/#{slug}/image.png" }

      it 'finds the slug' do
        drop_class.should_receive(:new).with(slug)
        subject
      end
    end

    context 'a path containing a drop type and file name' do
      let(:path) { "/image/#{slug}/image.png" }

      it 'finds the slug' do
        drop_class.should_receive(:new).with(slug)
        subject
      end
    end
  end
end
