const firestoreService = require('../services/firestore.service');

/**
 * POST /sme/profile
 */
const ALLOWED_PROFILE_FIELDS = [
  'business_name', 'owner_name', 'gst_number', 'phone_number', 'pincode', 'city', 'state',
  'industry', 'photo_url', 'annual_revenue_inr', 'employee_count', 'years_in_operation',
  // legacy / alternate field names kept for backwards compat
  'name', 'email', 'business_type', 'region', 'years_active',
];

async function createOrUpdateProfile(req, res) {
  try {
    const filtered = Object.fromEntries(
      Object.entries(req.body).filter(([k]) => ALLOWED_PROFILE_FIELDS.includes(k))
    );
    // Preserve existing profile_id so Firestore does an upsert on the same doc
    const existingProfileId = req.body.profile_id || null;
    const profileData = {
      ...filtered,
      user_id: req.user.uid,
    };
    const profileId = await firestoreService.saveSMEProfile(existingProfileId, profileData);

    return res.status(201).json({
      success: true,
      data: {
        profile_id: profileId,
        created_at: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('createOrUpdateProfile failed:', error);
    return res.status(500).json({ success: false, error: 'INTERNAL_ERROR' });
  }
}

/**
 * GET /sme/profile/:id
 */
async function getProfile(req, res) {
  const { id } = req.params;
  try {
    const profile = await firestoreService.getOwnedSMEProfile(id, req.user.uid);
    if (!profile) {
      return res.status(404).json({ success: false, error: 'NOT_FOUND' });
    }
    return res.json({
      success: true,
      data: profile
    });
  } catch (error) {
    console.error('getProfile failed:', error);
    return res.status(500).json({ success: false, error: 'INTERNAL_ERROR' });
  }
}

/**
 * GET /sme/profile/me
 * Returns the authenticated user's own most-recent profile.
 */
async function getMyProfile(req, res) {
  try {
    const profile = await firestoreService.getProfileByUserId(req.user.uid);
    if (!profile) {
      return res.status(404).json({ success: false, error: 'NOT_FOUND' });
    }
    return res.json({ success: true, data: profile });
  } catch (error) {
    console.error('getMyProfile failed:', error);
    return res.status(500).json({ success: false, error: 'INTERNAL_ERROR' });
  }
}

module.exports = {
  createOrUpdateProfile,
  getProfile,
  getMyProfile,
};
