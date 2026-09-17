module ComparisonsHelper
  # "7 line items, 2 discrepancies so far" — the running tally shown while
  # the extraction loop is still adding rows.
  def comparison_tally(comparison)
    t("comparisons.panel.tally",
      rows: t("comparisons.panel.tally_rows", count: comparison.rows.size),
      discrepancies: t("comparisons.panel.tally_discrepancies", count: comparison.discrepancies.size))
  end

  # "1,240 tokens used so far" — the running usage total shown while the job
  # is still working.
  def comparison_usage(comparison)
    t("comparisons.panel.usage", count: number_with_delimiter(comparison.total_tokens))
  end
end
