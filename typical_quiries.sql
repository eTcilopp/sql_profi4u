-- TYPICAL QUIRIES
   
-- list of all contractors with their gender
SELECT id,first_name, last_name, gender
FROM users, user_profiles
WHERE users.id = user_profiles.user_id AND is_contractor = TRUE;

-- list of all contractors with their skills and categories of skills
SELECT first_name, last_name, skill, category
FROM users, skills, categories, contractor_skills
WHERE contractor_skills.contractor_id = users.id AND contractor_skills.skill_id = skills.id AND skills.category_id = categories.id
ORDER BY first_name;

-- list of all contractors from a particular town (Murmansk in this case) and with a particular skills (Photo)
SELECT users.id, first_name, last_name, hometown, users.is_contractor, skills.id
FROM skills
JOIN contractor_skills ON contractor_skills.skill_id = skills.id
JOIN users ON contractor_skills.contractor_id = users.id
JOIN user_profiles ON users.id = user_profiles.user_id
JOIN hometowns ON user_profiles.hometown_id = hometowns.id
WHERE hometown_id = 2 AND skills.id = 60;


-- list of all contractors with rating >=3. Includes completed project description and client's comment
SELECT users.first_name, users.last_name, projects.description, ratings.rating_value, reviews.comment, hometown,  status
FROM users
JOIN projects ON users.id = projects.contractor_id
JOIN reviews ON projects.id = reviews.project_id
JOIN ratings ON reviews.rating_id = ratings.id
JOIN statuses ON projects.status_id = statuses.id
JOIN hometowns ON projects.location_id = hometowns.id
WHERE rating_id >= 3;


-- Messages history 
-- Get message history for particulatr project (project id 7 in this example)
call messages_history(55);

-- available projects for contractor (contractor with id 101 in this example)
call available_projects(101);
