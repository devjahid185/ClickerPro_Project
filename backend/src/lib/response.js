// src/lib/response.js
//
// সব response এর shape একই রাখার জন্য centralized helper।
// Flutter side এ ApiClient `{ user, token, ...payload }` expect করে,
// error case এ `{ message }` শোনে। তাই এই দুই shape ই use করি।

/**
 * Success response. `payload` যা থাকবে তা সরাসরি body তে spread হবে।
 * Example: ok(res, 200, { user: {...}, token: 'abc' })
 *          → 200 { user: {...}, token: 'abc' }
 */
function ok(res, statusCode, payload = {}) {
  return res.status(statusCode).json(payload);
}

/**
 * Error response. ক্লায়েন্ট সব সময় `message` field দেখে।
 */
function fail(res, statusCode, message, extra = {}) {
  return res.status(statusCode).json({ message, ...extra });
}

/**
 * Async route handler wrapper — try/catch বার বার লিখতে হবে না।
 * Usage: router.get('/x', asyncHandler(async (req, res) => { ... }))
 */
function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

module.exports = { ok, fail, asyncHandler };
