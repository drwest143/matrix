<pre><?php


foreach ($_REQUEST as $key => $value) {
	# code...
	$$key=$value;
}



$con = new mysqli('db1.atl.grizzard.com','dwest','Mexico143','glb_process');
$sql = "insert into `site-add` (`sitename`,`dbname`,`dbpass`,`ssl`,`sitetype`) values ('".$sitename."','".$dbname."','".$dbpass."','".$ssl."','".$sitetype."');";

if ($mysqli->connect_error) {
    die('Connect Error: ' . $mysqli->connect_error);
}

$res = $con->query($sql);

header('Location: http://'.$_SERVER['SERVER_NAME'].'/matrix/'.$redirect);

//$output = shell_exec('/var/www/html/matrix/process/site-add.sh test.grizzard.com');
print_r(get_defined_vars());
?></pre>