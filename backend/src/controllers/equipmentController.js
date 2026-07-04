const db = require('../config/database');
const { validateEquipment } = require('../validators/common');

const selectBase = `
  SELECT id, name, code, category, location,
    total_quantity AS totalQuantity,
    available_quantity AS availableQuantity,
    status, description, created_at AS createdAt, updated_at AS updatedAt
  FROM equipment
`;

function list(req, res) {
  const search = String(req.query.search || '').trim();
  const status = String(req.query.status || '').trim();
  const conditions = [];
  const params = {};

  if (search) {
    conditions.push('(name LIKE @search OR code LIKE @search OR category LIKE @search)');
    params.search = `%${search}%`;
  }
  if (status) {
    conditions.push('status = @status');
    params.status = status;
  }

  const where = conditions.length ? ` WHERE ${conditions.join(' AND ')}` : '';
  const items = db.prepare(`${selectBase}${where} ORDER BY updated_at DESC`).all(params);
  res.json(items);
}

function getById(req, res) {
  const item = db.prepare(`${selectBase} WHERE id = ?`).get(req.params.id);
  if (!item) return res.status(404).json({ message: 'Equipo no encontrado.' });
  return res.json(item);
}

function create(req, res) {
  const { data, errors } = validateEquipment(req.body);
  if (errors.length) return res.status(422).json({ message: errors[0], errors });

  const result = db.prepare(`
    INSERT INTO equipment
      (name, code, category, location, total_quantity, available_quantity, status, description)
    VALUES
      (@name, @code, @category, @location, @totalQuantity, @totalQuantity, @status, @description)
  `).run(data);

  return res.status(201).json(db.prepare(`${selectBase} WHERE id = ?`).get(result.lastInsertRowid));
}

function update(req, res) {
  const current = db.prepare(`${selectBase} WHERE id = ?`).get(req.params.id);
  if (!current) return res.status(404).json({ message: 'Equipo no encontrado.' });

  const { data, errors } = validateEquipment(req.body);
  if (errors.length) return res.status(422).json({ message: errors[0], errors });

  const borrowed = current.totalQuantity - current.availableQuantity;
  if (data.totalQuantity < borrowed) {
    return res.status(409).json({
      message: `Hay ${borrowed} unidad(es) prestadas. La cantidad total no puede ser menor.`,
    });
  }

  db.prepare(`
    UPDATE equipment SET
      name = @name, code = @code, category = @category, location = @location,
      total_quantity = @totalQuantity,
      available_quantity = @availableQuantity,
      status = @status, description = @description, updated_at = CURRENT_TIMESTAMP
    WHERE id = @id
  `).run({
    ...data,
    id: Number(req.params.id),
    availableQuantity: data.totalQuantity - borrowed,
  });

  return res.json(db.prepare(`${selectBase} WHERE id = ?`).get(req.params.id));
}

function remove(req, res) {
  const activeLoans = db.prepare(
    "SELECT COUNT(*) AS total FROM loans WHERE equipment_id = ? AND status = 'active'",
  ).get(req.params.id).total;

  if (activeLoans > 0) {
    return res.status(409).json({ message: 'No puedes eliminar un equipo con préstamos activos.' });
  }

  const result = db.prepare('DELETE FROM equipment WHERE id = ?').run(req.params.id);
  if (!result.changes) return res.status(404).json({ message: 'Equipo no encontrado.' });
  return res.status(204).send();
}

module.exports = { list, getById, create, update, remove };
