<?php
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Methods: HEAD, GET, POST, PUT, PATCH, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: X-API-KEY, Origin, X-Requested-With, Content-Type, Accept, Access-Control-Request-Method,Access-Control-Request-Headers, Authorization");
header('Content-Type: application/json');
$method = $_SERVER['REQUEST_METHOD'];
if ($method == "OPTIONS") {
  header('Access-Control-Allow-Origin: *');
  header("Access-Control-Allow-Headers: X-API-KEY, Origin, X-Requested-With, Content-Type, Accept, Access-Control-Request-Method,Access-Control-Request-Headers, Authorization");
  header("HTTP/1.1 200 OK");
  die();
}
require_once('config.php');
try {
    // Connect to the database
    
    // Fetch all users with phone numbers
    $query = "SELECT user_id, phoneno FROM api_userprofile WHERE phoneno IS NOT NULL";
    $stmt = $pdo->query($query);
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Hash each phone number and update the database
    foreach ($users as $user) {
        $phoneNumber = $user['phoneno'];
        $hashedPhoneNumber = hash('sha256', $phoneNumber); // Hash the phone number

        // Update the user's phone_hash in the database
        $updateQuery = "UPDATE api_userprofile SET phone_hash = :phone_hash WHERE user_id = :id";
        $updateStmt = $pdo->prepare($updateQuery);
        $updateStmt->execute([
            ':phone_hash' => $hashedPhoneNumber,
            ':id' => $user['user_id'],
        ]);
    }

    echo "Phone numbers hashed and updated successfully!";
} catch (PDOException $e) {
    // Handle database errors
    echo "Database error: " . $e->getMessage();
} catch (Exception $e) {
    // Handle other errors
    echo "Error: " . $e->getMessage();
}
?>