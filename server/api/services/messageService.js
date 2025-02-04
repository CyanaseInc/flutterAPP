const db = require("../config/db");

module.exports = {
    // Save a message to the database
    saveMessage: async (chatId, senderId, content) => {
        const query = "INSERT INTO messages (chat_id, sender_id, content) VALUES (?, ?, ?)";
        const [result] = await db.query(query, [chatId, senderId, content]);

        return {
            chatId,
            senderId,
            content,
            id: result.insertId,
            timestamp: new Date().toISOString(),
        };
    },

    // Fetch messages for a chat
    getMessages: async (chatId) => {
        const query = "SELECT * FROM messages WHERE chat_id = ? ORDER BY timestamp ASC";
        const [messages] = await db.query(query, [chatId]);
        return messages;
    },
};