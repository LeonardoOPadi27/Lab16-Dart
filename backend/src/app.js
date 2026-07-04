const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const equipmentRoutes = require('./routes/equipmentRoutes');
const loanRoutes = require('./routes/loanRoutes');
const { notFound, errorHandler } = require('./middleware/errorHandler');

const app = express();

app.disable('x-powered-by');
app.use(cors());
app.use(express.json({ limit: '100kb' }));
app.use(morgan(process.env.NODE_ENV === 'test' ? 'tiny' : 'dev'));

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'StockLab API' });
});

app.use('/api/equipment', equipmentRoutes);
app.use('/api/loans', loanRoutes);
app.use(notFound);
app.use(errorHandler);

module.exports = app;
