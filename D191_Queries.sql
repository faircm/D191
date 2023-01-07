CREATE TABLE IF NOT EXISTS detailed_report(
times_rented INT,
inventory_id INT,
film_id INT,
film_title VARCHAR(255),
category_id INT,
category_name VARCHAR(25)
);

CREATE TABLE IF NOT EXISTS summary_report(
rental_count INT,
film_title VARCHAR(255),
category_name VARCHAR(25)
);

CREATE FUNCTION UPDATE_NULL_ID(target_id INT) RETURNS INT AS $UPDATE_NULL_ID$
BEGIN
IF @target_id IS NULL THEN
target_id = 0;
END IF;
RETURN @target_id;
END
$UPDATE_NULL_ID$ LANGUAGE plpgsql;

CREATE FUNCTION POPULATE_SUMMARY_REPORT() RETURNS TRIGGER AS $POPULATE_SUMMARY_REPORT$
BEGIN
DELETE FROM summary_report;
INSERT INTO summary_report(rental_count, film_title, category_name)
SELECT SUM(times_rented) AS rental_count, film_title, category_name
FROM detailed_report
GROUP BY film_title, category_name
ORDER BY rental_count DESC;
RETURN NEW;
END;
$POPULATE_SUMMARY_REPORT$ LANGUAGE plpgsql;

CREATE TRIGGER UPDATE_SUMMARY
AFTER UPDATE ON detailed_report
FOR EACH STATEMENT
EXECUTE FUNCTION POPULATE_SUMMARY_REPORT();


CREATE PROCEDURE REFRESH_TABLES() AS $REFRESH_TABLES$
BEGIN
DELETE FROM detailed_report;
INSERT INTO detailed_report (times_rented, inventory_id, film_id, film_title, category_id, category_name)
SELECT COUNT(rental.rental_id) AS times_rented, inventory.inventory_id,film.film_id, film.title, film_category.category_id, category.name
FROM rental
FULL JOIN inventory ON rental.inventory_id = inventory.inventory_id
RIGHT JOIN film ON film.film_id = inventory.film_id
LEFT JOIN film_category ON film.film_id = film_category.film_id
LEFT JOIN category ON film_category.category_id = category.category_id
GROUP BY film.film_id, category.name, inventory.inventory_id, film_category.category_id
ORDER BY times_rented DESC;
DELETE FROM summary_report;
INSERT INTO summary_report(rental_count, film_title, category_name)
SELECT SUM(times_rented) AS rental_count, film_title, category_name
FROM detailed_report
GROUP BY film_title, category_name
ORDER BY rental_count DESC;
END;
$REFRESH_TABLES$ LANGUAGE plpgsql;

INSERT INTO detailed_report (times_rented, inventory_id, film_id, film_title, category_id, category_name)
SELECT COUNT(rental.rental_id) AS times_rented, inventory.inventory_id,film.film_id, film.title, film_category.category_id, category.name
FROM rental
FULL JOIN inventory ON rental.inventory_id = inventory.inventory_id
RIGHT JOIN film ON film.film_id = inventory.film_id
LEFT JOIN film_category ON film.film_id = film_category.film_id
LEFT JOIN category ON film_category.category_id = category.category_id
GROUP BY film.film_id, category.name, inventory.inventory_id, film_category.category_id
ORDER BY times_rented DESC;

INSERT INTO summary_report(rental_count, film_title, category_name)
SELECT SUM(times_rented) AS rental_count, film_title, category_name
FROM detailed_report
GROUP BY film_title, category_name
ORDER BY rental_count DESC;

SELECT * FROM detailed_report
SELECT * FROM summary_report