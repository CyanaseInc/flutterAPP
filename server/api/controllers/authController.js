const authService = require("../services/authService");


exports.testDatabaseConnection = async (req, res) => {
  const result = await authService.testConnection();
  
  if (result.success) {
    return res.status(200).json(result);
  } else {
    return res.status(500).json(result);
  }
};


exports.signup = async (req, res, next) => {
  try {
    const userData = req.body;
    // Validate the incoming user data
    if (!userData.firstName || !userData.lastName || !userData.email || !userData.password) {
      return res.status(400).json({
        success: false,
        message: "First name, last name, email, and password are required",
      });
    }

    const result = await authService.signup(userData);
    return res.status(201).json(result); // Respond with the result from the signup service
  } catch (err) {
    console.error("Signup error:", err);  // Log the error for debugging
    return res.status(500).json({
      success: false,
      message: "Internal server error during signup",
      error: err.message || err,
    });
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Check if email and password are provided
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required",
      });
    }

    // Proceed with the login process if email and password are present
    const result = await authService.login({ email, password });

    if (result.success) {
      return res.status(200).json(result); // Return the login success response
    } else {
      return res.status(401).json({
        success: false,
        message: result.message || "Invalid credentials",
      });
    }
  } catch (err) {
    console.error("Login error:", err);  // Log the error for debugging
    return res.status(500).json({
      success: false,
      message: "Internal server error during login",
      error: err.message || err,
    });
  }
};
