require('dotenv').config();
require('./config/database');
const app = require('./app');

const port = Number(process.env.PORT) || 3000;

app.listen(port, '0.0.0.0', () => {
  console.log(`StockLab API disponible en http://0.0.0.0:${port}/api`);
});
