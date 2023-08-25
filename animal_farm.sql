CREATE TABLE `animal_farm` (
  `identifier` varchar(40) NOT NULL,
  `charidentifier` int NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL,
  `mother` varchar(255) NOT NULL DEFAULT 'nobody',
  `couple` varchar(255) NOT NULL DEFAULT 'nobody',
  `sex` varchar(255) NOT NULL,
  `animaltype` varchar(255) NOT NULL,
  `animal` varchar(255) NOT NULL,
  `actif` int NOT NULL DEFAULT '0',
  `difficulty` int NOT NULL DEFAULT '0',
  `skin` int NOT NULL DEFAULT '0',
  `xp` int DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
