const router = require('express').Router();
const controller = require('../controllers/loanController');

router.get('/', controller.list);
router.post('/', controller.create);
router.put('/:id', controller.update);
router.patch('/:id/return', controller.markReturned);
router.delete('/:id', controller.remove);

module.exports = router;
