# The assembled result the page renders: one row per line item, the
# discrepancies found between the quotes, and the recommendation.
# Held in memory for the life of the job — never persisted.
class Comparison
  STATUSES = %i[pending running done failed].freeze
  SEVERITIES = %i[low medium high].freeze

  EXPIRY = 1.hour

  attr_reader :quotes, :rows, :discrepancies, :status
  attr_accessor :recommendation, :error

  # Comparisons live in the process cache, not a database. They expire, and
  # they are not shared between containers. The controller and the job both
  # reach them through here.
  def self.store(comparison, id: SecureRandom.uuid)
    Rails.cache.write(cache_key(id), comparison, expires_in: EXPIRY)
    id
  end

  def self.find(id)
    Rails.cache.read(cache_key(id))
  end

  def self.cache_key(id)
    "comparison/#{id}"
  end

  def initialize(quotes: [])
    @quotes = quotes
    @rows = []
    @discrepancies = []
    @status = :pending
  end

  # One row of the table: a line item compared across the quotes.
  # `values` is one entry per quote, in the same order as `quotes`. Each
  # becomes a cell carrying whether it holds a real figure, so the view can
  # mark the rest "needs checking" rather than printing a bare "?".
  def add_row(line_item:, values:, note: nil)
    # A row must have one cell per quote. If the model returns too few, the
    # missing ones would slide under the wrong column, so pad them out; if it
    # returns too many, drop the extras.
    cells = Array(values).first(quotes.size).map { |value| cell_for(value) }
    cells << cell_for(nil) while cells.size < quotes.size

    rows << { line_item: line_item.to_s.strip, cells: cells, note: note.presence }
  end

  def add_discrepancy(description:, severity: :medium)
    candidate = severity.to_s.strip.downcase.to_sym
    candidate = :medium unless SEVERITIES.include?(candidate)

    discrepancies << { description: description.to_s.strip, severity: candidate }
  end

  # Placeholders the model reaches for when a quote does not state something.
  PLACEHOLDERS = [ "", "?", "-", "--", "n/a", "na", "none", "not stated", "unknown" ].freeze

  def cell_for(value)
    text = value.to_s.strip
    { value: text, verified: text.present? && !PLACEHOLDERS.include?(text.downcase) }
  end

  def status=(value)
    unless STATUSES.include?(value.to_sym)
      raise ArgumentError, "unknown status #{value.inspect}"
    end

    @status = value.to_sym
  end

  def done?
    status == :done
  end

  def failed?
    status == :failed
  end

  def discrepancies?
    discrepancies.any?
  end
end
