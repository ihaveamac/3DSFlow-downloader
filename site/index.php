<?php
// https://github.com/ihaveamac/3DSFlow-downloader
// Licensed under the MIT license - see `LICENSE.md` at project root for details

// most of this is probably a bad idea but it works so shut up unless you can make it better :)

if (!isset($_SERVER['HTTPS']) || $_SERVER['HTTPS'] == ""){
    $redirect = "https://".$_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI'];
    header("HTTP/1.1 301 Moved Permanently");
    header("Location: $redirect");
    exit; // Don't kill him :'(
}

$regions = array("USA", "EUR", "GER", "AUS", "JPN");
$other_types = array("Homebrew", "Custom", "Templates", "Make" => "Make your own!");
$types = array_merge($regions, $other_types);
if (isset($_GET["type"])) {
    if (!in_array($_GET["type"], $types)) {
        header("Location: https://".$_SERVER['HTTP_HOST']."/3dsflow/");
        die;
    }
    $is_region = in_array($_GET['type'], $regions);
}

function listImages($dir) {
    $files = scandir($dir);
    foreach ($files as $file) {
        if ($file[0] != "." && $file[0] != "!" && $file != "header.php") {
            echo '<div class="banner-img col-xs-12 col-sm-4 col-md-3 col-lg-3"><div><a href="'.$dir.'/'.$file.'"><img src="'.$dir.'/'.$file.'"></a></div></div>'."\n";
        }
    }
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>3DSFlow Banners<?php echo ((isset($_GET["type"])) ? " - ".$_GET["type"] : " for the Grid Launcher"); ?></title>
    <link href='https://fonts.googleapis.com/css?family=Ubuntu:400,700' rel='stylesheet' type='text/css'>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: 'Ubuntu', sans-serif;
            /*text-align: center;*/
        }
        #types {
            font-size: 20px;
        }
        .banner-img div {
            display: inline-block;
            width: 246px;
            height: 216px;
            overflow: hidden;
            margin: 0 -10px -10px -10px;
        }
        .banner-img div img {
            position: relative;
            left: -77px;
        }
        .navbar {
            border-radius: 0 0 4px 4px;
            border-top: 0;
        }
    </style>
</head>
<body>
<div class="container">
    <div class="navbar navbar-inverse" role="navigation">
        <div class="container-fluid">
            <!-- Brand and toggle get grouped for better mobile display -->
            <div class="navbar-header">
                <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1" aria-expanded="false">
                    <span class="sr-only">Toggle navigation</span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                </button>
                <a class="navbar-brand" href="/3dsflow/">3DSFlow Banners</a>
            </div>

            <!-- Collect the nav links, forms, and other content for toggling -->
            <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
                <ul class="nav navbar-nav">
                    <?php foreach ($types as $k => $v): ?>
                        <?php if (is_int($k)): ?>
                            <li<?php if ($_GET["type"] === $v) echo ' class="active"'; ?>><a href="?type=<?= $v ?>"><?= $v ?></a></li>
                        <?php else: ?>
                            <li<?php if ($_GET["type"] === $k) echo ' class="active"'; ?>><a href="?type=<?= $k ?>"><?= $v ?></a></li>
                        <?php endif; ?>
                    <?php endforeach; ?>
                </ul>
            </div><!-- /.navbar-collapse -->
        </div><!-- /.container-fluid -->
    </div>
    <p><a href="https://github.com/mashers/3ds_hb_menu/wiki/Banners">How to use Banners</a> &mdash; Click an image to download it!</p>
    <div id="banners">
        <?php
        if (isset($_GET["type"])) {
            if (file_exists("banners/".$_GET["type"]."/header.php")) {
                include("banners/".$_GET["type"]."/header.php");
            }
            echo "<hr>";
            if ($is_region) {
                echo "<div class=\"container\"><h2>Retail</h2>";
                listImages("banners/".$_GET["type"]."/retail");
                echo "</div><div class=\"container\"><h2>Nintendo eShop</h2>";
                listImages("banners/".$_GET["type"]."/eshop");
                echo "</div><div class=\"container\"><h2>Virtual Console</h2>";
                listImages("banners/".$_GET["type"]."/vc");
                echo "</div>";
            } elseif ($_GET["type"] == "Homebrew") {
                echo "<div class=\"container\"><h2>General</h2>";
                listImages("banners/".$_GET["type"]."/general");
                echo "</div><div class=\"container\"><h2>Emulators</h2>";
                listImages("banners/".$_GET["type"]."/emulators");
                echo "</div>";
            } else {
                echo "<div class=\"container\">";
                listImages("banners/".$_GET["type"]);
                echo "</div>";
            }
        }
        ?>
        <hr>
        <div class="container"><p>
                <a href="https://gbatemp.net/threads/gridlauncher-3dsflow-project-box-cover-banners.405303/">GBAtemp thread</a> &mdash; <a href="https://github.com/ihaveamac/3DSFlow-downloader">Site source code on GitHub</a> &mdash; <a href="https://ianburgwin.net/">ianburgwin.net</a>
            </p></div>
    </div>
</div>
<script src="//code.jquery.com/jquery-1.11.3.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js" integrity="sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS" crossorigin="anonymous"></script>
</body>
</html>
