const admin = require('firebase-admin');

/**
 * Middleware that allows only admin users.
 * Must run after authenticate middleware (req.user must exist).
 *
 * Admins are identified by either:
 *  1. Firebase custom claim:  { admin: true }
 *  2. ADMIN_UIDS env var (comma-separated UIDs) — for bootstrapping the first admin
 */
async function requireAdmin(req, res, next) {
  const uid = req.user?.uid;
  if (!uid) {
    return res.status(403).json({ success: false, error: 'FORBIDDEN', message: 'Admin access required' });
  }

  // Bootstrap: UIDs listed in ADMIN_UIDS are always admin
  const adminUids = (process.env.ADMIN_UIDS || '').split(',').map(s => s.trim()).filter(Boolean);
  if (adminUids.includes(uid)) return next();

  // Check Firebase custom claim (only when Firebase Admin SDK is initialized)
  if (admin.apps.length > 0) {
    try {
      const userRecord = await admin.auth().getUser(uid);
      if (userRecord.customClaims?.admin === true) return next();
    } catch (err) {
      console.error('Admin claim check failed:', err.message);
    }
  }

  return res.status(403).json({ success: false, error: 'ADMIN_REQUIRED', message: 'Admin privileges required' });
}

module.exports = { requireAdmin };
