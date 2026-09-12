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
  # `values` is one entry per quote, in the same order as `quotes`.
  def add_row(line_item:, values:, note: nil)
    rows << { line_item: line_item, values: values, note: note }
  end

  def add_discrepancy(description:, severity: :medium)
    unless SEVERITIES.include?(severity.to_sym)
      raise ArgumentError, "unknown severity #{severity.inspect}"
    end

    discrepancies << { description: description, severity: severity.to_sym }
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
