function notFound(req, res) {
  res.status(404).json({ message: `Ruta no encontrada: ${req.method} ${req.path}` });
}

function errorHandler(error, req, res, next) {
  if (res.headersSent) return next(error);

  console.error(error);

  if (error.code === 'SQLITE_CONSTRAINT_UNIQUE') {
    return res.status(409).json({ message: 'El código del equipo ya está registrado.' });
  }

  if (error.code?.startsWith('SQLITE_CONSTRAINT')) {
    return res.status(409).json({ message: 'La operación no cumple las reglas de los datos.' });
  }

  return res.status(error.status || 500).json({
    message: error.message || 'Ocurrió un error inesperado.',
  });
}

module.exports = { notFound, errorHandler };
