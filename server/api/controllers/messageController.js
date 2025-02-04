const db = require("../config/db");

// Send a message
exports.sendMessage = async (req, res, next) => {
  try {
    const { groupId, senderId, content } = req.body;

    // Validate input
    if (!groupId || !senderId || !content) {
      return res.status(400).json({ success: false, message: "groupId, senderId, and content are required" });
    }

    // Insert the message into the database
    const insertMessageQuery = `
      INSERT INTO messages (group_id, sender_id, content, timestamp)
      VALUES (?, ?, ?, NOW())
    `;
    const [messageResult] = await db.query(insertMessageQuery, [groupId, senderId, content]);

    res.status(201).json({ success: true, message: "Message sent successfully", messageId: messageResult.insertId });
  } catch (err) {
    next(err);
  }
};

// Fetch messages for a group
exports.fetchMessages = async (req, res, next) => {
  try {
    const { groupId } = req.query;

    // Validate input
    if (!groupId) {
      return res.status(400).json({ success: false, message: "groupId is required" });
    }

    // Fetch messages for the group
    const fetchMessagesQuery = "SELECT * FROM messages WHERE group_id = ? ORDER BY timestamp ASC";
    const [messages] = await db.query(fetchMessagesQuery, [groupId]);

    res.status(200).json({ success: true, messages });
  } catch (err) {
    next(err);
  }
};