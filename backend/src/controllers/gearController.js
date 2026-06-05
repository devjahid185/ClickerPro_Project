// src/controllers/gearController.js

const prisma = require('../lib/prisma');
const { ok, fail, asyncHandler } = require('../lib/response');

// Flutter expects { gear: { id, name, brand } } on add
function presentGear(g) {
  return {
    id: g.id,
    name: g.name,
    brand: g.serial || null, // schema-এ আলাদা brand নেই, serial = brand হিসেবে map
    category: g.category || 'Other',
    condition: g.condition || null,
    value: g.value ?? 0,
    addedAt: g.createdAt ? g.createdAt.toISOString() : null,
  };
}

// POST /api/gear/add  বা  POST /api/profile/gear
exports.addGear = asyncHandler(async (req, res) => {
  const { name, brand, category, serial, condition, value } = req.body || {};
  if (!name || !String(name).trim()) return fail(res, 400, 'Gear name দিতে হবে');

  const gear = await prisma.gearItem.create({
    data: {
      name: String(name).trim(),
      // Flutter brand পাঠালে সেটাকে serial column-এ map করে রাখি (brand
      // আলাদা column নেই — Phase 2 এ নতুন column add করব)
      serial: brand || serial || null,
      category: category || 'General',
      condition: condition || null,
      value: parseFloat(value) || 0,
      ownerId: req.user.id,
    },
  });
  return ok(res, 201, { gear: presentGear(gear) });
});

// GET /api/gear/my-gear  বা  GET /api/profile/gear
exports.getMyGear = asyncHandler(async (req, res) => {
  const list = await prisma.gearItem.findMany({
    where: { ownerId: req.user.id },
    orderBy: { createdAt: 'desc' },
  });
  return ok(res, 200, {
    count: list.length,
    gear: list.map(presentGear),
  });
});

// DELETE /api/gear/:id  বা  DELETE /api/profile/gear/:id
exports.deleteGear = asyncHandler(async (req, res) => {
  const { id } = req.params;
  // ensure ownership
  const item = await prisma.gearItem.findUnique({ where: { id } });
  if (!item) return fail(res, 404, 'Gear পাওয়া যায়নি');
  if (item.ownerId !== req.user.id) return fail(res, 403, 'অনুমতি নেই');

  await prisma.gearItem.delete({ where: { id } });
  return ok(res, 200, {});
});
