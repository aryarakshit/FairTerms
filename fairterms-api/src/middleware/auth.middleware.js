const admin = require('firebase-admin');

/**
 * Decodes a JWT payload without signature verification.
 * Used as a fallback in ALLOW_MOCK_AUTH mode.
 */
function decodeJwtPayload(token) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
    return payload;
  } catch (_) {
    return null;
  }
}

/**
 * Middleware to authenticate requests using Firebase ID tokens.
 *
 * In ALLOW_MOCK_AUTH=true mode:
 *   - "mock-token" → fixed mock user
 *   - Real Firebase JWT when Admin SDK not configured → decoded without
 *     verification so real sign-in still works in local dev
 */
async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, error: 'AUTH_REQUIRED', message: 'No token provided' });
  }

  const idToken = authHeader.split('Bearer ')[1];
  const allowMock = process.env.ALLOW_MOCK_AUTH === 'true';

  // Fast path: literal mock token
  if (allowMock && idToken === 'mock-token') {
    req.user = { uid: 'mock-user-123', email: 'test@example.com' };
    return next();
  }

  // Try Firebase Admin verification if the SDK is initialised
  if (admin.apps.length) {
    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      req.user = decodedToken;
      return next();
    } catch (error) {
      console.error('Firebase token verification failed:', error.message);
      if (!allowMock) {
        return res.status(401).json({ success: false, error: 'AUTH_REQUIRED', message: 'Invalid token' });
      }
      // Fall through to the mock-auth decode path below
    }
  }

  // ALLOW_MOCK_AUTH fallback: decode JWT without verification to get the real uid
  // so Google-signed-in users work in local dev even without a service account.
  if (allowMock) {
    const payload = decodeJwtPayload(idToken);
    if (payload) {
      req.user = {
        uid: payload.user_id || payload.sub || payload.uid || 'dev-user',
        email: payload.email || '',
      };
      return next();
    }
    // Token isn't a JWT at all — still accept in mock mode with a fallback id
    req.user = { uid: 'dev-user', email: 'dev@fairterms.app' };
    return next();
  }

  return res.status(401).json({ success: false, error: 'AUTH_REQUIRED', message: 'Invalid token' });
}

module.exports = {
  authenticate
};
