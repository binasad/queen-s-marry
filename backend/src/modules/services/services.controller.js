const { query } = require('../../config/db');
const s3Service = require('../../services/s3Service');
const { uploadToLocal } = require('../../services/localUploadService');

const isS3Configured = () => {
  const key = process.env.AWS_ACCESS_KEY_ID || '';
  const secret = process.env.AWS_SECRET_ACCESS_KEY || '';
  return key && secret && !key.includes('your_') && !secret.includes('your_');
};

class ServicesController {
  // Get all service categories
  async getCategories(req, res) {
    try {
      const result = await query(
        `SELECT * FROM service_categories 
         WHERE is_active = TRUE 
         ORDER BY display_order ASC, name ASC`
      );

      res.json({
        success: true,
        data: { categories: result.rows },
      });
    } catch (error) {
      console.error('Get categories error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch categories.',
      });
    }
  }

  // Create category (Admin only)
  async createCategory(req, res) {
    try {
      const { name, description, imageUrl, icon, displayOrder } = req.body;

      const result = await query(
        `INSERT INTO service_categories (name, description, image_url, icon, display_order)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [name, description || null, imageUrl || null, icon || null, displayOrder || 0]
      );

      res.status(201).json({
        success: true,
        message: 'Category created successfully.',
        data: { category: result.rows[0] },
      });
    } catch (error) {
      console.error('Create category error:', error);
      if (error.code === '23505') { // Unique violation
        return res.status(409).json({
          success: false,
          message: 'Category with this name already exists.',
        });
      }
      res.status(500).json({
        success: false,
        message: 'Failed to create category.',
      });
    }
  }

  // Get all services
  async getAllServices(req, res) {
    try {
      const { categoryId, minPrice, maxPrice, search, isActive } = req.query;

      let queryText = `
        SELECT s.*, s.category_id, c.name as category_name 
        FROM services s
        LEFT JOIN service_categories c ON s.category_id = c.id
        WHERE 1=1
      `;
      const queryParams = [];
      let paramCounter = 1;

      // Filter by active status if specified (for mobile app), otherwise show all (for admin)
      if (isActive !== undefined) {
        queryText += ` AND s.is_active = $${paramCounter}`;
        queryParams.push(isActive === 'true' || isActive === true);
        paramCounter++;
      }

      if (categoryId) {
        queryText += ` AND s.category_id = $${paramCounter}`;
        queryParams.push(categoryId);
        paramCounter++;
      }

      if (minPrice) {
        queryText += ` AND s.price >= $${paramCounter}`;
        queryParams.push(minPrice);
        paramCounter++;
      }

      if (maxPrice) {
        queryText += ` AND s.price <= $${paramCounter}`;
        queryParams.push(maxPrice);
        paramCounter++;
      }

      if (search) {
        queryText += ` AND (s.name ILIKE $${paramCounter} OR s.description ILIKE $${paramCounter})`;
        queryParams.push(`%${search}%`);
        paramCounter++;
      }

      queryText += ' ORDER BY s.name ASC';

      const result = await query(queryText, queryParams);

      res.json({
        success: true,
        data: { services: result.rows },
      });
    } catch (error) {
      console.error('Get services error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch services.',
      });
    }
  }

  // Get service by ID
  async getServiceById(req, res) {
    try {
      const { id } = req.params;

      const result = await query(
        `SELECT s.*, c.name as category_name,
                COALESCE(
                  (SELECT json_agg(json_build_object(
                    'id', e.id,
                    'name', e.name,
                    'specialty', e.specialty,
                    'rating', e.rating,
                    'image_url', e.image_url
                  ))
                  FROM experts e
                  JOIN expert_services es ON e.id = es.expert_id
                  WHERE es.service_id = s.id AND e.is_active = TRUE), '[]'
                ) as experts
         FROM services s
         LEFT JOIN service_categories c ON s.category_id = c.id
         WHERE s.id = $1 AND s.is_active = TRUE`,
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Service not found.',
        });
      }

      res.json({
        success: true,
        data: { service: result.rows[0] },
      });
    } catch (error) {
      console.error('Get service error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch service.',
      });
    }
  }

  // Create service (Admin only)
  async createService(req, res) {
    try {
      const { categoryId, name, description, price, duration, imageUrl, tags } = req.body;

      const result = await query(
        `INSERT INTO services (category_id, name, description, price, duration, image_url, tags)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [categoryId, name, description, price, duration, imageUrl, tags || []]
      );

      const newService = result.rows[0];
      if (global.io) {
        console.log('📢 Emitting service-created and services-updated events');
        global.io.to('admin').emit('service-created', { service: newService });
        global.io.emit('services-updated', { action: 'created', service: newService });
      }

      res.status(201).json({
        success: true,
        message: 'Service created successfully.',
        data: { service: newService },
      });
    } catch (error) {
      console.error('Create service error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to create service.',
      });
    }
  }

  // Update service (Admin only)
  async updateService(req, res) {
    try {
      const { id } = req.params;
      const { categoryId, name, description, price, duration, imageUrl, tags, isActive } = req.body;

      const result = await query(
        `UPDATE services 
         SET category_id = COALESCE($1, category_id),
             name = COALESCE($2, name),
             description = COALESCE($3, description),
             price = COALESCE($4, price),
             duration = COALESCE($5, duration),
             image_url = COALESCE($6, image_url),
             tags = COALESCE($7, tags),
             is_active = COALESCE($8, is_active)
         WHERE id = $9
         RETURNING *`,
        [categoryId, name, description, price, duration, imageUrl, tags, isActive, id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Service not found.',
        });
      }

      const updatedService = result.rows[0];
      if (global.io) {
        console.log('📢 Emitting service-updated and services-updated events');
        global.io.to('admin').emit('service-updated', { service: updatedService });
        global.io.emit('services-updated', { action: 'updated', service: updatedService });
      }

      res.json({
        success: true,
        message: 'Service updated successfully.',
        data: { service: updatedService },
      });
    } catch (error) {
      console.error('Update service error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update service.',
      });
    }
  }

  // Delete service (Admin only - soft delete)
  async deleteService(req, res) {
    try {
      const { id } = req.params;

      const result = await query(
        'UPDATE services SET is_active = FALSE WHERE id = $1 RETURNING id',
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Service not found.',
        });
      }

      const deletedServiceId = result.rows[0].id;
      if (global.io) {
        global.io.to('admin').emit('service-deleted', { serviceId: deletedServiceId });
        global.io.emit('services-updated', { action: 'deleted', serviceId: deletedServiceId });
      }

      res.json({
        success: true,
        message: 'Service deleted successfully.',
      });
    } catch (error) {
      console.error('Delete service error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to delete service.',
      });
    }
  }

  // Get all experts
  async getAllExperts(req, res) {
    try {
      const { serviceId } = req.query;

      let queryText = 'SELECT * FROM experts WHERE is_active = TRUE';
      const queryParams = [];

      if (serviceId) {
        queryText = `
          SELECT e.* FROM experts e
          JOIN expert_services es ON e.id = es.expert_id
          WHERE e.is_active = TRUE AND es.service_id = $1
        `;
        queryParams.push(serviceId);
      }

      queryText += ' ORDER BY e.rating DESC, e.name ASC';

      const result = await query(queryText, queryParams);

      res.json({
        success: true,
        data: { experts: result.rows },
      });
    } catch (error) {
      console.error('Get experts error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch experts.',
      });
    }
  }

  // Upload image to S3 or local (Admin only)
  async uploadImage(req, res) {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'No file uploaded.',
        });
      }

      const { folder = 'assets' } = req.body; // Default to 'assets', can be 'categories', 'services', 'profiles'
      const fileBuffer = req.file.buffer;
      const originalName = req.file.originalname;

      let imageUrl;
      if (isS3Configured()) {
        try {
          imageUrl = await s3Service.uploadImage(fileBuffer, originalName, folder);
        } catch (s3Error) {
          console.warn('S3 upload failed, using local fallback:', s3Error.message);
          imageUrl = await uploadToLocal(fileBuffer, originalName, folder);
        }
      } else {
        console.log('S3 not configured (placeholder credentials), using local storage');
        imageUrl = await uploadToLocal(fileBuffer, originalName, folder);
      }

      res.json({
        success: true,
        message: 'Image uploaded successfully.',
        data: { imageUrl },
      });
    } catch (error) {
      console.error('Upload image error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to upload image.',
      });
    }
  }
}

module.exports = new ServicesController();
