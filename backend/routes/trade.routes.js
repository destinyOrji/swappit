const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const {
  sendTradeRequest,
  respondToTrade,
  completeTrade,
  getMyTrades,
  rateTrade,
} = require('../controllers/trade.controller');

router.post('/request', protect, sendTradeRequest);
router.get('/', protect, getMyTrades);
router.put('/:tradeId/respond', protect, respondToTrade);
router.put('/:tradeId/complete', protect, completeTrade);
router.post('/:tradeId/rate', protect, rateTrade);

module.exports = router;
