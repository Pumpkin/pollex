require 'aws-sdk'

StoredFile = Struct.new(:file) do
  def connection
    @_connection ||= begin
      AWS::S3.new(
        :access_key_id      => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key  => ENV['AWS_SECRET_ACCESS_KEY']
      )
    end
  end

  def bucket
    ENV['BUCKET_NAME']
  end

  def item
    connection.buckets[bucket].objects[file]
  end

  def url
    item.url_for(:read).to_s
  end

  def exists?
    item.exists?
  end

  def create!(thumb)
    item.write(:file => File.open(thumb.path))
  end
end

