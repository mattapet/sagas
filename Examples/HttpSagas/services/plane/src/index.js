'use strict';

const app = require('express')();
const config = require('config');
const bodyParser = require('body-parser');
const morgan = require('morgan');
const PORT = process.env.PORT || config.get('service.port') || 3000;
const SERVICE = process.env.SERVICE || config.get('service.name');

app.use(morgan('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

app.post('/trip', (req, res) => {
  console.log(`[${SERVICE}]: Trip request`);
  res.send({ status: 'ok' });
});

app.post('/trip/cancel', (req, res) => {
  console.log(`[${SERVICE}]: Trip cancel request`);
  res.send({ status: 'ok' });
});

app.listen(PORT, (err) => {
  if (!err) {
    console.log(`Service ${SERVICE} running on port ${PORT}`);
  }
});
