
const bcrypt = require('bcryptjs'); 



const db = require('../config/db');  // Assuming db is set up in a separate file

// Test the database connection
exports.testConnection = async () => {
  try {
    // Simple test query
    const testQuery = "SELECT 1 AS test";
    const [result] = await db.query(testQuery);  // Execute query
    console.log("Database connection successful: ", result);  // Log the result
    return { success: true, message: "Database connection is successful" };
  } catch (error) {
    console.error("Error connecting to database: ", error);  // Log the error
    return { success: false, message: "Database connection failed", error: error.message };
  }
};

exports.signup = async (userData) => {
  const { firstName, lastName, email, password, phoneNumber, country, birthDate, gender, address } = userData;

  try {
    // Check if the email already exists
    const emailExistsQuery = "SELECT * FROM auth_user WHERE email = ?";
    console.error("Executing query: ", emailExistsQuery, [email]);  // Log the query
    const [emailExists] = await db.query(emailExistsQuery, [email]);
    console.error("Email exists check result: ", emailExists);  // Log the result

    if (emailExists.length > 0) {
      throw new Error("Email already exists");
    }

    // Check if the phone number already exists
    const phoneExistsQuery = "SELECT * FROM api_userprofile WHERE phoneno = ?";
    console.error("Executing query: ", phoneExistsQuery, [phoneNumber]);  // Log the query
    const [phoneExists] = await db.query(phoneExistsQuery, [phoneNumber]);
    console.error("Phone exists check result: ", phoneExists);  // Log the result

    if (phoneExists.length > 0) {
      throw new Error("Phone number already exists");
    }

    // Insert into auth_user table
    const insertAuthUserQuery = `
      INSERT INTO auth_user (first_name, last_name, email, password, date_joined)
      VALUES (?, ?, ?, ?, NOW())
    `;
    console.error("Executing query: ", insertAuthUserQuery, [firstName, lastName, email, password]);  // Log the query
    const [authUserResult] = await db.query(insertAuthUserQuery, [firstName, lastName, email, password]);
    console.error("Insert auth_user result: ", authUserResult);  // Log the result

    // Insert into api_userprofile table
    const insertUserProfileQuery = `
      INSERT INTO api_userprofile (
        user_id, phoneno, country, birth_date, gender, address, is_verified, is_deleted, is_disabled, created
      )
      VALUES (?, ?, ?, ?, ?, ?, 0, 0, 0, NOW())
    `;
    console.error("Executing query: ", insertUserProfileQuery, [authUserResult.insertId, phoneNumber, country, birthDate, gender, address]);  // Log the query
    await db.query(insertUserProfileQuery, [authUserResult.insertId, phoneNumber, country, birthDate, gender, address]);

    const userId = authUserResult.insertId;
    return { success: true, message: "User created successfully", userId };
  } catch (error) {
    console.error("Error during signup: ", error);
    throw new Error("Internal server error during signup");
  }
};

// Import bcrypt for password comparison

exports.login = async (credentials) => {
  const { email, password } = credentials;

  try {
    // Query the database for the user
    const query = "SELECT * FROM auth_user WHERE email = ?";
    console.error("Executing query: ", query, [email]);  // Log the query
    const result = await db.query(query, [email]);
    console.error("Login query result: ", result);  // Log the result

    // Check if the result is not iterable (i.e., empty or null)
    if (!result || result.length === 0) {
      throw new Error("Invalid email or password");
    }

    const user = result[0]; // Ensure you are using the correct row
    // Compare password using bcrypt
    const isPasswordCorrect = await bcrypt.compare(password, user.password);
    if (!isPasswordCorrect) {
      throw new Error("Invalid email or password");
    }

    return { success: true, message: "Login successful", user };
  } catch (error) {
    console.error("Error during login: ", error);
    throw new Error(error.message || "Internal server error during login");
  }
};
;