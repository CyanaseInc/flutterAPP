const db = require("../config/db");

// Create a new group
exports.createGroup = async (req, res, next) => {
  try {
    const { name, description, createdBy } = req.body;

    // Validate input
    if (!name || !createdBy) {
      return res.status(400).json({ success: false, message: "Name and createdBy are required" });
    }

    // Insert into groups table
    const insertGroupQuery = `
      INSERT INTO groups (name, description, created_by, created_at)
      VALUES (?, ?, ?, NOW())
    `;
    const [groupResult] = await db.query(insertGroupQuery, [name, description, createdBy]);

    // Add the creator as a participant with the role 'admin'
    const insertParticipantQuery = `
      INSERT INTO group_participants (group_id, user_id, role, joined_at)
      VALUES (?, ?, 'admin', NOW())
    `;
    await db.query(insertParticipantQuery, [groupResult.insertId, createdBy]);

    res.status(201).json({ success: true, message: "Group created successfully", groupId: groupResult.insertId });
  } catch (err) {
    next(err);
  }
};

// Join a group
exports.joinGroup = async (req, res, next) => {
  try {
    const { groupId, userId } = req.body;

    // Validate input
    if (!groupId || !userId) {
      return res.status(400).json({ success: false, message: "groupId and userId are required" });
    }

    // Check if the user is already a participant
    const checkParticipantQuery = "SELECT * FROM group_participants WHERE group_id = ? AND user_id = ?";
    const [existingParticipant] = await db.query(checkParticipantQuery, [groupId, userId]);

    if (existingParticipant.length > 0) {
      return res.status(400).json({ success: false, message: "User is already a member of the group" });
    }

    // Add the user as a participant with the role 'member'
    const insertParticipantQuery = `
      INSERT INTO group_participants (group_id, user_id, role, joined_at)
      VALUES (?, ?, 'member', NOW())
    `;
    await db.query(insertParticipantQuery, [groupId, userId]);

    res.status(200).json({ success: true, message: "User joined the group successfully" });
  } catch (err) {
    next(err);
  }
};

// Fetch all groups for a user
exports.fetchGroups = async (req, res, next) => {
  try {
    const { userId } = req.query;

    // Validate input
    if (!userId) {
      return res.status(400).json({ success: false, message: "userId is required" });
    }

    // Fetch all groups the user is a member of
    const fetchGroupsQuery = `
      SELECT g.* FROM groups g
      INNER JOIN group_participants gp ON g.id = gp.group_id
      WHERE gp.user_id = ?
    `;
    const [groups] = await db.query(fetchGroupsQuery, [userId]);

    res.status(200).json({ success: true, groups });
  } catch (err) {
    next(err);
  }
};

// Fetch details of a specific group
exports.fetchGroupDetails = async (req, res, next) => {
  try {
    const { groupId } = req.params;

    // Validate input
    if (!groupId) {
      return res.status(400).json({ success: false, message: "groupId is required" });
    }

    // Fetch group details
    const fetchGroupQuery = "SELECT * FROM groups WHERE id = ?";
    const [group] = await db.query(fetchGroupQuery, [groupId]);

    if (group.length === 0) {
      return res.status(404).json({ success: false, message: "Group not found" });
    }

    // Fetch participants
    const fetchParticipantsQuery = "SELECT * FROM group_participants WHERE group_id = ?";
    const [participants] = await db.query(fetchParticipantsQuery, [groupId]);

    res.status(200).json({ success: true, group: group[0], participants });
  } catch (err) {
    next(err);
  }
};

// Update group details
exports.updateGroup = async (req, res, next) => {
  try {
    const { groupId } = req.params;
    const { name, description } = req.body;

    // Validate input
    if (!groupId || (!name && !description)) {
      return res.status(400).json({ success: false, message: "groupId and at least one field (name or description) are required" });
    }

    // Update group details
    const updateGroupQuery = "UPDATE groups SET name = ?, description = ? WHERE id = ?";
    await db.query(updateGroupQuery, [name, description, groupId]);

    res.status(200).json({ success: true, message: "Group updated successfully" });
  } catch (err) {
    next(err);
  }
};

// Delete a group
exports.deleteGroup = async (req, res, next) => {
  try {
    const { groupId } = req.params;

    // Validate input
    if (!groupId) {
      return res.status(400).json({ success: false, message: "groupId is required" });
    }

    // Delete group
    const deleteGroupQuery = "DELETE FROM groups WHERE id = ?";
    await db.query(deleteGroupQuery, [groupId]);

    res.status(200).json({ success: true, message: "Group deleted successfully" });
  } catch (err) {
    next(err);
  }
};