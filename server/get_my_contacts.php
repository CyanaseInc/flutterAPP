<?php
/**
 * App endpoint: fund.cyanase.app / server copy — match contacts via phone_hash (SHA-256).
 *
 * Body: { "phoneNumbers": ["+256 …", "0700…", …] }
 * Optional legacy: { "hashedContacts": ["hex…", …] }
 *
 * Response: { "registeredContacts": [ { "id": "<user_id>", "phoneno": "<raw from request>" }, … ] }
 */
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

function normalize_phone_uganda($phoneNumber) {
    $phoneNumber = preg_replace('/[^0-9+]/', '', $phoneNumber);
    if ($phoneNumber === '') {
        return '';
    }
    if (strpos($phoneNumber, '+') !== 0) {
        $phoneNumber = preg_replace('/^0/', '', $phoneNumber);
        $phoneNumber = '+256' . $phoneNumber;
    }
    return $phoneNumber;
}

function phone_hash_candidates($raw) {
    $trimmed = trim((string)$raw);
    if ($trimmed === '') {
        return [];
    }
    $noSpaces = preg_replace('/\s+/', '', $trimmed);
    $ug = normalize_phone_uganda($trimmed);
    $candidates = array_unique(array_filter([$trimmed, $noSpaces, $ug]));
    return array_values($candidates);
}

function build_hash_to_request_phone_map(array $phoneNumbers) {
    $map = [];
    foreach ($phoneNumbers as $phone) {
        if (!is_string($phone) && !is_numeric($phone)) {
            continue;
        }
        $phone = (string)$phone;
        foreach (phone_hash_candidates($phone) as $candidate) {
            $h = hash('sha256', $candidate);
            if (!isset($map[$h])) {
                $map[$h] = $phone;
            }
        }
    }
    return $map;
}

try {
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    $hashToRequestPhone = [];
    $hashedContacts = null;

    if (isset($data['phoneNumbers']) && is_array($data['phoneNumbers'])) {
        $hashToRequestPhone = build_hash_to_request_phone_map($data['phoneNumbers']);
        $hashedContacts = array_keys($hashToRequestPhone);
    } elseif (isset($data['hashedContacts']) && is_array($data['hashedContacts'])) {
        $hashedContacts = $data['hashedContacts'];
    }

    if (!$hashedContacts || count($hashedContacts) === 0) {
        http_response_code(400);
        echo json_encode([
            'error' => 'Invalid input: send phoneNumbers (array of strings) or hashedContacts (array of SHA-256 hex).',
        ]);
        exit;
    }

    $placeholders = implode(',', array_fill(0, count($hashedContacts), '?'));
    $query = "SELECT user_id, phoneno, phone_hash FROM api_userprofile
              WHERE phone_hash IN ($placeholders) AND phoneno IS NOT NULL AND phone_hash IS NOT NULL AND phone_hash != ''";
    $stmt = $pdo->prepare($query);
    $stmt->execute($hashedContacts);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $registeredContacts = [];
    foreach ($rows as $row) {
        $hash = $row['phone_hash'];
        $phonenoOut = isset($hashToRequestPhone[$hash]) ? $hashToRequestPhone[$hash] : $row['phoneno'];
        $registeredContacts[] = [
            'id' => (string)$row['user_id'],
            'phoneno' => $phonenoOut,
        ];
    }

    echo json_encode([
        'registeredContacts' => $registeredContacts,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Server error: ' . $e->getMessage()]);
}
