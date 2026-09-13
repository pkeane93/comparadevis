class ComparisonsController < ApplicationController
  MIN_QUOTES = 2
  MAX_QUOTES = 5
  MAX_COMPARISONS_PER_DAY = 3

  # The API accepts 32 MB per request and base64 inflates by about a third,
  # so these are set well under it rather than at it.
  MAX_QUOTE_SIZE = 5.megabytes
  MAX_TOTAL_SIZE = 20.megabytes

  # `create` re-renders the form on a validation error, so it needs this too.
  before_action :set_max_quotes, :set_min_quotes, only: %i[new create]

  # Every comparison run costs Anthropic credits. Capped per IP instead of
  # gated behind a password, so anyone can try the demo — just not spam it.
  rate_limit to: MAX_COMPARISONS_PER_DAY, within: 1.day, only: :create, with: :rate_limited

  before_action :set_attempts_left, only: %i[new create]

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
    @id = Comparison.store(@comparison)

    ComparisonJob.perform_later(@id, params[:description].to_s)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  # The comparison panel, polled by the page while the job runs.
  def show
    @id = params[:id]
    @comparison = Comparison.find(@id) || expired_comparison
  end

  private
    def set_max_quotes
      @max_quotes = MAX_QUOTES
    end

    def set_min_quotes
      @min_quotes = MIN_QUOTES
    end

    def rate_limited
      @error = "You've reached the limit of #{MAX_COMPARISONS_PER_DAY} comparisons per day from this connection. Try again tomorrow."
      # A before_action that renders halts the chain, so the later
      # set_attempts_left never runs on this path — compute it directly.
      set_attempts_left
      render :new, status: :too_many_requests
    end

    # Rails' rate_limit macro keeps no public reader for the current count, so
    # this mirrors its own cache key (scope: controller_path, name: nil,
    # by: request.remote_ip) to read it back for display.
    def set_attempts_left
      used = Rails.cache.read([ "rate-limit", controller_path, request.remote_ip ].join(":")) || 0
      @attempts_left = [ MAX_COMPARISONS_PER_DAY - used, 0 ].max
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
      elsif quotes.any? { |quote| quote.size > MAX_QUOTE_SIZE }
        "Each file must be under #{MAX_QUOTE_SIZE / 1.megabyte} MB."
      elsif quotes.sum(&:size) > MAX_TOTAL_SIZE
        "The quotes come to more than #{MAX_TOTAL_SIZE / 1.megabyte} MB in total."
      end
    end
end
