const { query } = require('../../config/db');

const fetchUserWithRole = async (userId) => {
  const result = await query(
    `SELECT
       u.id,
       u.name,
       u.email,
       u.address,
       u.phone,
       u.gender,
       u.profile_image_url,
       u.email_verified,
       u.created_at,
       u.last_login,
       u.role_id,
       r.name AS role_name,
       COALESCE(array_agg(DISTINCT p.slug) FILTER (WHERE p.slug IS NOT NULL), '{}') AS permissions
     FROM users u
     LEFT JOIN roles r ON u.role_id = r.id
     LEFT JOIN role_permissions rp ON rp.role_id = r.id
     LEFT JOIN permissions p ON p.id = rp.permission_id
     WHERE u.id = $1
     GROUP BY u.id, r.id`,
    [userId]
  );
  return result.rows[0];
};

class UsersController {
  // Get current user profile
  async getProfile(req, res) {
    try {
      const user = await fetchUserWithRole(req.user.id);

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found.',
        });
      }

      res.json({
        success: true,
        data: {
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            address: user.address,
            phone: user.phone,
            gender: user.gender,
            profile_image_url: user.profile_image_url,
            email_verified: user.email_verified,
            created_at: user.created_at,
            last_login: user.last_login,
            role: {
              id: user.role_id,
              name: user.role_name,
              permissions: user.permissions,
            },
          },
        },
      });
    } catch (error) {
      console.error('Get profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch profile.',
      });
    }
  }

  // Update profile
  async updateProfile(req, res) {
    try {
      const { name, address, phone, gender, profileImageUrl } = req.body;
      const updates = [];
      const values = [];
      let paramCounter = 1;

      if (name !== undefined) { updates.push(`name = $${paramCounter++}`); values.push(name); }
      if (address !== undefined) { updates.push(`address = $${paramCounter++}`); values.push(address); }
      if (phone !== undefined) { updates.push(`phone = $${paramCounter++}`); values.push(phone); }
      if (gender !== undefined) { updates.push(`gender = $${paramCounter++}`); values.push(gender); }
      if (profileImageUrl !== undefined) { updates.push(`profile_image_url = $${paramCounter++}`); values.push(profileImageUrl); }

      if (updates.length === 0) {
        const user = await fetchUserWithRole(req.user.id);
        return res.json({ success: true, data: { user } });
      }

      values.push(req.user.id);
      await query(
        `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramCounter}`,
        values
      );

      const user = await fetchUserWithRole(req.user.id);

      res.json({
        success: true,
        message: 'Profile updated successfully.',
        data: { user },
      });
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update profile.',
      });
    }
  }

  // Get user by ID (Admin only)
  async getUserById(req, res) {
    try {
      const { id } = req.params;

      const user = await fetchUserWithRole(id);

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found.',
        });
      }

      res.json({
        success: true,
        data: { user },
      });
    } catch (error) {
      console.error('Get user error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch user.',
      });
    }
  }

  // Get all users (Admin only)
  async getAllUsers(req, res) {
    try {
      const { role, search, page = 1, limit = 10 } = req.query;
      const offset = (page - 1) * limit;

      let queryText = `
        SELECT u.id, u.name, u.email, u.phone, u.email_verified, u.created_at, u.last_login,
               u.role_id, r.name AS role_name
        FROM users u
        LEFT JOIN roles r ON u.role_id = r.id
        WHERE 1=1
      `;
      const queryParams = [];
      let paramCounter = 1;

      if (role) {
        queryText += ` AND r.name = $${paramCounter}`;
        queryParams.push(role);
        paramCounter++;
      }

      if (search) {
        queryText += ` AND (name ILIKE $${paramCounter} OR email ILIKE $${paramCounter})`;
        queryParams.push(`%${search}%`);
        paramCounter++;
      }

      queryText += ` ORDER BY created_at DESC LIMIT $${paramCounter} OFFSET $${paramCounter + 1}`;
      queryParams.push(limit, offset);

      const result = await query(queryText, queryParams);

      // Get total count
      let countQuery = 'SELECT COUNT(*) FROM users u LEFT JOIN roles r ON u.role_id = r.id WHERE 1=1';
      const countParams = [];
      if (role) {
        countQuery += ' AND r.name = $1';
        countParams.push(role);
      }
      if (search) {
        countQuery += ` AND (name ILIKE $${countParams.length + 1} OR email ILIKE $${countParams.length + 1})`;
        countParams.push(`%${search}%`);
      }

      const countResult = await query(countQuery, countParams);
      const totalUsers = parseInt(countResult.rows[0].count, 10);

      res.json({
        success: true,
        data: {
          users: result.rows,
          pagination: {
            page: parseInt(page, 10),
            limit: parseInt(limit, 10),
            total: totalUsers,
            pages: Math.ceil(totalUsers / limit),
          },
        },
      });
    } catch (error) {
      console.error('Get users error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch users.',
      });
    }
  }

  // Assign role to user by email (Admin only)
  async assignRoleByEmail(req, res) {
    try {
      const { email, roleId } = req.body;

      if (!email || !roleId) {
        return res.status(400).json({
          success: false,
          message: 'Email and roleId are required.',
        });
      }

      // Check if user exists in users table
      // NOTE: schema uses password_hash now, and we don't need the password here,
      // so only select the fields we actually use.
      const existingUser = await query(
        'SELECT id, role_id, name FROM users WHERE email = $1',
        [email]
      );

      if (existingUser.rows.length > 0) {
        // User exists - just update their role
        const userData = existingUser.rows[0];
        const hasExistingRole = userData.role_id !== null;

        await query('UPDATE users SET role_id = $1 WHERE email = $2', [roleId, email]);

      // Send welcome/setup email (async - don't wait for it)
      const emailService = require('../auth/auth.service.email');
      emailService.emailService.sendWelcomeEmail(email, userData.name || 'User', hasExistingRole)
        .catch(err => {
          console.error('Failed to send welcome email:', err);
        });

        return res.json({
          success: true,
          message: hasExistingRole
            ? `Role updated successfully. Welcome email will be sent to ${email}.`
            : `Role assigned successfully. Welcome email will be sent to ${email}.`,
          data: { user: { id: userData.id, email: email, name: userData.name } },
        });
      }

      // User doesn't exist - create them with the role (password will be set via email link)
      const bcrypt = require('bcryptjs');
      const hashedPassword = await bcrypt.hash('temp_' + Date.now(), 10); // Temporary password

      const newUser = await query(
        `INSERT INTO users (name, email, password_hash, role_id, email_verified)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id`,
        ['New User', email, hashedPassword, roleId, true]
      );

      // Send welcome/setup email (async - don't wait for it)
      const emailService = require('../auth/auth.service.email');
      emailService.emailService.sendWelcomeEmail(email, 'New User', false)
        .catch(err => {
          console.error('Failed to send welcome email:', err);
        });

      res.json({
        success: true,
        message: `User account created and role assigned. Welcome email will be sent to ${email}.`,
        data: { user: { id: newUser.rows[0].id, email: email, name: 'New User' } },
      });
    } catch (error) {
      console.error('Assign role error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to assign role.',
      });
    }
  }

  // Assign role to multiple users by email (Admin only)
  async assignRoleToMultiple(req, res) {
    try {
      const { emails, roleId } = req.body;

      if (!emails || !Array.isArray(emails) || emails.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Emails array is required.',
        });
      }

      if (!roleId) {
        return res.status(400).json({
          success: false,
          message: 'RoleId is required.',
        });
      }

      // Check if role exists
      const roleResult = await query('SELECT id, name FROM roles WHERE id = $1', [roleId]);
      if (roleResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Role not found.',
        });
      }

      const results = {
        success: [],
        failed: [],
      };

      for (const email of emails) {
        try {
          const userResult = await query('SELECT id FROM users WHERE email = $1', [email]);
          if (userResult.rows.length === 0) {
            results.failed.push({ email, reason: 'User not found' });
            continue;
          }

          await query('UPDATE users SET role_id = $1 WHERE email = $2', [roleId, email]);
          results.success.push(email);
        } catch (error) {
          results.failed.push({ email, reason: error.message });
        }
      }

      res.json({
        success: true,
        message: `Role "${roleResult.rows[0].name}" assigned to ${results.success.length} user(s).`,
        data: {
          assigned: results.success,
          failed: results.failed,
        },
      });
    } catch (error) {
      console.error('Assign role to multiple error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to assign roles.',
      });
    }
  }

  // Delete user (Admin only)
  async deleteUser(req, res) {
    try {
      const { id } = req.params;

      // Prevent deleting own account
      if (id === req.user.id) {
        return res.status(400).json({
          success: false,
          message: 'You cannot delete your own account.',
        });
      }

      const result = await query(
        'DELETE FROM users WHERE id = $1 RETURNING id',
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found.',
        });
      }

      res.json({
        success: true,
        message: 'User deleted successfully.',
      });
    } catch (error) {
      console.error('Delete user error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to delete user.',
      });
    }
  }
}

module.exports = new UsersController();
