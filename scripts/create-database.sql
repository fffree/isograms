/***
 * CREATE DATABASES AND VIEWS FOR ISOGRAM LISTS
 *
 * Instructions:
 * - Go to the console/command prompt
 * - Go to the directory with the word lists generated
 *   by the isogram.py script
 * - The two word lists must be named
 *      bnc-isograms.csv
 *   and
 *      ngrams-isograms.csv
 *   respectively.
 * - Copy this script into the same directory,
 *   it should be named "create-database.sql"
 * - Now run this command on the console:
 *      sqlite3 isograms.db < create-database.sql
 *   and wait, it might take a while.
 * - Voila! "isograms.db" is the SQLite3 database
 *   containing all the isograms.
 * - If this doesn't work properly for some reason,
 *   I suggest to try running sqlite3 from the console
 *   and then copy and pasting the commands below in
 *   four parts, as follows:
 *     (1) The two CREATE TABLE statements (all four at once).
 *     (2) The five SQLite commands beginnging with a dot,
 *         one after another.
 *     (3) The SQL commands and statements to deal with the
 *         totals. If this doesn't work by copy and pasting as one single
 *         block, try copying the statments beginning with a dot on their own
 *         and the intervening INSERT and UPDATE statements as blocks.
 *     (3) The remaining SQL commands (all at once).
 */

/***
 * Tables for importing the BNC and Ngram word lists
 */
 
CREATE TABLE bnc (
    "isogramy" INTEGER,
    "length" INTEGER,
    "word" TEXT,
    "source_pos" TEXT,
    "count" INTEGER,
    "vol_count" INTEGER,
	"count_per_million" FLOAT,
	"vol_count_as_percent" FLOAT,
    "is_palindrome" INTEGER,
    "is_tautonym" INTEGER
);

CREATE TABLE bnc_totals (
	"total_1grams" INTEGER,
	"total_volumes" INTEGER,
	"total_isograms" INTEGER,
	"total_palindromes" INTEGER,
	"total_tautonyms" INTEGER
);

CREATE TABLE ngrams (
    "isogramy" INTEGER,
    "length" INTEGER,
    "word" TEXT,
    "source_pos" TEXT,
    "count" INTEGER,
    "vol_count" INTEGER,
	"count_per_million" FLOAT,
	"vol_count_as_percent" FLOAT,
    "is_palindrome" INTEGER,
    "is_tautonym" INTEGER
);

CREATE TABLE ngrams_totals (
	"total_1grams" INTEGER,
	"total_volumes" INTEGER,
	"total_isograms" INTEGER,
	"total_palindromes" INTEGER,
	"total_tautonyms" INTEGER
);

/***
 * Import CSV files for BNC and Ngrams
 */

.mode csv
.separator "\t"
.import bnc-isograms.csv bnc
.import ngrams-isograms.csv ngrams

/***
 * Import .totals files; SQLite doesn't have a pivot statement so this is a
 * little bit verbose...
 */
 
CREATE TABLE temp_key_value_store (  /* Used to import the .totals files, */
	"key" VARCHAR,                   /* gets deleted after importing is done. */
	"value" INTEGER
);

.import bnc-isograms.csv.totals temp_key_value_store

INSERT INTO
	bnc_totals (total_1grams)
	SELECT
		"value" 
	FROM
		temp_key_value_store
	WHERE
		"key" is "!total_1grams"
;
		
UPDATE
	bnc_totals
SET
	total_volumes = (
		SELECT
			"value"
		FROM
			temp_key_value_store
		WHERE
			"key" is "!total_volumes"
	)
;
	
UPDATE
	bnc_totals
SET
	total_isograms = (
		SELECT
			"value"
		FROM
			temp_key_value_store
		WHERE
			"key" is "!total_isograms"
	)
;
	
UPDATE
	bnc_totals
SET
	total_palindromes = (
		SELECT
			"value"
		FROM
			temp_key_value_store
		WHERE
			"key" is "!total_palindromes"
	)
;
	
UPDATE
	bnc_totals
SET
	total_tautonyms = (
		SELECT
			"value"
		FROM
			temp_key_value_store
		WHERE
			"key" is "!total_tautonyms"
	)
;
	
DELETE FROM temp_key_value_store;

.import ngrams-isograms.csv.totals temp_key_value_store

INSERT INTO
	ngrams_totals (total_1grams)
	SELECT
		"value" 
	FROM
		temp_key_value_store
	WHERE
		"key" is "!total_1grams"
;
		
UPDATE
	ngrams_totals
SET
	total_volumes = (
		SELECT
			"value"
		FROM
			temp_key_value_store
		WHERE
			"key" is "!total_volumes"
	)
;
	
UPDATE
	ngrams_totals
SET
	total_isograms = (
		SELECT
			"value"
		FROM
			temp_key_value_store
		WHERE
			"key" is "!total_isograms"
	)
;
	
UPDATE
	ngrams_totals
SET
	total_palindromes = (
		SELECT
			"value"
		FROM
			temp_key_value_store
		WHERE
			"key" is "!total_palindromes"
	)
;
	
UPDATE
	ngrams_totals
SET
	total_tautonyms = (
		SELECT
			"value"
		FROM
			temp_key_value_store
		WHERE
			"key" is "!total_tautonyms"
	)
;
	
DROP TABLE temp_key_value_store;

.mode columns

/***
 * Create Tables with more convenient data subsets
 */

/***
 * Table for combined lists
 */
 
CREATE TABLE
     "combined"
     AS
          SELECT
               *
          FROM
               bnc
          UNION
               SELECT
                    *
               FROM
                    ngrams
;

/***
 * Table for compacted lists
 */
 
CREATE TABLE
    "bnc_compacted"
    AS
        SELECT
            isogramy,
            length,
            word,
            source_pos,
            SUM(count) AS count,
            SUM(vol_count) AS vol_count,
			SUM(count_per_million) AS count_per_million,
			SUM(vol_count_as_percent) AS vol_count_as_percent,
            is_palindrome,
            is_tautonym
        FROM
            bnc
        GROUP BY
            word
;

CREATE TABLE
    "ngrams_compacted"
    AS
        SELECT
            isogramy,
            length,
            word,
            source_pos,
            SUM(count) AS count,
            SUM(vol_count) AS vol_count,
			SUM(count_per_million) AS count_per_million,
			SUM(vol_count_as_percent) AS vol_count_as_percent,
            is_palindrome,
            is_tautonym
        FROM
            ngrams
        GROUP BY
            word
;

CREATE TABLE
	"combined_compacted_temp"
	AS
          SELECT
               *
          FROM
               bnc_compacted
          UNION
               SELECT
                    *
               FROM
                    ngrams_compacted
;
					
CREATE TABLE
    "combined_compacted"
    AS
        SELECT
            isogramy,
            length,
            word,
            source_pos,
            SUM(count) AS count,
            SUM(vol_count) AS vol_count,
			AVG(count_per_million) AS count_per_million,
			AVG(vol_count_as_percent) AS vol_count_as_percent,
            is_palindrome,
            is_tautonym
        FROM
            combined_compacted_temp
        GROUP BY
            word
;

DROP TABLE combined_compacted_temp;

/***
 * Table for intersected (compacted) list
 */

CREATE TABLE
    "intersected"
    AS
        SELECT
            bnc_compacted.isogramy AS isogramy,
            bnc_compacted.length AS length,
            bnc_compacted.word AS word,
            ngrams_compacted.source_pos AS source_pos,
            bnc_compacted.count + ngrams_compacted.count AS count,
            bnc_compacted.vol_count + ngrams_compacted.vol_count AS vol_count,
			(bnc_compacted.count_per_million + ngrams_compacted.count_per_million) / 2.0 AS count_per_million,
			(bnc_compacted.vol_count_as_percent + ngrams_compacted.vol_count_as_percent) / 2.0 AS vol_count_as_percent,
            bnc_compacted.is_palindrome AS is_palindrome,
            bnc_compacted.is_tautonym AS is_tautonym
        FROM
            bnc_compacted,
            ngrams_compacted
        WHERE
            bnc_compacted.word = ngrams_compacted.word
;

/***
 * Rebuild database to save space (defragments and deletes empty pages from temporary tables etc.)
 */
VACUUM;

/***
 * END OF SCRIPT
 */
 .exit
 
 