#!/usr/bin/php

<?php

require_once dirname(__FILE__).'/texy-compact.php';

$texy = &new Texy();
$texy->utf = TRUE;	// enable UTF-8

if(!defined("STDIN")) define("STDIN", fopen('php://stdin','r'));

while($line = fgets(STDIN)) $text .= $line;

$html = $texy->process($text);

echo $html;

?>

