const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const USE_MOCK_FIRESTORE = process.env.USE_MOCK_FIRESTORE === 'true';
const MOCK_DB_PATH = path.join(__dirname, '../../mock_db.json');

// ---------------------------------------------------------------------------
// In-memory mock store (activated when USE_MOCK_FIRESTORE=true)
// ---------------------------------------------------------------------------
const _mock = {
  sme_profiles: new Map(),
  analyses: new Map(),
};

/** Saves mock data to local JSON file. */
function _saveMockData() {
  try {
    const data = {
      sme_profiles: Object.fromEntries(_mock.sme_profiles),
      analyses: Object.fromEntries(_mock.analyses),
    };
    fs.writeFileSync(MOCK_DB_PATH, JSON.stringify(data, null, 2));
  } catch (err) {
    console.error('Failed to save mock data:', err);
  }
}

/** Loads mock data from local JSON file. */
function _loadMockData() {
  if (fs.existsSync(MOCK_DB_PATH)) {
    try {
      const data = JSON.parse(fs.readFileSync(MOCK_DB_PATH, 'utf8'));
      _mock.sme_profiles = new Map(Object.entries(data.sme_profiles || {}));
      _mock.analyses = new Map(Object.entries(data.analyses || {}));
      console.log(`Loaded ${_mock.sme_profiles.size} profiles and ${_mock.analyses.size} analyses from mock DB.`);
    } catch (err) {
      console.error('Failed to load mock data:', err);
    }
  }
}

if (USE_MOCK_FIRESTORE) {
  _loadMockData();
}
const { randomUUID } = require('crypto');

/** Slugifies a display name into a URL-safe prefix (max 30 chars). */
function _slug(text) {
  return (text || '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 30) || 'mock';
}

/** Generates a readable mock ID: "{name-slug}-{8-char hex}" */
function _mockId(name) {
  const suffix = randomUUID().replace(/-/g, '').slice(0, 8);
  return `${_slug(name)}-${suffix}`;
}

// ---------------------------------------------------------------------------
// Real Firebase Admin initialisation (skipped in mock mode)
// ---------------------------------------------------------------------------
let db = null;
if (!USE_MOCK_FIRESTORE) {
  if (!admin.apps.length) {
    try {
      const serviceAccountPath = path.join(__dirname, '../../firebase-adminsdk.json');
      if (fs.existsSync(serviceAccountPath)) {
        console.log('Initializing Firebase Admin with local service account JSON.');
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccountPath),
        });
      } else {
        admin.initializeApp({
          credential: admin.credential.applicationDefault(),
        });
      }
    } catch (error) {
      console.warn('Firebase Admin failed to initialize. Ensure GOOGLE_APPLICATION_CREDENTIALS is set or firebase-adminsdk.json is present.');
      console.error(error.message);
    }
  }
  if (admin.apps.length) {
    db = admin.firestore();
  }
}

/**
 * Saves or updates an SME profile.
 */
async function saveSMEProfile(profileId, profileData) {
  if (USE_MOCK_FIRESTORE) {
    const id = profileId || _mockId(profileData.business_name || profileData.name);
    const now = new Date().toISOString();
    const existing = _mock.sme_profiles.get(id) || {};
    _mock.sme_profiles.set(id, {
      ...existing,
      ...profileData,
      updated_at: now,
      created_at: existing.created_at || now,
    });
    _saveMockData();
    return id;
  }

  const data = {
    ...profileData,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (profileId) {
    const docRef = db.collection('sme_profiles').doc(profileId);
    await docRef.set(data, { merge: true });
    return profileId;
  } else {
    data.created_at = admin.firestore.FieldValue.serverTimestamp();
    const newDoc = await db.collection('sme_profiles').add(data);
    return newDoc.id;
  }
}

/**
 * Retrieves an SME profile.
 */
async function getSMEProfile(profileId) {
  if (USE_MOCK_FIRESTORE) {
    const doc = _mock.sme_profiles.get(profileId);
    return doc ? { profile_id: profileId, ...doc } : null;
  }
  const doc = await db.collection('sme_profiles').doc(profileId).get();
  if (!doc.exists) return null;
  return { profile_id: doc.id, ...doc.data() };
}

/**
 * Retrieves an SME profile only if it belongs to the given user.
 */
async function getOwnedSMEProfile(profileId, userId) {
  const profile = await getSMEProfile(profileId);
  if (!profile || profile.user_id !== userId) {
    return null;
  }
  return profile;
}

/**
 * Retrieves the most-recent SME profile belonging to a user.
 */
async function getProfileByUserId(userId) {
  if (USE_MOCK_FIRESTORE) {
    const all = Array.from(_mock.sme_profiles.entries())
      .map(([id, doc]) => ({ profile_id: id, ...doc }))
      .filter((p) => p.user_id === userId);
    return all.length ? all[all.length - 1] : null;
  }
  const snapshot = await db.collection('sme_profiles')
    .where('user_id', '==', userId)
    .orderBy('created_at', 'desc')
    .limit(1)
    .get();
  if (snapshot.empty) return null;
  const doc = snapshot.docs[0];
  return { profile_id: doc.id, ...doc.data() };
}

/**
 * Creates a new analysis record with status 'processing'.
 */
async function createAnalysis(analysisData) {
  if (USE_MOCK_FIRESTORE) {
    const buyerName = analysisData.buyer_info?.name || analysisData.payment_terms?.buyer_name || '';
    const id = _mockId(buyerName);
    _mock.analyses.set(id, {
      ...analysisData,
      status: 'processing',
      created_at: new Date().toISOString(),
    });
    _saveMockData();
    return id;
  }
  const docRef = await db.collection('analyses').add({
    ...analysisData,
    status: 'processing',
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return docRef.id;
}

/**
 * Updates analysis record status and adds results.
 */
async function updateAnalysis(analysisId, updateData) {
  if (USE_MOCK_FIRESTORE) {
    const existing = _mock.analyses.get(analysisId) || {};
    _mock.analyses.set(analysisId, {
      ...existing,
      ...updateData,
      updated_at: new Date().toISOString(),
    });
    _saveMockData();
    return;
  }
  await db.collection('analyses').doc(analysisId).update({
    ...updateData,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Retrieves analysis record by ID.
 */
async function getAnalysis(analysisId) {
  if (USE_MOCK_FIRESTORE) {
    const doc = _mock.analyses.get(analysisId);
    return doc ? { analysis_id: analysisId, ...doc } : null;
  }
  const doc = await db.collection('analyses').doc(analysisId).get();
  if (!doc.exists) return null;
  return { analysis_id: doc.id, ...doc.data() };
}

/**
 * Retrieves an analysis only if it belongs to the given user.
 */
async function getOwnedAnalysis(analysisId, userId) {
  const analysis = await getAnalysis(analysisId);
  if (!analysis || analysis.user_id !== userId) {
    return null;
  }
  return analysis;
}

/**
 * Retrieves all analyses for a given user, sorted by created_at descending.
 */
async function getAnalysesByUser(userId) {
  if (USE_MOCK_FIRESTORE) {
    return Array.from(_mock.analyses.entries())
      .map(([id, doc]) => ({ analysis_id: id, ...doc }))
      .filter((a) => a.user_id === userId)
      .sort((a, b) => (b.created_at > a.created_at ? 1 : -1));
  }
  const snapshot = await db.collection('analyses')
    .where('user_id', '==', userId)
    .orderBy('created_at', 'desc')
    .get();
  return snapshot.docs.map(doc => ({ analysis_id: doc.id, ...doc.data() }));
}

// ---------------------------------------------------------------------------
// Admin-only queries (no ownership check)
// ---------------------------------------------------------------------------

/**
 * Returns all analyses across all users, newest first.
 */
async function getAllAnalyses(limit = 500) {
  if (USE_MOCK_FIRESTORE) {
    return Array.from(_mock.analyses.entries())
      .map(([id, doc]) => ({ analysis_id: id, ...doc }))
      .sort((a, b) => (b.created_at > a.created_at ? 1 : -1))
      .slice(0, limit);
  }
  const snapshot = await db.collection('analyses')
    .orderBy('created_at', 'desc')
    .limit(limit)
    .get();
  return snapshot.docs.map(doc => ({ analysis_id: doc.id, ...doc.data() }));
}

/**
 * Returns all SME profiles across all users.
 */
async function getAllProfiles(limit = 500) {
  if (USE_MOCK_FIRESTORE) {
    return Array.from(_mock.sme_profiles.entries())
      .map(([id, doc]) => ({ profile_id: id, ...doc }))
      .slice(0, limit);
  }
  const snapshot = await db.collection('sme_profiles')
    .orderBy('created_at', 'desc')
    .limit(limit)
    .get();
  return snapshot.docs.map(doc => ({ profile_id: doc.id, ...doc.data() }));
}

/**
 * Hard-deletes an analysis by ID (admin only).
 */
async function deleteAnalysis(analysisId) {
  if (USE_MOCK_FIRESTORE) {
    _mock.analyses.delete(analysisId);
    _saveMockData();
    return;
  }
  await db.collection('analyses').doc(analysisId).delete();
}

/**
 * Hard-deletes every analysis owned by the given user. Returns the count removed.
 */
async function deleteAnalysesByUser(userId) {
  if (USE_MOCK_FIRESTORE) {
    let removed = 0;
    for (const [id, doc] of _mock.analyses.entries()) {
      if (doc.user_id === userId) {
        _mock.analyses.delete(id);
        removed++;
      }
    }
    if (removed > 0) _saveMockData();
    return removed;
  }
  const snapshot = await db.collection('analyses')
    .where('user_id', '==', userId)
    .get();
  if (snapshot.empty) return 0;

  // Firestore batches cap at 500 writes — chunk if necessary.
  const docs = snapshot.docs;
  for (let i = 0; i < docs.length; i += 450) {
    const batch = db.batch();
    docs.slice(i, i + 450).forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }
  return docs.length;
}

module.exports = {
  saveSMEProfile,
  getSMEProfile,
  getOwnedSMEProfile,
  getProfileByUserId,
  createAnalysis,
  updateAnalysis,
  getAnalysis,
  getOwnedAnalysis,
  getAnalysesByUser,
  getAllAnalyses,
  getAllProfiles,
  deleteAnalysis,
  deleteAnalysesByUser,
};
