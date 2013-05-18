require 'pollex/middleware'

describe Pollex::Middleware do
  describe '#serve' do
    let(:path)       { "/#{slug}" }
    let(:slug)       { 'abc123' }
    let(:downloader) { stub(:downloader, download: file) }
    let(:file)       { stub(:file) }
    let(:thumber)    { stub(:thumber, new: thumb) }
    let(:thumb)      { stub(:thumb, size: 42) }
    subject { Pollex::Middleware.new(path) }

    it 'downloads the drop' do
      downloader.should_receive(:download).with(slug)
      subject.serve(downloader, thumber)
    end

    it 'creates a thumb' do
      thumber.should_receive(:new).with(file, slug)
      subject.serve(downloader, thumber)
    end

    it 'serves the thumb' do
      response = [ 200, { 'Content-Length' => '42' }, thumb ]
      expect(subject.serve(downloader, thumber)).to eq(response)
    end
  end
end
