const messageService = require("../services/messageService");

module.exports = (io) => {
    io.on("connection", (socket) => {
        console.log("User connected:", socket.id);

        // Handle sending messages
        socket.on("sendMessage", async (data) => {
            const { chatId, senderId, content } = data;

            // Validate input
            if (!chatId || !senderId || !content) {
                console.error("Invalid message data:", data);
                return;
            }

            try {
                // Save message to the database
                const message = await messageService.saveMessage(chatId, senderId, content);

                // Broadcast the message to the chat room
                io.to(chatId).emit("receiveMessage", message);
            } catch (err) {
                console.error("Error saving message:", err);
            }
        });

        // Handle joining a chat room
        socket.on("joinChat", (chatId) => {
            if (!chatId) {
                console.error("Invalid chat ID:", chatId);
                return;
            }

            socket.join(chatId);
            console.log(`User ${socket.id} joined chat: ${chatId}`);
        });

        // Handle disconnection
        socket.on("disconnect", () => {
            console.log("User disconnected:", socket.id);
        });
    });
};