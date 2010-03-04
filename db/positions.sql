-- MySQL dump 10.13  Distrib 5.1.44, for unknown-linux-gnu (x86_64)
--
-- Host: localhost    Database: active_trader_production
-- ------------------------------------------------------
-- Server version	5.1.37-1ubuntu5.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `positions`
--

DROP TABLE IF EXISTS `positions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `positions` (
  `ticker_id` int(11) NOT NULL DEFAULT '0',
  `ettime` datetime DEFAULT NULL,
  `etprice` float DEFAULT NULL,
  `etival` float DEFAULT NULL,
  `xttime` datetime DEFAULT NULL,
  `xtprice` float DEFAULT NULL,
  `xtival` float DEFAULT NULL,
  `entry_date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `entry_price` float DEFAULT NULL,
  `entry_ival` float DEFAULT NULL,
  `exit_date` datetime DEFAULT NULL,
  `exit_price` float DEFAULT NULL,
  `exit_ival` float DEFAULT NULL,
  `days_held` int(11) DEFAULT NULL,
  `nreturn` float DEFAULT NULL,
  `logr` float DEFAULT NULL,
  `short` tinyint(1) DEFAULT NULL,
  `closed` tinyint(1) DEFAULT NULL,
  `entry_pass` int(11) DEFAULT NULL,
  `roi` float DEFAULT NULL,
  `num_shares` int(11) DEFAULT NULL,
  `etind_id` int(11) DEFAULT NULL,
  `xtind_id` int(11) DEFAULT NULL,
  `entry_trigger_id` int(11) DEFAULT NULL,
  `entry_strategy_id` int(11) DEFAULT NULL,
  `exit_trigger_id` int(11) DEFAULT NULL,
  `exit_strategy_id` int(11) DEFAULT NULL,
  `scan_id` int(11) DEFAULT NULL,
  `consumed_margin` float DEFAULT NULL,
  `eind_id` int(11) DEFAULT NULL,
  `xind_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`ticker_id`,`entry_date`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1
/*!50100 PARTITION BY RANGE (year(entry_date))
(PARTITION p0 VALUES LESS THAN (2000) ENGINE = MyISAM,
 PARTITION p1 VALUES LESS THAN (2001) ENGINE = MyISAM,
 PARTITION p2 VALUES LESS THAN (2002) ENGINE = MyISAM,
 PARTITION p3 VALUES LESS THAN (2003) ENGINE = MyISAM,
 PARTITION p4 VALUES LESS THAN (2004) ENGINE = MyISAM,
 PARTITION p5 VALUES LESS THAN (2005) ENGINE = MyISAM,
 PARTITION p6 VALUES LESS THAN (2006) ENGINE = MyISAM,
 PARTITION p7 VALUES LESS THAN (2007) ENGINE = MyISAM,
 PARTITION p8 VALUES LESS THAN (2008) ENGINE = MyISAM,
 PARTITION p9 VALUES LESS THAN (2009) ENGINE = MyISAM,
 PARTITION p10 VALUES LESS THAN (2010) ENGINE = MyISAM,
 PARTITION p11 VALUES LESS THAN (2011) ENGINE = MyISAM,
 PARTITION p12 VALUES LESS THAN MAXVALUE ENGINE = MyISAM) */;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2010-03-01 21:36:52
