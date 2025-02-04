const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
require("dotenv").config();
const db = require("./config/db");
const authRoutes = require("./routes/authRoutes");
const groupRoutes = require("./routes/groupRoutes");
const messageRoutes = require("./routes/messageRoutes");
const userRoutes = require("./routes/userRoutes");
const errorHandler = require("./middleware/errorHandler");

const app = express();
const server = http.createServer(app);
const io = new Server(server);

// Middleware
app.use(express.json());

// Routes
app.use("/auth", authRoutes);
app.use("/groups", groupRoutes);
app.use("/messages", messageRoutes);
app.use("/users", userRoutes);

// Root route
app.use('/public',express.static(__dirname +"/public"));
app.get("/", (req, res) => {
  res.send("Hello, World! This is my Node.js backend hahaha.");
});

// Error handling middleware
app.use(errorHandler);

// WebSocket connection
io.on("connection", (socket) => {
  console.log("User connected:", socket.id);

  socket.on("disconnect", () => {
    console.log("User disconnected:", socket.id);
  });
});

// Start the server
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || "0.0.0.0"; // Bind to all network interfaces

server.listen(PORT, HOST, () => {
  console.log(`Server running on http://${HOST}:${PORT}`);
});