// src/middleware/adminMiddleware.js
//
// Gate for admin-only routes. Runs AFTER `authenticate` (which populates
// req.user from the JWT). Rejects anyone whose role is not ADMIN.
//
// Usage: router.get('/users', authenticate, requireAdmin, ctrl.listUsers)

function requireAdmin(req, res, next) {
  const role = (req.user && req.user.role ? req.user.role : '').toUpperCase();
  if (role !== 'ADMIN') {
    return res.status(403).json({ message: 'অ্যাডমিন অনুমতি প্রয়োজন' });
  }
  return next();
}

module.exports = requireAdmin;
module.exports.requireAdmin = requireAdmin;
