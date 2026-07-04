function text(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function positiveInteger(value) {
  const number = Number(value);
  return Number.isInteger(number) && number > 0 ? number : null;
}

function validateEquipment(body) {
  const data = {
    name: text(body.name),
    code: text(body.code).toUpperCase(),
    category: text(body.category),
    location: text(body.location),
    totalQuantity: positiveInteger(body.totalQuantity),
    status: text(body.status) || 'available',
    description: text(body.description),
  };

  const errors = [];
  if (data.name.length < 3) errors.push('El nombre debe tener al menos 3 caracteres.');
  if (!/^[A-Z0-9-]{3,20}$/.test(data.code)) errors.push('El código solo admite letras, números y guiones.');
  if (!data.category) errors.push('La categoría es obligatoria.');
  if (!data.location) errors.push('La ubicación es obligatoria.');
  if (!data.totalQuantity) errors.push('La cantidad debe ser un entero mayor que cero.');
  if (!['available', 'maintenance', 'inactive'].includes(data.status)) errors.push('El estado no es válido.');

  return { data, errors };
}

function validateLoan(body) {
  const data = {
    equipmentId: positiveInteger(body.equipmentId),
    borrowerName: text(body.borrowerName),
    borrowerCode: text(body.borrowerCode).toUpperCase(),
    quantity: positiveInteger(body.quantity),
    loanDate: text(body.loanDate),
    dueDate: text(body.dueDate),
    notes: text(body.notes),
  };

  const errors = [];
  if (!data.equipmentId) errors.push('Selecciona un equipo válido.');
  if (data.borrowerName.length < 3) errors.push('Ingresa el nombre del responsable.');
  if (data.borrowerCode.length < 3) errors.push('Ingresa un código de responsable válido.');
  if (!data.quantity) errors.push('La cantidad debe ser mayor que cero.');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(data.loanDate)) errors.push('La fecha de préstamo no es válida.');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(data.dueDate)) errors.push('La fecha de devolución no es válida.');
  if (data.loanDate && data.dueDate && data.dueDate < data.loanDate) {
    errors.push('La devolución no puede ser anterior al préstamo.');
  }

  return { data, errors };
}

module.exports = { validateEquipment, validateLoan, text };
