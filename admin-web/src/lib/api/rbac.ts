import api from './api';

// The shape of data your backend expects
interface UpdatePermissionsPayload {
  roleId: string;
  permissions: string[];
}

export const updateRolePermissions = async (matrix: Record<string, string[]>) => {
  try {
    // Transform the matrix object into an array for easier backend processing
    // Example: [{ roleId: 'sales_lead', permissions: ['leads.view'] }, ...]
    const payload: UpdatePermissionsPayload[] = Object.entries(matrix).map(
      ([roleId, permissions]) => ({
        roleId,
        permissions,
      })
    );

    // POST to your Node/Express backend
    const response = await api.post('/roles/update-matrix', {
      updates: payload
    });

    return response.data;
  } catch (error) {
    console.error('Failed to sync permissions:', error);
    console.log("hello");
    throw error;
  }
};
