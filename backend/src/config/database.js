const fs = require('node:fs');
const path = require('node:path');
const Database = require('better-sqlite3');

const databasePath = path.resolve(
  __dirname,
  '../..',
  process.env.DB_PATH || './data/stocklab.db',
);

fs.mkdirSync(path.dirname(databasePath), { recursive: true });

const db = new Database(databasePath);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS equipment (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    code TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL,
    location TEXT NOT NULL,
    total_quantity INTEGER NOT NULL CHECK(total_quantity > 0),
    available_quantity INTEGER NOT NULL CHECK(available_quantity >= 0),
    status TEXT NOT NULL DEFAULT 'available'
      CHECK(status IN ('available', 'maintenance', 'inactive')),
    description TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS loans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    equipment_id INTEGER NOT NULL,
    borrower_name TEXT NOT NULL,
    borrower_code TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK(quantity > 0),
    loan_date TEXT NOT NULL,
    due_date TEXT NOT NULL,
    returned_at TEXT,
    status TEXT NOT NULL DEFAULT 'active'
      CHECK(status IN ('active', 'returned')),
    notes TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON DELETE RESTRICT
  );

  CREATE INDEX IF NOT EXISTS idx_equipment_name ON equipment(name);
  CREATE INDEX IF NOT EXISTS idx_loans_status ON loans(status);
  CREATE INDEX IF NOT EXISTS idx_loans_equipment ON loans(equipment_id);
`);

const count = db.prepare('SELECT COUNT(*) AS total FROM equipment').get().total;

if (count === 0) {
  const insert = db.prepare(`
    INSERT INTO equipment
      (name, code, category, location, total_quantity, available_quantity, status, description)
    VALUES
      (@name, @code, @category, @location, @totalQuantity, @availableQuantity, @status, @description)
  `);

  const seed = db.transaction((items) => {
    for (const item of items) insert.run(item);
  });

  seed([
    {
      name: 'Laptop Lenovo ThinkPad', code: 'LAP-001', category: 'Computadoras',
      location: 'Laboratorio A', totalQuantity: 8, availableQuantity: 8,
      status: 'available', description: 'Equipo para prácticas de programación.',
    },
    {
      name: 'Proyector Epson', code: 'PRO-004', category: 'Audiovisual',
      location: 'Almacén principal', totalQuantity: 3, availableQuantity: 3,
      status: 'available', description: 'Proyector portátil con conexión HDMI.',
    },
    {
      name: 'Kit Arduino Uno', code: 'ARD-012', category: 'Electrónica',
      location: 'Laboratorio B', totalQuantity: 12, availableQuantity: 12,
      status: 'available', description: 'Kit con placa, sensores y cables.',
    },
  ]);
}

module.exports = db;
