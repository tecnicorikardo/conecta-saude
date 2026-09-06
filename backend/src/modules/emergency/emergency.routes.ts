import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';
import {
  getActiveEmergency,
  createEmergencyAlert,
  resolveEmergencyAlert,
  listEmergencyHistory,
} from './emergency.controller';

const router = Router();

router.use(authenticate);

router.get('/active', getActiveEmergency);
router.get('/history', listEmergencyHistory);
router.post('/', createEmergencyAlert);
router.patch('/:id/resolve', resolveEmergencyAlert);

export { router as emergencyRouter };
