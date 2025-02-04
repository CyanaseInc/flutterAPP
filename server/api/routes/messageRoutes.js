const express = require("express");
const messageController = require("../controllers/messageController");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

// Send a message
router.post("/send-message", authMiddleware, messageController.sendMessage);

// Fetch messages for a group
router.get("/fetch-messages", authMiddleware, messageController.fetchMessages);

module.exports = router;