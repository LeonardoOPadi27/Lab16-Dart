const test = require('node:test');
const assert = require('node:assert/strict');
const { validateEquipment, validateLoan } = require('../src/validators/common');

test('normaliza y valida un equipo correcto', () => {
  const result = validateEquipment({
    name: '  Laptop Dell  ',
    code: ' lap-020 ',
    category: 'Computadoras',
    location: 'Laboratorio A',
    totalQuantity: 5,
    status: 'available',
    description: '',
  });

  assert.deepEqual(result.errors, []);
  assert.equal(result.data.code, 'LAP-020');
  assert.equal(result.data.name, 'Laptop Dell');
});

test('rechaza una devolución anterior al préstamo', () => {
  const result = validateLoan({
    equipmentId: 1,
    borrowerName: 'Ana Torres',
    borrowerCode: 'U2026001',
    quantity: 1,
    loanDate: '2026-07-10',
    dueDate: '2026-07-08',
    notes: '',
  });

  assert.ok(result.errors.includes('La devolución no puede ser anterior al préstamo.'));
});
