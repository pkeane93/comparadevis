# One uploaded quote PDF. Held in memory for the life of a request or job —
# nothing is written to disk or persisted.
class Quote
  attr_reader :filename, :bytes
  attr_accessor :company

  def initialize(filename:, bytes:, company: nil)
    @filename = filename
    @bytes = bytes
    @company = company
  end

  # Builds from an ActionDispatch::Http::UploadedFile off the upload form.
  def self.from_upload(uploaded_file)
    new(filename: uploaded_file.original_filename, bytes: uploaded_file.read)
  end

  # Payload for an Anthropic document content block.
  def base64
    @base64 ||= Base64.strict_encode64(bytes)
  end

  def pdf?
    bytes.start_with?("%PDF-")
  end

  def size
    bytes.bytesize
  end

  # What to call this quote before the model has told us the company.
  def label
    company.presence || filename
  end
end
