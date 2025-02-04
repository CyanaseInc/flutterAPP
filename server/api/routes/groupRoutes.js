const express = require("express");
const groupController = require("../controllers/groupController");
const authMiddleware = require("../middleware/authMiddleware"); // Optional: Add authentication middleware

const router = express.Router();

// Create a new group
router.post("/create-group", authMiddleware, groupController.createGroup);

// Join a group
router.post("/join-group", authMiddleware, groupController.joinGroup);

// Fetch all groups for a user
router.get("/fetch-groups", authMiddleware, groupController.fetchGroups);

// Fetch details of a specific group
router.get("/:groupId", authMiddleware, groupController.fetchGroupDetails);

// Update group details
router.put("/:groupId", authMiddleware, groupController.updateGroup);

// Delete a group
router.delete("/:groupId", authMiddleware, groupController.deleteGroup);

module.exports = router;