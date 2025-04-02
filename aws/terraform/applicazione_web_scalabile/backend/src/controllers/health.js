const getHealth = (req, res) => {
  console.log('Richiesta di health check ricevuta');
  res.status(200).json({ status: 'OK' });
};

module.exports = {
  getHealth,
};