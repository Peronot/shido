import { Router } from 'express';

import { resources } from '../config/resources.js';
import { authenticate } from '../middleware/authenticate.js';
import { authorizeResource } from '../middleware/authorizeResource.js';
import {
  createResource,
  getResourceById,
  listResource,
  removeResource,
  updateResource,
} from './resourceController.js';

const router = Router();

router.param('resource', (req, res, next, resourceName) => {
  const config = resources[resourceName];
  if (!config) {
    return res.status(404).json({ error: `Unknown resource: ${resourceName}` });
  }

  req.resourceConfig = config;
  return next();
});

router.use(authenticate);

router.get('/:resource', authorizeResource, listResource);
router.get('/:resource/:id', authorizeResource, getResourceById);
router.post('/:resource', authorizeResource, createResource);
router.put('/:resource/:id', authorizeResource, updateResource);
router.delete('/:resource/:id', authorizeResource, removeResource);

export default router;
