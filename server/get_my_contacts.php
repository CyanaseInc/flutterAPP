<?php
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Methods: HEAD, GET, POST, PUT, PATCH, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: X-API-KEY, Origin, X-Requested-With, Content-Type, Accept, Access-Control-Request-Method, Access-Control-Request-Headers, Authorization");
header('Content-Type: application/json');
$method = $_SERVER['REQUEST_METHOD'];
if ($method == "OPTIONS") {
    header('Access-Control-Allow-Origin: *');
    header("Access-Control-Allow-Headers: X-API-KEY, Origin, X-Requested-With, Content-Type, Accept, Access-Control-Request-Method, Access-Control-Request-Headers, Authorization");
    header("HTTP/1.1 200 OK");
    die();
}

require_once('config.php');

try {
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    // Validate the input
    if (!isset($data['phoneNumbers']) || !is_array($data['phoneNumbers'])) {
        http_response_code(400); // Bad Request
        echo json_encode(['error' => 'Invalid input: Expected an array of phone numbers.']);
        exit;
    }

    $phoneNumbers = $data['phoneNumbers'];

    // Validate each phone number
    foreach ($phoneNumbers as $phoneNumber) {
        if (!is_string($phoneNumber)) {
            http_response_code(400); // Bad Request
            echo json_encode(['error' => 'Invalid input: Each phone number must be a string.']);
            exit;
        }
    }

    // Prepare a query to find registered contacts
    $placeholders = implode(',', array_fill(0, count($phoneNumbers), '?')); // Create placeholders for the query
    $query = "SELECT phoneno, user_id AS id FROM api_userprofile WHERE phoneno IN ($placeholders)";
    $stmt = $pdo->prepare($query);
    $stmt->execute($phoneNumbers);

    // Fetch the registered contacts
    $registeredContacts = $stmt->fetchAll(PDO::FETCH_ASSOC); // Use FETCH_ASSOC to get associative arrays

    // Return the registered contacts
    echo json_encode([
        'registeredContacts' => $registeredContacts,
       
    ]);
} catch (PDOException $e) {
    // Handle database errors
    http_response_code(500); // Internal Server Error
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
} catch (Exception $e) {
    // Handle other errors
    http_response_code(500); // Internal Server Error
    echo json_encode(['error' => 'Server error: ' . $e->getMessage()]);
}
?>