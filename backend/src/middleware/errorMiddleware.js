// src/middleware/errorMiddleware.js
//
// সব unhandled error কে standard JSON shape এ ফেরত দেয়:
//   { message, code? }
// Flutter এর ApiClient `r['message']` খুঁজে — তাই এই shape consistent।

function errorMiddleware(err, req, res, next) {
  // আগে log
  console.error(`[ERROR] ${new Date().toISOString()} ${req.method} ${req.url}`);
  console.error(err.stack || err);

  // Prisma এর কিছু পরিচিত error এর জন্য 4xx mapping
  if (err && err.code === 'P2002') {
    // unique constraint violation
    const target = (err.meta && err.meta.target) || [];
    return res.status(409).json({
      message: `ইতিমধ্যে এই ${target.join(', ') || 'value'}-এর একটি record আছে`,
    });
  }
  if (err && err.code === 'P2025') {
    return res.status(404).json({ message: 'Record খুঁজে পাওয়া যায়নি' });
  }
  if (err && err.code === 'P2003') {
    return res.status(400).json({ message: 'Foreign key violation' });
  }

  // SyntaxError (bad JSON body)
  if (err && err.type === 'entity.parse.failed') {
    return res.status(400).json({ message: 'Request body JSON সঠিক নয়' });
  }

  const status = err.statusCode || err.status || 500;
  res.status(status).json({
    message: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && err.stack
      ? { stack: err.stack }
      : {}),
  });
}

module.exports = errorMiddleware;
