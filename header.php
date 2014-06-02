<!DOCTYPE html>
<html>
<head>
<?php
$ch = curl_init("http://web1.atl.grizzard.com/host.php");
curl_setopt($ch, CURLOPT_RETURNTRANSFER ,TRUE);
$status = curl_exec($ch);
 ?>
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script> 
<!-- <link href="//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css" rel="stylesheet"> -->
<link href="//netdna.bootstrapcdn.com/bootswatch/3.1.1/spacelab/bootstrap.min.css" rel="stylesheet">
<script src="//netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"></script>
</head>
<body>

<div class="container">
	<div class="row clearfix">
		<div class="col-md-12 column">
			<nav class="navbar navbar-inverse" role="navigation">
				<div class="navbar-header">
					 <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1"> <span class="sr-only">Toggle navigation</span><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button> <a class="navbar-brand" href="#">Grizzard Web Hosting Control</a>
				</div>
				
				<div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
					<ul class="nav navbar-nav">
						<li class="dropdown">
							 <a href="#" class="dropdown-toggle" data-toggle="dropdown">Node Setup<strong class="caret"></strong></a>
							<ul class="dropdown-menu">
								<li>
									<a href="add-node.php">Add Server</a>
								</li>
								<li>
									<a href="#">Delete Server</a>
								</li>
								<li class="divider">
								</li>
								<li>
									<a href="#">View Cluster Status</a>
								</li>
							</ul>
						</li>

						<li class="dropdown">
							 <a href="#" class="dropdown-toggle" data-toggle="dropdown">Live Server<strong class="caret"></strong></a>
							<ul class="dropdown-menu">
								<li>
									<a href="add-site-live.php">Add Site</a>
								</li>
								<li>
									<a href="#">Delete Site</a>
								</li>
								<li class="divider">
								</li>
								<li>
									<a href="#">View Status</a>
								</li>
							</ul>
						</li>

						<li class="dropdown">
							 <a href="#" class="dropdown-toggle" data-toggle="dropdown">Development Server<strong class="caret"></strong></a>
							<ul class="dropdown-menu">
								<li>
									<a href="add-site-dev.php">Add Site</a>
								</li>
								<li>
									<a href="#">Delete Site</a>
								</li>
								<li class="divider">
								</li>
								<li>
									<a href="#">View Status</a>
								</li>
							</ul>
						</li>
						


					</ul>
				</div>
				
			</nav>

