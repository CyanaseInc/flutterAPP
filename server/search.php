<?php
header('Access-Control-Allow-Origin: *');
header("Access-Control-Allow-Methods: HEAD, GET, POST, PUT, PATCH, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: X-API-KEY, Origin, X-Requested-With, Content-Type, Accept, Access-Control-Request-Method, Access-Control-Request-Headers, Authorization");
header('Content-Type: application/json');

// Handle preflight requests
$method = $_SERVER['REQUEST_METHOD'];
if ($method == "OPTIONS") {
    header("HTTP/1.1 200 OK");
    exit;
}

require_once('config.php'); // Ensure this file correctly initializes $pdo

// Read the request data
$query = isset($_POST['query']) ? trim($_POST['query']) : '';

if (empty($query)) {
    echo json_encode(["error" => "Search query is empty"]);
    exit;
}

// Secure the query using prepared statements
$query = "%{$query}%"; // Using wildcards for LIKE search

// Prepare the SQL query with parameterized statements
$sql = "SELECT auth_user.id, auth_user.first_name, auth_user.last_name, api_userprofile.phoneno, api_userprofile.profile_picture 
        FROM auth_user 
        JOIN api_userprofile ON auth_user.id = api_userprofile.user_id
        WHERE api_userprofile.phoneno LIKE ? 
        LIMIT 3"; // LIMIT is used to restrict the number of results

// Execute the prepared statement
$stmt = $pdo->prepare($sql);
$stmt->execute([$query]);
$result = $stmt->fetchAll(PDO::FETCH_ASSOC);

if (empty($result)) {
    echo json_encode([
        "message" => "No contacts found matching the search criteria"
    ]);
    exit;
}

$contacts = [];

// Format the result data for the response
foreach ($result as $row) {
    $contacts[] = [
        'id' => $row['id'],
        'name' => $row['first_name'].' '.$row['last_name'], // Combine first and last name
        'phone_number' => $row['phoneno'],  // Use 'phoneno' directly
        'profilePic' => $row['profile_picture'] ?? '' // Use the null coalescing operator for profilePic
    ];
}

// Return JSON response with contacts
echo json_encode($contacts);
?>
