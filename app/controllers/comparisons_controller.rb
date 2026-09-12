class ComparisonsController < ApplicationController
  REQUIRED_QUOTES = 3
  MAX_UPLOAD_SIZE = 10.megabytes

  # Upload form on the landing page.
  def new
  end

  # Accepts the uploaded PDFs, starts a comparison, and hands back its URL.
  def create
    @quotes = Array(params[:quotes]).compact_blank.map { |file| Quote.from_upload(file) }

    if (@error = upload_error(@quotes))
      return render :new, status: :unprocessable_entity
    end

    comparison = Comparison.new(quotes: @quotes)
    id = store(comparison)

    redirect_to comparison_path(id)
  end

  # Spinner while the comparison is running, result once it is done.
  def show
    @comparison = fetch(params[:id])

    redirect_to(root_path, alert: "That comparison has expired.") if @comparison.nil?
  end

  private
    def upload_error(quotes)
      return "Please upload #{REQUIRED_QUOTES} quotes." unless quotes.size == REQUIRED_QUOTES
      return "Every file must be a PDF." unless quotes.all?(&:pdf?)
      return "Each file must be under #{MAX_UPLOAD_SIZE / 1.megabyte} MB." if quotes.any? { |q| q.size > MAX_UPLOAD_SIZE }

      nil
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
