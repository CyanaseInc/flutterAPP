const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const mysql = require("mysql");

const app = express();
const server = http.createServer(app);
const io = new Server(server);

// MySQL Connection
const db = mysql.createConnection({
    host: "localhost",
    user: "message_sever",
    password: "Q_@#%QWanio?_178poIjgd",
    database: "cyanase_app",
});

db.connect((err) => {
    if (err) {
        console.error("MySQL connection error:", err);
        return;
    }
    console.log("Connected to MySQL!");
});

io.on("connection", (socket) => {
    console.log("User connected:", socket.id);

    socket.on("sendMessage", (data) => {
        const { chatId, senderId, content } = data;
        const query = "INSERT INTO messages (chat_id, sender_id, content) VALUES (?, ?, ?)";
        db.query(query, [chatId, senderId, content], (err, result) => {
            if (err) {
                console.error("Error saving message:", err);
                return;
            }
            io.to(chatId).emit("receiveMessage", { chatId, senderId, content });
        });
    });

    socket.on("joinChat", (chatId) => {
        socket.join(chatId);
        console.log(`User joined chat: ${chatId}`);
    });

    socket.on("disconnect", () => {
        console.log("User disconnected:", socket.id);
    });
});

server.listen(3000, () => {
    console.log("Server running on port 3000");
});
