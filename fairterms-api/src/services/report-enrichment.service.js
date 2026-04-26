const DEFAULT_RBI_BANK_RATE = Number(process.env.RBI_BANK_RATE || 6.5);
const DEFAULT_BUYER_TAX_RATE = Number(process.env.DEFAULT_BUYER_TAX_RATE || 25.0);
const MSME_PAYMENT_WINDOW_DAYS = 45;

/**
 * Formats an integer INR amount using Indian number grouping.
 */
function formatInr(amount) {
  return new Intl.NumberFormat('en-IN', {
    maximumFractionDigits: 0,
  }).format(Math.round(amount));
}

/**
 * Returns the number of delayed days beyond the MSME 45-day limit.
 */
function getDelayDays(paymentTermsDays) {
  return Math.max(0, Number(paymentTermsDays || 0) - MSME_PAYMENT_WINDOW_DAYS);
}

/**
 * Builds the stage-2 MSMED Act Section 16 interest calculation block.
 */
function buildInterestCalculation(paymentTerms) {
  const principal = Math.max(0, Math.round(Number(paymentTerms.order_value_inr || 0)));
  if (!principal) {
    return null;
  }

  const delayDays = getDelayDays(paymentTerms.payment_terms_days);
  const rbiBankRate = DEFAULT_RBI_BANK_RATE;
  const applicableRate = rbiBankRate * 3;
  const annualRateDecimal = applicableRate / 100;
  const monthlyRate = annualRateDecimal / 12;
  const monthsDelayed = delayDays / 30;
  const compoundInterest =
    delayDays > 0
      ? principal * (Math.pow(1 + monthlyRate, monthsDelayed) - 1)
      : 0;
  const totalOwed = principal + compoundInterest;
  const dailyAccrual =
    delayDays > 0 ? (principal * annualRateDecimal) / 365 : 0;

  return {
    principal_inr: principal,
    delay_days: delayDays,
    rbi_bank_rate: Number(rbiBankRate.toFixed(2)),
    applicable_rate: Number(applicableRate.toFixed(2)),
    compound_interest_inr: Math.round(compoundInterest),
    total_owed_inr: Math.round(totalOwed),
    daily_accrual_inr: Math.round(dailyAccrual),
    legal_basis: 'MSMED Act 2006, Section 16 - 3x RBI bank rate, compounded monthly',
    calculated_at: new Date().toISOString(),
  };
}

/**
 * Builds the stage-2 Section 43B(h) tax alert block.
 */
function buildTaxAlert(paymentTerms) {
  const invoiceAmount = Math.max(0, Math.round(Number(paymentTerms.order_value_inr || 0)));
  if (!invoiceAmount) {
    return null;
  }

  const delayDays = getDelayDays(paymentTerms.payment_terms_days);
  const taxRate = DEFAULT_BUYER_TAX_RATE;
  const taxDeductionLost =
    delayDays > 0 ? Math.round(invoiceAmount * (taxRate / 100)) : 0;

  const alertText =
    delayDays > 0
      ? `By delaying payment beyond 45 days, the buyer cannot claim Rs ${formatInr(invoiceAmount)} as a tax-deductible expense under Section 43B(h). This costs the buyer approximately Rs ${formatInr(taxDeductionLost)} in lost tax savings.`
      : 'The buyer is still within the 45-day MSME payment window, so Section 43B(h) tax disallowance is not triggered yet.';

  return {
    section: '43B(h) Income Tax Act',
    non_deductible_amount_inr: delayDays > 0 ? invoiceAmount : 0,
    estimated_buyer_tax_rate: Number(taxRate.toFixed(1)),
    tax_deduction_lost_inr: taxDeductionLost,
    alert_text: alertText,
    notice_pdf_url: null,
  };
}

module.exports = {
  buildInterestCalculation,
  buildTaxAlert,
};
