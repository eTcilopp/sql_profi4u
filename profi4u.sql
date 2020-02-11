
DROP DATABASE IF EXISTS profi4u;
CREATE DATABASE profi4u;
USE profi4u;

DROP TABLE IF EXISTS hometowns;
CREATE TABLE hometowns (
	id SERIAL PRIMARY KEY,
	hometown VARCHAR (250) UNIQUE
);

DROP TABLE IF EXISTS statuses;
CREATE TABLE statuses(
	id BIGINT UNSIGNED NOT NULL UNIQUE PRIMARY KEY,
	status VARCHAR(50)
	);

DROP TABLE IF EXISTS categories;
CREATE TABLE categories(
	id SERIAL PRIMARY KEY,
	category VARCHAR(50)
	);
DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings(
	id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
	rating_value VARCHAR(10)
);

DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id SERIAL  PRIMARY KEY,
	first_name VARCHAR(100),
	last_name VARCHAR(100),
	email VARCHAR(100) UNIQUE,
	is_contractor BOOL DEFAULT FALSE
);

DROP TABLE IF EXISTS user_profiles;
CREATE TABLE user_profiles(
	user_id SERIAL PRIMARY KEY,
	active BOOLEAN,
	gender ENUM ('male','female','undefined'),
	birthday DATE,
	photo_id BIGINT UNSIGNED,
	created_at DATETIME DEFAULT NOW(),
	hometown_id BIGINT UNSIGNED NOT NULL,
	resume TEXT,
	
	FOREIGN KEY (user_id) REFERENCES users(id)
	ON UPDATE CASCADE,
	-- FOREIGN KEY (photo_id) REFERENCES media(id),
	FOREIGN KEY (hometown_id) REFERENCES hometowns(id)
);

DROP TABLE IF EXISTS projects;
CREATE TABLE projects (
	id SERIAL PRIMARY KEY,
	status_id BIGINT UNSIGNED NOT NULL,
	created_at DATETIME DEFAULT NOW(),
	modified_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
	required_at DATETIME DEFAULT NOW(),
	valid_until DATETIME,
	creator_id BIGINT UNSIGNED NOT NULL,
	location_id BIGINT UNSIGNED NOT NULL,
	contractor_id BIGINT UNSIGNED,
	category_id BIGINT UNSIGNED NOT NULL,
	description VARCHAR(255),
	
	FOREIGN KEY (creator_id)REFERENCES users(id),
	FOREIGN KEY (contractor_id)REFERENCES users(id),
	FOREIGN KEY (status_id) REFERENCES statuses(id),
	FOREIGN KEY (category_id)REFERENCES categories(id),
	FOREIGN KEY (location_id)REFERENCES hometowns(id)
);

DROP TABLE IF EXISTS skills;
CREATE TABLE skills(
	id SERIAL PRIMARY KEY,
	skill VARCHAR(250),
	category_id BIGINT UNSIGNED NOT NULL,
	
	FOREIGN KEY (category_id) REFERENCES categories(id)
);

DROP TABLE IF EXISTS contractor_skills;
CREATE TABLE contractor_skills(
	contractor_id BIGINT UNSIGNED NOT NULL,
	skill_id BIGINT UNSIGNED NOT NULL,
	
	PRIMARY KEY (contractor_id, skill_id),
	FOREIGN KEY (contractor_id) REFERENCES users(id),
	FOREIGN KEY (skill_id) REFERENCES skills(id)
	);

DROP TABLE IF EXISTS reviews;
CREATE TABLE reviews (
	id SERIAL PRIMARY KEY,
	project_id BIGINT UNSIGNED NOT NULL,
	rating_id BIGINT UNSIGNED NOT NULL,
	comment TEXT,
	created_at DATETIME DEFAULT NOW(),
	updated_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
	
	FOREIGN KEY (project_id)REFERENCES projects(id),
	FOREIGN KEY (rating_id) REFERENCES ratings(id)
);

DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
	id SERIAL PRIMARY KEY,
	from_user_id BIGINT UNSIGNED NOT NULL,
    to_user_id BIGINT UNSIGNED NOT NULL,
    body TEXT,
    created_at DATETIME DEFAULT NOW(),

    FOREIGN KEY (from_user_id) REFERENCES users(id),
    FOREIGN KEY (to_user_id) REFERENCES users(id)
);


-- view: all available projects now

CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW `view_available_projects` AS
select
    `projects`.`id` AS `project_id`,
    `projects`.`status_id` AS `status_id`,
    `projects`.`description` AS `description`,
    `projects`.`location_id` AS `location_id`,
    `projects`.`category_id` AS `category_id`
from
    `projects`
where
    ((`projects`.`status_id` <> 3)
    and (`projects`.`status_id` <> 4));

   
-- view: contractors with ratings and projects
CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW `view_contractors_with_skills_and_ratings` AS
select
    `users`.`id` AS `contractor_id`,
    `categories`.`id` AS `skill`,
    `hometowns`.`id` AS `id`,
    `reviews`.`project_id` AS `project_id`,
    `reviews`.`rating_id` AS `rating_id`
from
    (((((((`users`
join `user_profiles` on
    ((`user_profiles`.`user_id` = `users`.`id`)))
join `hometowns` on
    ((`hometowns`.`id` = `user_profiles`.`hometown_id`)))
join `contractor_skills` on
    ((`users`.`id` = `contractor_skills`.`contractor_id`)))
join `skills` on
    ((`skills`.`id` = `contractor_skills`.`skill_id`)))
join `categories` on
    ((`categories`.`id` = `skills`.`category_id`)))
left join `projects` on
    ((`projects`.`contractor_id` = `users`.`id`)))
left join `reviews` on
    ((`reviews`.`project_id` = `projects`.`id`)));
   

-- Procedures
-- MARK EXPIRED PROJECTS
DROP PROCEDURE IF EXISTS update_expired_orders;

DELIMITER //
CREATE PROCEDURE update_expired_orders()
BEGIN
	UPDATE projects SET status_id=4 WHERE valid_until < NOW();
END //

DELIMITER ;

-- MESSAGE HISTORY BY PROJECT ID
DROP PROCEDURE IF EXISTS messages_history ;

DELIMITER //
CREATE PROCEDURE messages_history(IN project_id INT)
BEGIN
	SELECT DISTINCT projects.id, messages.created_at, from_user_id, to_user_id, sender.first_name, recipient.first_name, body
	FROM messages
	JOIN users AS sender ON sender.id = messages.from_user_id
	JOIN users AS recipient ON recipient.id = messages.to_user_id
	JOIN projects ON projects.creator_id = sender.id OR projects.creator_id = recipient.id
	WHERE projects.id = project_id
	ORDER BY messages.created_at;
END //

DELIMITER ;

-- get available projects for a contractor based on his or her skills and location

DROP PROCEDURE IF EXISTS available_projects ;

DELIMITER //
CREATE PROCEDURE available_projects(IN requester_id INT)
BEGIN
	SELECT *
	FROM view_available_projects
	WHERE
		location_id = (SELECT hometown_id FROM user_profiles up WHERE user_id = requester_id) AND
		category_id = (SELECT category_id FROM skills WHERE skills.id =
					(SELECT skill_id FROM contractor_skills WHERE contractor_id = requester_id));
END //

DELIMITER ;
