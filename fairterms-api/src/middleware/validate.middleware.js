/**
 * Simple validation middleware for common requests.
 */

const FIRESTORE_ID_PATTERN = /^[A-Za-z0-9_-]{6,128}$/;
const GST_NUMBER_PATTERN = /^[0-9A-Z]{15}$/;
const PINCODE_PATTERN = /^\d{6}$/;
const LEADERBOARD_SORT_FIELDS = new Set([
    'fairness_score',
    'avg_payment_terms_days',
    'total_smes_served',
    'buyer_name',
]);
const SORT_ORDERS = new Set(['asc', 'desc']);

function trimString(value) {
    return typeof value === 'string' ? value.trim() : '';
}

function isNonEmptyString(value, maxLength = 255) {
    const trimmed = trimString(value);
    return trimmed.length > 0 && trimmed.length <= maxLength;
}

function isPositiveInteger(value, min = 1, max = Number.MAX_SAFE_INTEGER) {
    return Number.isInteger(value) && value >= min && value <= max;
}

function isFiniteNumberInRange(value, min, max) {
    return typeof value === 'number' && Number.isFinite(value) && value >= min && value <= max;
}

function validateResourceIdParam(req, res, next) {
    const { id } = req.params;
    if (!FIRESTORE_ID_PATTERN.test(id || '')) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Invalid resource ID' });
    }
    next();
}

function validateProfile(req, res, next) {
    const profile = {
        business_name: trimString(req.body.business_name),
        owner_name: trimString(req.body.owner_name),
        city: trimString(req.body.city),
        pincode: trimString(req.body.pincode),
        state: trimString(req.body.state),
        industry: trimString(req.body.industry),
        gst_number: trimString(req.body.gst_number),
        photo_url: trimString(req.body.photo_url),
        phone_number: trimString(req.body.phone_number),
    };

    if (
        !isNonEmptyString(profile.business_name, 150) ||
        !isNonEmptyString(profile.owner_name, 150) ||
        !PINCODE_PATTERN.test(profile.pincode) ||
        !isNonEmptyString(profile.state, 100) ||
        !isNonEmptyString(profile.industry, 100) ||
        !isPositiveInteger(req.body.annual_revenue_inr, 1, 10_000_000_000) ||
        !isPositiveInteger(req.body.employee_count, 1, 100_000) ||
        !isPositiveInteger(req.body.years_in_operation, 0, 200)
    ) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Missing required profile fields' });
    }

    if (profile.city && !isNonEmptyString(profile.city, 100)) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Invalid city value' });
    }

    if (profile.gst_number && !GST_NUMBER_PATTERN.test(profile.gst_number)) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Invalid GST number' });
    }

    req.body = {
        ...req.body,
        ...profile,
    };
    next();
}

function validateAnalysisRun(req, res, next) {
    const payload = {
        profile_id: trimString(req.body.profile_id),
        buyer_name: trimString(req.body.buyer_name),
        buyer_type: trimString(req.body.buyer_type),
        buyer_address: trimString(req.body.buyer_address),
        payment_terms_offered_to_sme: trimString(req.body.payment_terms_offered_to_sme),
        additional_context: trimString(req.body.additional_context),
    };

    if (
        !FIRESTORE_ID_PATTERN.test(payload.profile_id) ||
        !isNonEmptyString(payload.buyer_name, 150) ||
        !isPositiveInteger(req.body.payment_terms_days, 1, 3650) ||
        !isPositiveInteger(req.body.order_value_inr, 1, 10_000_000_000)
    ) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Missing required analysis fields' });
    }

    if (payload.buyer_type && !isNonEmptyString(payload.buyer_type, 100)) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Invalid buyer type' });
    }

    if (payload.buyer_address && !isNonEmptyString(payload.buyer_address, 500)) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Invalid buyer address' });
    }

    if (
        payload.payment_terms_offered_to_sme &&
        !isNonEmptyString(payload.payment_terms_offered_to_sme, 100)
    ) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Invalid payment terms label' });
    }

    if (
        req.body.sme_payment_to_suppliers_days !== undefined &&
        !isPositiveInteger(req.body.sme_payment_to_suppliers_days, 0, 3650)
    ) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Invalid supplier payment days' });
    }

    if (
        req.body.interest_rate_on_short_term_loan !== undefined &&
        !isFiniteNumberInRange(req.body.interest_rate_on_short_term_loan, 0, 100)
    ) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Invalid short-term loan interest rate' });
    }

    if (payload.additional_context.length > 2000) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Additional context is too long' });
    }

    req.body = {
        ...req.body,
        ...payload,
    };
    next();
}

function validateBenchmarkCompare(req, res, next) {
    const industry = trimString(req.body.industry);
    const state = trimString(req.body.state);
    const annualRevenueMin = req.body.annual_revenue_min;
    const annualRevenueMax = req.body.annual_revenue_max;

    if (
        !isNonEmptyString(industry, 100) ||
        !isPositiveInteger(req.body.payment_terms_days, 1, 3650)
    ) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'industry and payment_terms_days are required' });
    }

    if (state && !isNonEmptyString(state, 100)) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Invalid state value' });
    }

    if (annualRevenueMin !== undefined && !isPositiveInteger(annualRevenueMin, 1, 10_000_000_000)) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Invalid minimum revenue' });
    }

    if (annualRevenueMax !== undefined && !isPositiveInteger(annualRevenueMax, 1, 10_000_000_000)) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Invalid maximum revenue' });
    }

    if (
        annualRevenueMin !== undefined &&
        annualRevenueMax !== undefined &&
        annualRevenueMin > annualRevenueMax
    ) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Minimum revenue cannot exceed maximum revenue' });
    }

    req.body = {
        ...req.body,
        industry,
        state,
    };
    next();
}

function validateHeatmapQuery(req, res, next) {
    const industry = trimString(req.query.industry) || 'all';

    if (industry !== 'all' && !isNonEmptyString(industry, 100)) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Invalid industry filter' });
    }

    req.query = {
        ...req.query,
        industry,
    };
    next();
}

function validateLeaderboardQuery(req, res, next) {
    const sort = trimString(req.query.sort) || 'fairness_score';
    const order = (trimString(req.query.order) || 'desc').toLowerCase();
    const limitRaw = req.query.limit === undefined ? '50' : String(req.query.limit);
    const limit = Number.parseInt(limitRaw, 10);

    if (!LEADERBOARD_SORT_FIELDS.has(sort)) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Invalid leaderboard sort field' });
    }

    if (!SORT_ORDERS.has(order)) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Invalid leaderboard sort order' });
    }

    if (!Number.isInteger(limit) || limit < 1 || limit > 100) {
        return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'Leaderboard limit must be between 1 and 100' });
    }

    req.query = {
        ...req.query,
        sort,
        order,
        limit,
    };
    next();
}

module.exports = {
    validateResourceIdParam,
    validateProfile,
    validateAnalysisRun,
    validateBenchmarkCompare,
    validateHeatmapQuery,
    validateLeaderboardQuery
};
