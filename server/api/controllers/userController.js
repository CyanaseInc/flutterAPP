const db = require("../config/db");

// Update user profile
exports.updateProfile = async (req, res, next) => {
  try {
    const { userId, firstName, lastName, email, phoneNumber, country, birthDate, gender, address } = req.body;

    // Validate input
    if (!userId) {
      return res.status(400).json({ success: false, message: "userId is required" });
    }

    // Update user profile in the database
    const updateProfileQuery = `
      UPDATE users
      SET first_name = ?, last_name = ?, email = ?, phone_number = ?, country = ?, birth_date = ?, gender = ?, address = ?
      WHERE id = ?
    `;
    await db.query(updateProfileQuery, [firstName, lastName, email, phoneNumber, country, birthDate, gender, address, userId]);

    res.status(200).json({ success: true, message: "Profile updated successfully" });
  } catch (err) {
    next(err);
  }
};

// Fetch user details
exports.fetchUserDetails = async (req, res, next) => {
  try {
    const { userId } = req.query;

    // Validate input
    if (!userId) {
      return res.status(400).json({ success: false, message: "userId is required" });
    }

    // Fetch user details from the database
    const fetchUserQuery = "SELECT * FROM users WHERE id = ?";
    const [user] = await db.query(fetchUserQuery, [userId]);

    if (user.length === 0) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    res.status(200).json({ success: true, user: user[0] });
  } catch (err) {
    next(err);
  }
};