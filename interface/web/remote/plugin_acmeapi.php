<?php

define('USERNAME', 'ispconfigremoteuser');
define('PASSWORD', 'XXXchangemeXXX');
define('SOAP_LOCATION', 'https://localhost:8080/remote/index.php');
define('SOAP_URI', 'https://localhost:8080/remote/');

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");


if (isset($_SERVER['HTTP_AUTH_TOKEN'])) {
    $authHeader = $_SERVER['HTTP_AUTH_TOKEN'];
    $key = $authHeader;
} else {
    echo json_encode(["message" => "FAIL - No API Key "]);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];
$request = explode('/', trim($_SERVER['PATH_INFO'] ?? '', '/'));

switch ($method) {
    case 'POST':
        if ($_SERVER['PATH_INFO'] == '/records') {
            $input = json_decode(file_get_contents('php://input'), true);
            $domain = $input['domain'];
            $txt = $input['txt'];
            create_record($domain, $txt, $key);
            echo json_encode(["message" => "SUCCESS - TXT record added"]);
        }
        break;

    case 'DELETE':
        if ($_SERVER['PATH_INFO'] == '/records') {
            $domain = $_GET['domain'] ?? null;
            delete_record($domain,$key);
            echo json_encode(["message" => "SUCCESS - TXT record removed"]);
        }

}

function delete_record($record, $key) {
    $con = apiConnect();
    $session_id = $con['session_id'];
    $client = $con['client'];

    list($acmetxt, $url) = explode('.', $record, 2);
    $parts = explode('.', $url);
    while (count($parts) > 1) {
        // Join the parts back into a string
        $zone = implode('.', $parts);
        try {
            $zone_id = $client->dns_zone_get_id($session_id, $zone);
            $zone_rec = $client->dns_zone_get($session_id, $zone_id);
            $apikey = $zone_rec['plugin_acmeapi_key'];
        } catch (SoapFault $e) { }
        if ($apikey == $key) { // found deepest Zone
            break;
        }
        array_shift($parts);
    }

    // If no Zone with key found
    if (!(is_numeric($zone_id))) {
        echo json_encode(["message" => "FAIL - No zone found or key wrong"]);
        exit;
    }

    $apikey = $zone_rec['plugin_acmeapi_key'];
    if ($apikey != $key) { //check again
        echo json_encode(["message" => "FAIL - Wrong API Key for $zone"]);
        exit;
    }

    $allRerecords = $client->dns_rr_get_all_by_zone($session_id, $zone_id);
    $recordId = 0;
    foreach ($allRerecords as $rr) {
        if ($rr['zone'] == $zone_id && $rr['name'] == $record.'.') {
            $recordId = $rr['id'];
        }
    }

    if (!(is_numeric($recordId))) {
        echo json_encode(["message" => "FAIL - No Record found"]);
        exit;
    }

    try{
        $client->dns_txt_delete($session_id, $recordId);
        $client->logout($session_id);
    } catch (SoapFault $e) {
        die('SOAP Error: ' . $e->getMessage());
    }
}

function create_record($record,$txt,$key) {
    $con = apiConnect();
    $session_id = $con['session_id'];
    $client = $con['client'];


    list($acmetxt, $url) = explode('.', $record, 2);

    $parts = explode('.', $url);
    while (count($parts) > 1) {
        // Join the parts back into a string
        $zone = implode('.', $parts);
        try {
            $zone_id = $client->dns_zone_get_id($session_id, $zone);
            $zone_rec = $client->dns_zone_get($session_id, $zone_id);
            $apikey = $zone_rec['plugin_acmeapi_key'];
        } catch (SoapFault $e) { }
        if ($apikey == $key) { // found deepest Zone
            break;
        }
        array_shift($parts);
    }

    // If no Zone with key found
    if (!(is_numeric($zone_id))) {
        echo json_encode(["message" => "FAIL - No Zone found or Key wrong"]);
        exit;
    }

    $client_id = $client->client_get_id($session_id, $zone_rec['sys_userid']);
    $server_id = $zone_rec['server_id'];

    $apikey = $zone_rec['plugin_acmeapi_key'];
    if ($apikey != $key) { //check again
        echo json_encode(["message" => "FAIL - Wrong API Key for $zone"]);
        exit;
    }
    try{
        $mydate = date("Y-m-d H:i:s");
        $params = [
            'server_id' => $server_id,
            'zone' => $zone_id,
            'type' => 'TXT',
            'name' => $record.'.',
            'data' => $txt,
            'ttl' => '900',
            'aux' => '10',
            'active' => 'y',
            'stamp' => $mydate,
        ];
        $client->dns_txt_add($session_id, $client_id, $params, true);
        $client->logout($session_id);

    } catch (SoapFault $e) {
        die('SOAP Error: ' . $e->getMessage());
    }
}
function apiConnect () {
    $context = stream_context_create([
        'ssl' => [
            'verify_peer' => true,
            'verify_peer_name' => false, //because localhost is not in SAN
            'allow_self_signed' => false
        ]
    ]);

    try {
        $client = new SoapClient(null, array('location' => SOAP_LOCATION,
                'uri' => SOAP_URI,
                'stream_context' => $context)
        );

        //* Login to the remote server
        if (!($session_id = $client->login(USERNAME, PASSWORD))) {
            echo 'Loggin failed';
        }
    } catch (SoapFault $e) {
        die('SOAP Error: ' . $e->getMessage());
    }
    return ["session_id" => $session_id, "client" => $client ];
}
?>;
