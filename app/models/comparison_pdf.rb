# Draws a landscape PDF export of a Comparison: the table, the discrepancies,
# and the recommendation. Prawn draws from scratch, so this does not share
# any styling with the HTML panel — it is maintained separately.
class ComparisonPdf
  def self.render(comparison)
    new(comparison).render
  end

  def initialize(comparison)
    @comparison = comparison
  end

  def render
    document.render
  end

  private
    attr_reader :comparison

    def document
      @document ||= Prawn::Document.new(page_size: "A4", page_layout: :landscape).tap do |pdf|
        draw_wordmark(pdf)
        pdf.text safe(I18n.t("comparisons.panel.heading")), size: 12, color: "666666"
        pdf.move_down 16

        draw_table(pdf)
        draw_discrepancies(pdf) if comparison.discrepancies?
        draw_recommendation(pdf) if comparison.recommendation.present?
      end
    end

    # A small text wordmark — a diamond glyph next to bold "Comparadevis" —
    # matching the app header's rotated-square-plus-text treatment. No image
    # asset needed, so it stays crisp at any size.
    def draw_wordmark(pdf)
      mark = 14
      top = pdf.cursor
      left = pdf.bounds.left
      cx = left + mark / 2.0
      cy = top - mark / 2.0
      half = mark / 2.0

      pdf.stroke_color "22D3EE"
      pdf.line_width 1.5
      pdf.stroke_polygon [ cx, cy + half ], [ cx + half, cy ], [ cx, cy - half ], [ cx - half, cy ]
      pdf.stroke_color "000000"

      pdf.draw_text "Comparadevis", at: [ left + mark + 8, top - 15 ], size: 20, style: :bold
      pdf.move_down mark + 6
    end

    def draw_table(pdf)
      header = [ "" ] + comparison.quotes.map { |quote| safe(quote.label) }
      rows = comparison.rows.map { |row| table_row(row) }

      pdf.table([ header ] + rows, header: true, width: pdf.bounds.width) do |table|
        table.row(0).font_style = :bold
        table.row(0).background_color = "EEEEEE"
        table.cells.padding = 6
        table.cells.size = 9
      end
    end

    def table_row(row)
      label = row[:unit].present? ? "#{row[:line_item]} (#{row[:unit]})" : row[:line_item]
      needs_checking = I18n.t("comparisons.panel.needs_checking")
      values = row[:cells].map { |cell| cell[:verified] ? cell[:value] : needs_checking }

      ([ label ] + values).map { |text| safe(text) }
    end

    def draw_discrepancies(pdf)
      pdf.move_down 20
      pdf.text safe(I18n.t("comparisons.panel.discrepancies")), size: 14, style: :bold
      pdf.move_down 6

      comparison.discrepancies.each do |discrepancy|
        pdf.text safe("• (#{discrepancy[:severity]}) #{discrepancy[:description]}"), size: 10
      end
    end

    def draw_recommendation(pdf)
      pdf.move_down 20
      pdf.text safe(I18n.t("comparisons.panel.recommendation")), size: 14, style: :bold
      pdf.move_down 6
      pdf.text safe(comparison.recommendation), size: 10
    end

    # Prawn's built-in fonts only support Windows-1252, but the model's prose
    # sometimes uses smart quotes/dashes/ellipses outside that set — normalize
    # the common ones to their ASCII equivalents, then drop anything that
    # still doesn't fit rather than letting the whole export crash on it.
    def safe(text)
      text.to_s
        .gsub(/[‘’]/, "'")
        .gsub(/[“”]/, '"')
        .gsub(/[–—]/, "-")
        .gsub(/…/, "...")
        .encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?")
        .encode("UTF-8")
    end
end
