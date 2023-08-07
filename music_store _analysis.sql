/*	Question Set 1 - Easy */

/* Q1: Who is the senior most employee based on job title? */


SELECT last_name, first_name, levels 
FROM employee
ORDER BY levels DESC
LIMIT 1


/* Q2: Which countries have the most Invoices? */


SELECT billing_country, COUNT(invoice_id) AS nu
FROM invoice
GROUP BY billing_country
ORDER BY nu DESC;


/* Q3: What are top 3 values of total invoice? */


SELECT total
FROM invoice
ORDER BY total DESC
LIMIT 3;


/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */


SELECT billing_city, ROUND(SUM(total)::numeric, 2) AS sum_total
FROM invoice
GROUP BY billing_city
ORDER BY sum_total DESC;


/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/


SELECT
    cu.customer_id,
    cu.first_name,
    cu.last_name,
    ROUND(CAST(SUM(inv.total) AS numeric), 2) AS total
FROM
    customer AS cu
JOIN
    invoice AS inv ON cu.customer_id = inv.customer_id
GROUP BY
    cu.customer_id, cu.first_name, cu.last_name
ORDER BY
    total DESC
LIMIT 1;


/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */


/* Method 1 */


WITH cte1 AS (
    SELECT *
    FROM customer AS cu
    JOIN invoice AS inv
    ON cu.customer_id = inv.customer_id
), 
cte2 AS (
    SELECT *
    FROM cte1
    JOIN invoice_line
    ON cte1.invoice_id = invoice_line.invoice_id
), 
cte3 AS (
    SELECT cte2.first_name, cte2.last_name, cte2.email, track.genre_id
    FROM cte2
    JOIN track
    ON cte2.track_id = track.track_id
), 
cte4 AS (
    SELECT *
    FROM cte3
    JOIN genre
    ON cte3.genre_id = genre.genre_id
)
SELECT DISTINCT cte4.email, cte4.first_name, cte4.last_name, cte4.name
FROM cte4
WHERE cte4.name = 'Rock'
ORDER BY cte4.email;


/* Method 2 */


SELECT DISTINCT email, first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
JOIN track ON invoice_line.track_id = track.track_id
JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name LIKE 'Rock'
ORDER BY email;


/* Method 3 */


SELECT DISTINCT
    customer.email AS Email,
    customer.first_name AS FirstName,
    customer.last_name AS LastName,
    genre.name AS Name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
JOIN track ON invoice_line.track_id = track.track_id
JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name LIKE 'Rock'
ORDER BY customer.email;



/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */


/* Method 1 */


SELECT artist.name, COUNT(track.track_id) AS count_tr
FROM artist
JOIN album ON artist.artist_id = album.artist_id
JOIN track ON track.album_id = album.album_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name = 'Rock'
GROUP BY artist.name
ORDER BY count_tr DESC
LIMIT 10;


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */


SELECT name, milliseconds
FROM track
WHERE milliseconds > (
    SELECT AVG(milliseconds)
    FROM track
)
ORDER BY milliseconds DESC;


/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

WITH cte AS (
    SELECT 
        customer.first_name,
        customer.last_name,
        artist.name,
        invoice_line.unit_price * invoice_line.quantity AS total
    FROM customer
    JOIN invoice ON customer.customer_id = invoice.customer_id
    JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN album ON album.album_id = track.album_id
    JOIN artist ON artist.artist_id = album.artist_id
)
SELECT 
    cte.first_name,
    cte.last_name,
    cte.name,
    SUM(total) AS total_money
FROM cte
GROUP BY cte.first_name, cte.last_name, cte.name
ORDER BY total_money DESC;


/* Q2: find the best selling artist and it's customer name and total spent on that artist ? */

WITH best_selling_art AS (
    SELECT
        artist.artist_id,
        artist.name,
        SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sale
    FROM invoice_line
    JOIN track ON invoice_line.track_id = track.track_id
    JOIN album ON album.album_id = track.album_id
    JOIN artist ON artist.artist_id = album.artist_id
    GROUP BY artist.artist_id, artist.name
    ORDER BY total_sale DESC
    LIMIT 1
)
SELECT
    customer.first_name,
    customer.last_name,
    best_selling_art.name AS best_selling_artist_name,
    best_selling_art.artist_id AS best_selling_artist_id,
    SUM(invoice_line.unit_price * invoice_line.quantity) AS total
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN album ON album.album_id = track.album_id
JOIN best_selling_art ON best_selling_art.artist_id = album.artist_id
GROUP BY customer.first_name, customer.last_name, best_selling_art.name, best_selling_art.artist_id
ORDER BY total DESC;


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */


WITH most_pop_mus AS (
    SELECT 
        COUNT(invoice_line.invoice_id) AS purchase,
        customer.country,
        genre.name,
        ROW_NUMBER() OVER (PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS row_nu
    FROM customer
    JOIN invoice ON customer.customer_id = invoice.customer_id
    JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN genre ON genre.genre_id = track.genre_id
    GROUP BY customer.country, genre.name
)
SELECT *
FROM most_pop_mus
WHERE row_nu = 1;

/* Method 2: : Using Recursive */

WITH RECURSIVE
 sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2)
SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */


WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1

/* Method 2: Using Recursive */

WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;
