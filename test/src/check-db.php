<?php

if(isset($_SERVER['DB_HOST']) && isset($_SERVER['DB_DRIVER']) && isset($_SERVER['DB_USER']) && isset($_SERVER['DB_PASSWORD']) && isset($_SERVER['DB_PORT']) && isset($_SERVER['DB_NAME']))

{

        $driver = $_SERVER['DB_DRIVER'];
        $dbname = $_SERVER['DB_NAME'];
        $dbuser = $_SERVER['DB_USER'];
        $dbpass = $_SERVER['DB_PASSWORD'];
        $dbhost = $_SERVER['DB_HOST'];
        $dbport = $_SERVER['DB_PORT'];

        $link = mysqli_connect($dbhost, $dbuser, $dbpass, $dbname, $dbport) or die("Unable to Connect to '$dbhost'");
        mysqli_select_db($link, $dbname) or die("Could not open the db '$dbname'");

        $test_query = "SHOW TABLES FROM $dbname";
        $result = mysqli_query($link, $test_query);

        $tblCnt = 0;
        while($tbl = mysqli_fetch_array($result)) {
         $tblCnt++;
         #echo $tbl[0]."<br />\n";
        }

        if (!$tblCnt) {
            echo "There are no tables<br />\n";
        } else {
            echo "There are $tblCnt tables<br />\n";
        }

        echo "\n";
        echo "Check DB Connection Done.";

}
?>