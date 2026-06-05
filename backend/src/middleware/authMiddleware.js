// src/middleware/authMiddleware.js
//
// JWT verify। req.user → { id, role } populate করে।  Failure case-এ Flutter
// `ApiException(statusCode: 401)` সাড়াকে session invalidation signal হিসেবে
// ধরে — তাই 401 এ message string consistent রাখি।

const jwt = require('jsonwebtoken');

const JWT_SECRET =
  process.env.JWT_SECRET || 'ClickerPro_Super_Secret_Key_12345';

function authenticate(req, res, next) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'অনুমতি নেই — token দরকার' });
  }
  const token = header.slice(7).trim();
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = { id: decoded.id, role: decoded.role };
    return next();
  } catch (_err) {
    return res.status(401).json({ message: 'টোকেনটি সঠিক নয়' });
  }
}

module.exports = authenticate;
module.exports.authMiddleware = authenticate;
module.exports.authenticate = authenticate;
