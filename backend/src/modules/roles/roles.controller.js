const { query, transaction } = require('../../config/db');

class RolesController {
  async listPermissions(req, res) {
    const result = await query('SELECT id, slug, description FROM permissions ORDER BY slug');
    res.json({ success: true, data: result.rows });
  }

  async listRoles(req, res) {
    const result = await query(
      `SELECT r.id, r.name, r.is_system_role,
              COALESCE(array_agg(DISTINCT p.slug) FILTER (WHERE p.slug IS NOT NULL), '{}') AS permissions
         FROM roles r
         LEFT JOIN role_permissions rp ON rp.role_id = r.id
         LEFT JOIN permissions p ON p.id = rp.permission_id
         GROUP BY r.id
         ORDER BY r.name`
    );
    res.json({ success: true, data: result.rows });
  }

  async createRole(req, res) {
    const { name, permissions = [] } = req.body;

    const existing = await query('SELECT id FROM roles WHERE name = $1', [name]);
    if (existing.rows.length > 0) {
      return res.status(400).json({ success: false, message: 'Role already exists.' });
    }

    const permRows = permissions.length
      ? await query('SELECT id, slug FROM permissions WHERE slug = ANY($1)', [permissions])
      : { rows: [] };
    const foundSlugs = new Set(permRows.rows.map((r) => r.slug));
    const missing = permissions.filter((p) => !foundSlugs.has(p));
    if (missing.length) {
      return res.status(400).json({
        success: false,
        message: `Unknown permissions: ${missing.join(', ')}`,
      });
    }

    const result = await transaction(async (client) => {
      const created = await client.query(
        'INSERT INTO roles (name, is_system_role) VALUES ($1, FALSE) RETURNING id, name, is_system_role',
        [name]
      );
      const roleId = created.rows[0].id;

      if (permRows.rows.length) {
        const values = permRows.rows.map((p) => `('${roleId}','${p.id}')`).join(',');
        await client.query(
          `INSERT INTO role_permissions (role_id, permission_id)
           VALUES ${values}
           ON CONFLICT DO NOTHING`
        );
      }

      return created.rows[0];
    });

    res.status(201).json({
      success: true,
      message: 'Role created successfully.',
      data: result,
    });
  }

  async updateRolePermissions(req, res) {
    const { id } = req.params;
    const { permissions = [] } = req.body;

    const role = await query('SELECT id, is_system_role FROM roles WHERE id = $1', [id]);
    if (role.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Role not found.' });
    }

    const permRows = permissions.length
      ? await query('SELECT id, slug FROM permissions WHERE slug = ANY($1)', [permissions])
      : { rows: [] };
    const foundSlugs = new Set(permRows.rows.map((r) => r.slug));
    const missing = permissions.filter((p) => !foundSlugs.has(p));
    if (missing.length) {
      return res.status(400).json({
        success: false,
        message: `Unknown permissions: ${missing.join(', ')}`,
      });
    }

    await transaction(async (client) => {
      await client.query('DELETE FROM role_permissions WHERE role_id = $1', [id]);
      if (permRows.rows.length) {
        const values = permRows.rows.map((p) => `('${id}','${p.id}')`).join(',');
        await client.query(
          `INSERT INTO role_permissions (role_id, permission_id)
           VALUES ${values}
           ON CONFLICT DO NOTHING`
        );
      }
    });

    const updated = await query(
      `SELECT r.id, r.name, r.is_system_role,
              COALESCE(array_agg(DISTINCT p.slug) FILTER (WHERE p.slug IS NOT NULL), '{}') AS permissions
         FROM roles r
         LEFT JOIN role_permissions rp ON rp.role_id = r.id
         LEFT JOIN permissions p ON p.id = rp.permission_id
         WHERE r.id = $1
         GROUP BY r.id`,
      [id]
    );

    res.json({ success: true, message: 'Permissions updated.', data: updated.rows[0] });
  }
}

module.exports = new RolesController();
