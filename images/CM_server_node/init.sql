SET GLOBAL validate_password_policy=LOW;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'hadoop123';
CREATE DATABASE scm 	  DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE amon 	  DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE rman 	  DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE hue 	  DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE hive      DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE sentry 	  DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE nav 	  DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE navms 	  DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE oozie 	  DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

GRANT ALL ON scm.*      TO 'scm'@'%' IDENTIFIED BY 'hadoop123';
GRANT ALL ON amon.*     TO 'amon'@'%' IDENTIFIED BY 'hadoop123';
GRANT ALL ON rman.*     TO 'rman'@'%' IDENTIFIED BY 'hadoop123';
GRANT ALL ON hue.*      TO 'hue'@'%' IDENTIFIED BY 'hadoop123';
GRANT ALL ON hive.*     TO 'hive'@'%' IDENTIFIED BY 'hadoop123';
GRANT ALL ON sentry.*   TO 'sentry'@'%' IDENTIFIED BY 'hadoop123';
GRANT ALL ON nav.*      TO 'nav'@'%' IDENTIFIED BY 'hadoop123';
GRANT ALL ON navms.*    TO 'navms'@'%' IDENTIFIED BY 'hadoop123';
GRANT ALL ON oozie.*    TO 'oozie'@'%' IDENTIFIED BY 'hadoop123';
flush privileges;










