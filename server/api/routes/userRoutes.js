const express = require("express");
const userController = require("../controllers/userController");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

// Update user profile
router.put("/update-profile", authMiddleware, userController.updateProfile);

// Fetch user details
router.get("/fetch-user-details", authMiddleware, userController.fetchUserDetails);

module.exports = router;