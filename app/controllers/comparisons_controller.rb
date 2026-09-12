class ComparisonsController < ApplicationController
  MIN_QUOTES = 2
  MAX_QUOTES = 5
  MAX_UPLOAD_SIZE = 10.megabytes

  # `create` re-renders the form on a validation error, so it needs this too.
  before_action :set_max_quotes, only: %i[new create]

  # The one page: uploads on top, comparison underneath once it exists.
  def new
  end

  # Accepts the uploaded PDFs and starts a comparison. Responds with a Turbo
  # Stream so the panel appears under the uploads without leaving the page.
  def create
    @quotes = Array(params[:quotes]).compact_blank.map { |file| Quote.from_upload(file) }

    if (@error = upload_error(@quotes))
      return render :new, status: :unprocessable_entity
    end

    @comparison = Comparison.new(quotes: @quotes)
    @id = store(@comparison)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  # The comparison panel, polled by the page while the job runs.
  def show
    @id = params[:id]
    @comparison = fetch(@id) || expired_comparison
  end

  private
    def set_max_quotes
      @max_quotes = MAX_QUOTES
    end

    # Comparisons are held in memory and expire, so a polling frame can outlive
    # the result it is waiting for. Reported as a failure, which stops polling.
    def expired_comparison
      Comparison.new.tap do |comparison|
        comparison.error = "This comparison has expired. Upload the quotes again to run a new one."
        comparison.status = :failed
      end
    end

    def upload_error(quotes)
      if quotes.size < MIN_QUOTES
        "Please upload at least #{MIN_QUOTES} quotes."
      elsif quotes.size > MAX_QUOTES
        "You can compare up to #{MAX_QUOTES} quotes at a time."
      elsif !quotes.all?(&:pdf?)
        "Every file must be a PDF."
      elsif quotes.any? { |quote| quote.size > MAX_UPLOAD_SIZE }
        "Each file must be under #{MAX_UPLOAD_SIZE / 1.megabyte} MB."
      end
    end

    # Comparisons live in the process cache, not a database. They expire, and
    # they are not shared between containers.
    def store(comparison)
      SecureRandom.uuid.tap do |id|
        Rails.cache.write(cache_key(id), comparison, expires_in: 1.hour)
      end
    end

    def fetch(id)
      Rails.cache.read(cache_key(id))
    end

    def cache_key(id)
      "comparison/#{id}"
    end
end
