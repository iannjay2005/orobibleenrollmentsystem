<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}

$conn = new mysqli("localhost", "root", "", "obc_enrollment");

if ($conn->connect_error) {
    die(json_encode(["error" => "Connection failed"]));
}

$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';

if (!empty($email) && !empty($password)) {
    // IMPORTANT: Table name must be 'accounts' to match your DB
    $sql = "INSERT INTO accounts (email, password) VALUES ('$email', '$password')";
    
    if ($conn->query($sql) === TRUE) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => $conn->error]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Empty fields"]);
}

$conn->close();
?>