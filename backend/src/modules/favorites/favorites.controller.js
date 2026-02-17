const { query } = require('../../config/db');

class FavoritesController {
  getFavorites = async (req, res) => {
    try {
      const result = await query(
        `SELECT id, item_type as "itemType", item_id as "itemId", created_at as "createdAt"
         FROM user_favorites
         WHERE user_id = $1
         ORDER BY created_at DESC`,
        [req.user.id]
      );
      res.json({ success: true, data: { favorites: result.rows } });
    } catch (err) {
      console.error('Get favorites error:', err);
      res.status(500).json({ success: false, message: 'Failed to fetch favorites.' });
    }
  };

  addFavorite = async (req, res) => {
    try {
      const { itemType, itemId } = req.body;
      await query(
        `INSERT INTO user_favorites (user_id, item_type, item_id)
         VALUES ($1, $2, $3)
         ON CONFLICT (user_id, item_type, item_id) DO NOTHING`,
        [req.user.id, itemType, itemId]
      );
      res.status(201).json({ success: true, message: 'Added to favorites.' });
    } catch (err) {
      console.error('Add favorite error:', err);
      res.status(500).json({ success: false, message: 'Failed to add favorite.' });
    }
  };

  removeFavorite = async (req, res) => {
    try {
      const { itemType, itemId } = req.params;
      const result = await query(
        `DELETE FROM user_favorites
         WHERE user_id = $1 AND item_type = $2 AND item_id = $3
         RETURNING id`,
        [req.user.id, itemType, itemId]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Favorite not found.' });
      }
      res.json({ success: true, message: 'Removed from favorites.' });
    } catch (err) {
      console.error('Remove favorite error:', err);
      res.status(500).json({ success: false, message: 'Failed to remove favorite.' });
    }
  };

  checkFavorite = async (req, res) => {
    try {
      const { itemType, itemId } = req.params;
      const result = await query(
        `SELECT 1 FROM user_favorites
         WHERE user_id = $1 AND item_type = $2 AND item_id = $3`,
        [req.user.id, itemType, itemId]
      );
      res.json({ success: true, data: { isFavorite: result.rows.length > 0 } });
    } catch (err) {
      console.error('Check favorite error:', err);
      res.status(500).json({ success: false, message: 'Failed to check favorite.' });
    }
  };
}

module.exports = new FavoritesController();
