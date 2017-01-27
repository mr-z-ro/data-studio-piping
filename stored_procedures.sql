# Create stored procedure that creates the google_data_studio_new db and tables
CREATE DEFINER=`root`@`%` PROCEDURE openair_new.create_google_data_studio_new_db_and_tables()
BEGIN
  # Create DB
  CREATE DATABASE google_data_studio_new;
  
  # Create Table to hold transformed timesheets
  CREATE TABLE google_data_studio_new.timesheets (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `timesheet_id` int(11) NOT NULL,
  `entry_date` date NOT NULL DEFAULT '0000-00-00',
  `associate` varchar(200) NOT NULL DEFAULT '',
  `practice` varchar(200) NOT NULL DEFAULT '',
  `client_name` varchar(200) NOT NULL DEFAULT '',
  `project_name` varchar(200) NOT NULL DEFAULT '',
  `task_name` varchar(200) NOT NULL DEFAULT '',
  `hours` decimal(12,2) NOT NULL DEFAULT '0.00',
  `associate_task_rate` decimal(12,2) NOT NULL DEFAULT '0.00',
  `associate_task_currency` char(3) NOT NULL DEFAULT '',
  `dollars` decimal(12,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`id`),
  KEY `date` (`entry_date`),
  KEY `associate` (`associate`),
  KEY `project_name` (`project_name`),
  KEY `task_name` (`task_name`)
  ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
  
  # Create Table to hold transformed bookings
  CREATE TABLE google_data_studio_new.bookings (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `associate` varchar(200) NOT NULL DEFAULT '',
  `practice` varchar(200) NOT NULL DEFAULT '',
  `client_name` varchar(200) NOT NULL DEFAULT '',
  `project_name` varchar(200) NOT NULL DEFAULT '',
  `task_name` varchar(200) NOT NULL DEFAULT '',
  `booking_type` varchar(200) NOT NULL DEFAULT '',
  `start_date` date NOT NULL DEFAULT '0000-00-00',
  `end_date` date NOT NULL DEFAULT '0000-00-00',
  `hours` decimal(12,2) NOT NULL DEFAULT '0.00',
  `percentage` decimal(12,2) NOT NULL DEFAULT '0.00',
  `booking_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `booking_updated` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `associate_task_rate` decimal(12,2) NOT NULL DEFAULT '0.00',
  `associate_task_currency` char(3) NOT NULL DEFAULT '',
  `dollars` decimal(12,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`id`)
  ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
  
  # Create Table to hold transformed daily bookings
  CREATE TABLE google_data_studio_new.bookings_daily (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `booking_id` int(11) NOT NULL DEFAULT '-1',
  `associate` varchar(200) NOT NULL DEFAULT '',
  `practice` varchar(200) NOT NULL DEFAULT '',
  `client_name` varchar(200) NOT NULL DEFAULT '',
  `project_name` varchar(200) NOT NULL DEFAULT '',
  `task_name` varchar(200) NOT NULL DEFAULT '',
  `booking_type` varchar(200) NOT NULL DEFAULT '',
  `start_date` date NOT NULL DEFAULT '0000-00-00',
  `end_date` date NOT NULL DEFAULT '0000-00-00',
  `date` date NOT NULL DEFAULT '0000-00-00',
  `week_of_booking` int(3) NOT NULL DEFAULT '0',
  `week_of_year` int(3) NOT NULL DEFAULT '0',
  `week_of_year_iso` char(3) DEFAULT NULL,
  `total_booking_hours` decimal(12,2) NOT NULL DEFAULT '0.00',
  `hours` decimal(12,8) NOT NULL DEFAULT '0.00000000',
  `percentage` decimal(12,2) NOT NULL DEFAULT '0.00',
  `booking_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `booking_updated` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `associate_task_rate` decimal(12,2) NOT NULL DEFAULT '0.00',
  `associate_task_currency` char(3) NOT NULL DEFAULT '',
  `dollars` decimal(12,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`id`),
  KEY `date` (`date`),
  KEY `associate` (`associate`),
  KEY `project_name` (`project_name`),
  KEY `task_name` (`task_name`)
  ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
  
  # Create Table to hold transformed daily bookings & timesheets
  CREATE TABLE google_data_studio_new.timesheets_vs_bookings_daily (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `timesheets_id` int(11) NOT NULL,
  `bookings_daily_id` int(11) NOT NULL DEFAULT '-1',
  `associate` varchar(200) NOT NULL DEFAULT '',
  `practice` varchar(200) NOT NULL DEFAULT '',
  `client_name` varchar(200) NOT NULL DEFAULT '',
  `project_name` varchar(200) NOT NULL DEFAULT '',
  `task_name` varchar(200) NOT NULL DEFAULT '',
  `date` date NOT NULL DEFAULT '0000-00-00',
  `week_of_booking` int(3) NOT NULL DEFAULT '0',
  `week_of_year_iso` char(3) DEFAULT NULL,
  `booking_hours` decimal(12,8) NOT NULL DEFAULT '0.00000000',
  `booking_fees` decimal(12,2) NOT NULL DEFAULT '0.00',
  `timesheet_hours` decimal(12,2) NOT NULL DEFAULT '0.00',
  `timesheet_fees` decimal(12,2) NOT NULL DEFAULT '0.00',
  `associate_currency` char(3) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
  ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
  
  # Create table to hold transformed expenses (envelopes)
  CREATE TABLE google_data_studio_new.expenses (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `associate` varchar(200) NOT NULL DEFAULT '',
  `practice` varchar(200) NOT NULL DEFAULT '',
  `client_name` varchar(200) NOT NULL DEFAULT '',
  `project_name` varchar(200) NOT NULL DEFAULT '',
  `total` decimal(17,3) NOT NULL DEFAULT '0.000',
  `currency` char(3) NOT NULL DEFAULT '',
  `date` date NOT NULL DEFAULT '0000-00-00',
  `year` int(4) NOT NULL DEFAULT '0',
  `week_of_year` int(3) NOT NULL DEFAULT '0',
  `week_of_year_iso` char(3) DEFAULT NULL,
  PRIMARY KEY (`id`)
  ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
  
  # Create Table to hold list of dates for transforming bookings from range to daily
  CREATE TABLE google_data_studio_new.all_dates (
  `dt` datetime NOT NULL,
  PRIMARY KEY (`dt`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
END ;
#$#$#$

# Call stored procedure that creates the google_data_studio_new db and tables
CALL openair_new.create_google_data_studio_new_db_and_tables();

# Create function to count weekdays in a range
#$#$#$

CREATE FUNCTION openair_new.TOTAL_WEEKDAYS(date1 DATE, date2 DATE)
RETURNS INT
RETURN ABS(DATEDIFF(date2, date1)) + 1
     - ABS(DATEDIFF(ADDDATE(date2, INTERVAL 1 - DAYOFWEEK(date2) DAY),
                    ADDDATE(date1, INTERVAL 1 - DAYOFWEEK(date1) DAY))) / 7 * 2
     - (DAYOFWEEK(IF(date1 < date2, date1, date2)) = 1)
     - (DAYOFWEEK(IF(date1 > date2, date1, date2)) = 7);

# Create stored procedure that populates the google_data_studio_new tables
#$#$#$
CREATE DEFINER=`root`@`%` PROCEDURE openair_new.populate_google_data_studio_new_tables()
BEGIN
	# For all_dates table
	DECLARE dateStart DATE DEFAULT DATE('2010-01-01');
	DECLARE dateEnd DATE DEFAULT DATE('2025-12-31');

	# Populate last 12 months of timesheets
	INSERT INTO google_data_studio_new.timesheets
	(`timesheet_id`, `entry_date`, `associate`, `practice`, `client_name`, `project_name`, `task_name`, `hours`, `associate_task_rate`, `associate_task_currency`)
	SELECT
	  ts.id AS "timesheet_id",
	  t.date AS "entry_date", 
	  u.name AS "associate",  
	  d.name AS "practice",
	  c.name AS "client_name",
	  p.name AS "project_name", 
	  pt.name AS "task_name",
	  t.hour AS "hours",
	  IF(ur.rate IS NULL, 0, ur.rate) AS "associate_task_rate",
	  IF(ur.currency IS NULL, "", ur.currency) AS "associate_task_currency"
	FROM openair_new.task t
	INNER JOIN openair_new.timesheet ts ON t.timesheet_id = ts.id
	INNER JOIN openair_new.user u ON t.user_id = u.id
	LEFT JOIN openair_new.department d ON u.department_id = d.id
	LEFT JOIN openair_new.project p ON t.project_id = p.id
	LEFT JOIN openair_new.project_task pt ON t.project_task_id = pt.id
	LEFT JOIN openair_new.customer c ON pt.customer_id = c.id
	LEFT JOIN openair_new.up_rate ur ON t.project_id = ur.project_id AND t.user_id = ur.user_id
	WHERE t.date > DATE_SUB(NOW(), INTERVAL 12 MONTH);
	UPDATE google_data_studio_new.timesheets SET dollars=hours*associate_task_rate/8;
	
	# Populate last 12 months of Bookings
	INSERT INTO google_data_studio_new.bookings
	(`associate`, `practice`, `client_name`, `project_name`, `task_name`, `booking_type`, `start_date`, `end_date`, `hours`, `percentage`, `booking_created`, `booking_updated`,`associate_task_rate`,`associate_task_currency`)
	SELECT
	  u.name AS "associate",
	  d.name AS "practice",
	  c.name AS "client_name",
	  p.name AS "project_name", 
	  pt.name AS "task_name",
	  bt.name AS "booking_type",
	  b.startdate AS "start_date",
	  b.enddate AS "end_date",
	  b.hours AS "hours",
	  b.percentage AS "percentage",
	  b.created AS "booking_created",
	  b.updated AS "booking_updated",
	  (SELECT
	    IF(ur.rate IS NULL, 0, ur.rate) AS "associate_task_rate"
	   FROM openair_new.up_rate ur WHERE (b.project_id = ur.project_id AND b.user_id = ur.user_id) LIMIT 1),
	  (SELECT
	    IF(ur.currency IS NULL, "", ur.currency) AS "associate_task_currency"
	   FROM openair_new.up_rate ur WHERE (b.project_id = ur.project_id AND b.user_id = ur.user_id) LIMIT 1)
	FROM openair_new.booking b 
	LEFT JOIN openair_new.booking_type bt ON b.booking_type_id = bt.id
	LEFT JOIN openair_new.customer c ON b.customer_id = c.id
	LEFT JOIN openair_new.project p ON b.project_id = p.id
	LEFT JOIN openair_new.project_task pt ON b.project_task_id = pt.id
	LEFT JOIN openair_new.user u ON b.user_id = u.id
	LEFT JOIN openair_new.department d ON u.department_id = d.id
	WHERE b.enddate > DATE_SUB(NOW(), INTERVAL 12 MONTH);	
	UPDATE google_data_studio_new.bookings SET dollars=hours*associate_task_rate/8;
	
	# Populate all_dates table, excluding weekends
	WHILE dateStart <= dateEnd DO
	  IF (DAYOFWEEK(dateStart) <> 1 AND DAYOFWEEK(dateStart) <> 7) THEN
	    INSERT INTO google_data_studio_new.all_dates (dt) VALUES (dateStart);
	  END IF;
      SET dateStart = date_add(dateStart, INTERVAL 1 DAY);
	END WHILE;
	     
		# Populate daily bookings table
	INSERT INTO google_data_studio_new.bookings_daily
	(`id`, `booking_id`, `associate`, `practice`, `client_name`, `project_name`, `task_name`, `booking_type`, `start_date`, `end_date`, `date`, `week_of_booking`, `week_of_year`, `week_of_year_iso`, `total_booking_hours`, `hours`, `percentage`, `booking_created`, `booking_updated`, `associate_task_rate`, `associate_task_currency`, `dollars`)
	SELECT 
	  NULL, 
	  id, 
	  associate, 
	  practice, 
	  client_name, 
	  project_name, 
	  task_name, 
	  booking_type, 
	  start_date, 
	  end_date, 
	  dt, 
	  FLOOR((DATEDIFF(dt, start_date))/7 + 1), 
	  WEEK(dt), 
	  CONCAT("W", LPAD(WEEK(dt), 2, '0')), 
	  hours, 
	  hours / openair_new.TOTAL_WEEKDAYS(start_date, end_date), 
	  percentage, 
	  booking_created, 
	  booking_updated, 
	  associate_task_rate, 
	  associate_task_currency, 
	  NULL
	FROM google_data_studio_new.bookings b JOIN google_data_studio_new.all_dates ad ON (ad.dt BETWEEN start_date AND end_date);

	# Populate daily bookings table
	INSERT INTO google_data_studio_new.bookings_daily
	(`id`, `booking_id`, `associate`, `practice`, `client_name`, `project_name`, `task_name`, `booking_type`, `start_date`, `end_date`, `date`, `week_of_booking`, `week_of_year`, `week_of_year_iso`, `total_booking_hours`, `hours`, `percentage`, `booking_created`, `booking_updated`, `associate_task_rate`, `associate_task_currency`, `dollars`)
	SELECT 
	  NULL, 
	  id, 
	  associate, 
	  practice, 
	  client_name, 
	  project_name, 
	  task_name, 
	  booking_type, 
	  start_date, 
	  end_date, 
	  dt, 
	  FLOOR((DATEDIFF(dt, start_date))/7 + 1), 
	  WEEK(dt), 
	  CONCAT("W", LPAD(WEEK(dt), 2, '0')), 
	  hours, 
	  hours / openair_new.TOTAL_WEEKDAYS(start_date, end_date), 
	  percentage, 
	  booking_created, 
	  booking_updated, 
	  associate_task_rate, 
	  associate_task_currency, 
	  NULL
	FROM google_data_studio_new.bookings b JOIN google_data_studio_new.all_dates ad ON (ad.dt BETWEEN start_date AND end_date);
	UPDATE google_data_studio_new.bookings_daily SET dollars=hours*associate_task_rate/8;
	
	# Populate table of timesheets and bookings daily
	# A. Insert records for Days with bookings during the whole timesheet table time period, and time entered in any associated timesheets
    # B. Insert  records for Days entered in timesheets that were not captured in a booking
	INSERT INTO google_data_studio_new.timesheets_vs_bookings_daily
	SELECT
	  NULL AS "id",
	  t.id AS "timesheets_id",
	  b.id AS "bookings_daily_id",
	  b.associate,
	  b.practice,
	  b.client_name,
	  b.project_name,
	  b.task_name,
	  b.date,
	  b.week_of_booking,
	  b.week_of_year_iso,
	  b.hours AS "booking_hours",
	  b.dollars AS "booking_dollars",
	  t.hours AS "timesheet_hours",
	  t.dollars AS "timesheet_dollars",
	  b.associate_task_currency
	FROM google_data_studio_new.bookings_daily b
	  LEFT JOIN google_data_studio_new.timesheets t ON
	    (b.date = t.entry_date AND
	     b.associate = t.associate AND
	     b.project_name = t.project_name AND
	     b.task_name = t.task_name)
	WHERE b.date BETWEEN (SELECT min(entry_date) FROM google_data_studio_new.timesheets) AND (SELECT max(entry_date) FROM google_data_studio_new.timesheets);
	
	INSERT INTO google_data_studio_new.timesheets_vs_bookings_daily
	SELECT
	  NULL AS "id",
	  t.id AS "timesheets_id",
	  b.id AS "bookings_daily_id",
	  t.associate,
	  t.practice,
	  t.client_name,
	  t.project_name,
	  t.task_name,
	  t.entry_date,
	  b.week_of_booking,
	  CONCAT("W", LPAD(WEEK(t.entry_date), 2, '0')) AS "week_of_year_iso",
	  b.hours AS "booking_hours",
	  b.dollars AS "booking_dollars",
	  t.hours AS "timesheet_hours",
	  t.dollars AS "timesheet_dollars",
	  t.associate_task_currency
	FROM google_data_studio_new.timesheets t
	  LEFT JOIN google_data_studio_new.bookings_daily b ON
	    (b.date = t.entry_date AND
	     b.associate = t.associate AND
	     b.project_name = t.project_name AND
	     b.task_name = t.task_name)
	WHERE b.id IS NULL;
	
	# Populate Expenses
	INSERT INTO google_data_studio_new.expenses (`associate`, `practice`, `client_name`, `project_name`, `total`, `currency`, `date`, `year`, `week_of_year`, `week_of_year_iso`)
	SELECT
	  u.name AS "associate",  
	  d.name AS "practice",
	  c.name AS "client_name",
	  p.name AS "project_name",
	  e.total AS "total",
	  e.currency AS "currency",
	  e.date AS "date",
	  YEAR(e.date) AS "year",
	  WEEK(e.date) AS "week_of_year", 
	  CONCAT("W", LPAD(WEEK(e.date), 2, '0')) AS "week_of_year_iso"
	FROM openair_new.envelope e
		INNER JOIN openair_new.user u ON e.user_id = u.id
		LEFT JOIN openair_new.department d ON u.department_id = d.id
		LEFT JOIN openair_new.project p ON e.project_id = p.id
		LEFT JOIN openair_new.customer c ON e.customer_id = c.id;
END;
#$#$#$

CALL openair_new.populate_google_data_studio_new_tables();