const db = require('../config/database');
const { validateLoan, text } = require('../validators/common');

const selectBase = `
  SELECT l.id, l.equipment_id AS equipmentId, e.name AS equipmentName,
    e.code AS equipmentCode, l.borrower_name AS borrowerName,
    l.borrower_code AS borrowerCode, l.quantity,
    l.loan_date AS loanDate, l.due_date AS dueDate,
    l.returned_at AS returnedAt, l.status, l.notes,
    l.created_at AS createdAt, l.updated_at AS updatedAt
  FROM loans l
  JOIN equipment e ON e.id = l.equipment_id
`;

function list(req, res) {
  const status = String(req.query.status || '').trim();
  const search = String(req.query.search || '').trim();
  const conditions = [];
  const params = {};

  if (status) {
    conditions.push('l.status = @status');
    params.status = status;
  }
  if (search) {
    conditions.push('(l.borrower_name LIKE @search OR l.borrower_code LIKE @search OR e.name LIKE @search)');
    params.search = `%${search}%`;
  }

  const where = conditions.length ? ` WHERE ${conditions.join(' AND ')}` : '';
  res.json(db.prepare(`${selectBase}${where} ORDER BY l.created_at DESC`).all(params));
}

function create(req, res) {
  const { data, errors } = validateLoan(req.body);
  if (errors.length) return res.status(422).json({ message: errors[0], errors });

  const transaction = db.transaction(() => {
    const equipment = db.prepare('SELECT * FROM equipment WHERE id = ?').get(data.equipmentId);
    if (!equipment) {
      const error = new Error('El equipo seleccionado no existe.');
      error.status = 404;
      throw error;
    }
    if (equipment.status !== 'available') {
      const error = new Error('El equipo no está habilitado para préstamos.');
      error.status = 409;
      throw error;
    }
    if (equipment.available_quantity < data.quantity) {
      const error = new Error(`Solo hay ${equipment.available_quantity} unidad(es) disponibles.`);
      error.status = 409;
      throw error;
    }

    const result = db.prepare(`
      INSERT INTO loans
        (equipment_id, borrower_name, borrower_code, quantity, loan_date, due_date, notes)
      VALUES
        (@equipmentId, @borrowerName, @borrowerCode, @quantity, @loanDate, @dueDate, @notes)
    `).run(data);

    db.prepare(`
      UPDATE equipment SET available_quantity = available_quantity - ?, updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `).run(data.quantity, data.equipmentId);

    return result.lastInsertRowid;
  });

  const id = transaction();
  return res.status(201).json(db.prepare(`${selectBase} WHERE l.id = ?`).get(id));
}

function update(req, res) {
  const loan = db.prepare('SELECT * FROM loans WHERE id = ?').get(req.params.id);
  if (!loan) return res.status(404).json({ message: 'Préstamo no encontrado.' });
  if (loan.status === 'returned') {
    return res.status(409).json({ message: 'Un préstamo devuelto ya no puede editarse.' });
  }

  const borrowerName = text(req.body.borrowerName);
  const borrowerCode = text(req.body.borrowerCode).toUpperCase();
  const dueDate = text(req.body.dueDate);
  const notes = text(req.body.notes);

  if (borrowerName.length < 3 || borrowerCode.length < 3 || !/^\d{4}-\d{2}-\d{2}$/.test(dueDate)) {
    return res.status(422).json({ message: 'Revisa los datos del préstamo.' });
  }
  if (dueDate < loan.loan_date) {
    return res.status(422).json({ message: 'La devolución no puede ser anterior al préstamo.' });
  }

  db.prepare(`
    UPDATE loans SET borrower_name = ?, borrower_code = ?, due_date = ?, notes = ?,
      updated_at = CURRENT_TIMESTAMP WHERE id = ?
  `).run(borrowerName, borrowerCode, dueDate, notes, req.params.id);

  return res.json(db.prepare(`${selectBase} WHERE l.id = ?`).get(req.params.id));
}

function markReturned(req, res) {
  const transaction = db.transaction(() => {
    const loan = db.prepare('SELECT * FROM loans WHERE id = ?').get(req.params.id);
    if (!loan) {
      const error = new Error('Préstamo no encontrado.');
      error.status = 404;
      throw error;
    }
    if (loan.status === 'returned') {
      const error = new Error('Este préstamo ya fue devuelto.');
      error.status = 409;
      throw error;
    }

    db.prepare(`
      UPDATE loans SET status = 'returned', returned_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP WHERE id = ?
    `).run(req.params.id);
    db.prepare(`
      UPDATE equipment SET available_quantity = available_quantity + ?,
        updated_at = CURRENT_TIMESTAMP WHERE id = ?
    `).run(loan.quantity, loan.equipment_id);
  });

  transaction();
  return res.json(db.prepare(`${selectBase} WHERE l.id = ?`).get(req.params.id));
}

function remove(req, res) {
  const loan = db.prepare('SELECT * FROM loans WHERE id = ?').get(req.params.id);
  if (!loan) return res.status(404).json({ message: 'Préstamo no encontrado.' });
  if (loan.status === 'active') {
    return res.status(409).json({ message: 'Devuelve el equipo antes de eliminar el registro.' });
  }
  db.prepare('DELETE FROM loans WHERE id = ?').run(req.params.id);
  return res.status(204).send();
}

module.exports = { list, create, update, markReturned, remove };
