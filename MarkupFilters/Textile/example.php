#!/usr/bin/php

<?php

require_once('classTextile.php');

$textile = new Textile();

while($line = fgets(STDIN)) $in .= $line;

echo $textile->TextileThis($in);

?>

