# *Isograms*: Tools and data for studying isograms.

This is a collection of python scripts and data files which were used to extract isograms (and some palindromes and tautonyms) from corpus-based word-lists (specifically Google Ngram and the British National Corpus [BNC]).


## Scripts for isogram mining
There are currently two scripts in this repository, one for tyding Ngrams and BNC word lists and extracting isograms, and one to create a neat SQLite database from the output of the first script. Below some basic instructions on using these scripts.

All scripts are located in the ``./scripts`` folder.

### Prerequisits

To run the main script you need:
* A copy of the script from ``./scripts/isograms.py`` ;-)
* [Python 3](http://python.org) (it won't work with Python 2)

To create the database (optional), you need:
* [SQLite 3](http://sqlite.com/) (might also work with other versions)

Everything described here should work equally well on reasonably recent versions of Windows, Linux, Unix and macOS, but please do let me know if you run into any problems.

### Source data

The scripts were written to work with word lists from Google Ngram and the BNC.

You can obtain the English language version of Google Ngram from here:

You can obtain a word list for the BNC from here:

For Ngrams data I would recommend deleting all the numeric and punctuation files (i.e. only keep the files ending in "-a" through "-z"). Place all of the Ngrams files together in one folder: the script expects the path to a folder as the input for Ngrams, but the direct path to a single file for the BNC.

### Preparing the data

The first step in processing the word lists is to tidy them (exclude superflous material and some of the most obvious noise) and to bring them into a uniform format. To do this, run one of the following commands from the command line/shell, depending on whether you're working with Ngrams or the BNC.

For Ngrams:
```bash
python isograms.py  --ngrams --indir=INDIR --outfile=OUTFILE
```

For the BNC:
```bash
python isograms.py  --bnc --indir=INFILE --outfile=OUTFILE
```

Obviously replace INDIR/INFILE with the input directory or filename and OUTFILE with the filename for the tidied and reformatted output.

### Mining isograms

After preparing the data as detailed above, you can run the following command to extract all the isograms from the data:

```bash
python isograms.py  --batch --infile=INFILE --outfile=OUTFILE
```

Here INFILE should refer the the output from the previosu data cleaning process. Please note that the script will actually write *two* output files, one named OUTFILE with a word list of all the isograms and their associated frequency data, and one named "OUTFILE.totals" with very basic summary statistics.

### Loading the isograms into a database

Depending on what you want to do with the list of isograms, it might be most convenient for you to access them through and SQL database where you can query the data directly for specific properties. In order to get them all into an SQLite database, follow these simple steps:

1. Make sure the files with the Ngrams and BNC data are named "ngrams-isograms.csv" and "bnc-isograms.csv" respectively. (The script assumes you have both of them, if you only want to load one, just create an empty file for the other one).
2. Copy the "create-database.sql" script into the same directory as the two data files.
3. Open the command line/shell, go to the directory where the files and the SQL-script are and type:
   ```bash
   sqlite3 isograms.db <create-database.sql
   ```
4. This will create a database called "isograms.db" which you can now access with your favourite SQLite software (or API).

See the section below for a basic descript of the output data and how to work with it.  


## Isogram data from Ngrams and the BNC

The data from English Google Ngrams and the BNC is available in two formats: as a plain text CSV file and as a SQLite3 database.

### CSV format

The CSV files for each dataset actually come in two parts: one labelled ".csv" and one ".totals". The ".csv" contains the actual extracted data, and the ".totals" file contains some basic summary statistics about the ".csv" dataset with the same name.

The CSV files contain one row per data point, with the colums separated by a single tab stop. There are *no* labels at the top of the files. Each line has the following columns, in this order (the labels below are what I use in the database, which has an identical structure, see section below):

Label      | Data type | Description
---------- | ----------| -----------
isogramy   | int       | The order of isogramy, e.g. "2" is a second order isogram
length     | int       | The length of the word in letters
word       | text      | The actual word/isogram in ASCII
source_pos | text      | The Part of Speech tag from the original corpus
count      | int       | Token count (total number of occurences)
vol_count  | int       | Volume count (number of different sources which contain the word)
count_per_million    | int | Token count per million words
vol_count_as_percent | int | Volume count as percentage of the total number of volumes
is_palindrome | bool   | Whether the word is a palindrome (1) or not (0)
is_tautonym | bool     | Whether the word is a tautonym (1) or not (0)

The ".totals" files have a slightly different format, with one row per data point, where the first column is the label and the second column is the associated value. The ".totals" files contain the following data:

Label              | Data type | Description
------------------ | ----------| -----------
!total_1grams      | int       | The total number of words in the corpus
!total_volumes     | int       | The total number of volumes (individual sources) in the corpus
!total_isograms    | int       | The total number of isograms found in the corpus (before compacting)
!total_palindromes | int       | How many of the isograms found are palindromes
!total_tautonyms   | int       | How many of the isograms found are tautonyms

The CSV files are mainly useful for further automated data processing. For working with the data set directly (e.g. to do statistics or cross-check entries), I would recommend using the database format described below.


### SQLite database format

On the other hand, the SQLite database combines the data from all four of the plain text files, and adds various useful combinations of the two datasets, namely:
* Compacted versions of each dataset, where identical headwords are combined into a single entry.
* A combined compacted dataset, combining and compacting the data from both Ngrams and the BNC.
* An intersected dataset, which contains only those words which are found in *both* the Ngrams and the BNC dataset.

The intersected dataset is by far the least noisy, but is missing some real isograms, too.

Each of these tables in the database contains the following columns:

Label      | Data type | Description
---------- | ----------| -----------
isogramy   | int       | The order of isogramy, e.g. "2" is a second order isogram
length     | int       | The length of the word in letters
word       | text      | The actual word/isogram in ASCII
source_pos | text      | The Part of Speech tag from the original corpus
count      | int       | Token count (total number of occurences)
vol_count  | int       | Volume count (number of different sources which contain the word)
count_per_million    | int | Token count per million words
vol_count_as_percent | int | Volume count as percentage of the total number of volumes
is_palindrome | bool   | Whether the word is a palindrome (1) or not (0)
is_tautonym | bool     | Whether the word is a tautonym (1) or not (0)

The database also contains two "_totals" tables for the Ngrams and the BNC, with the following columns:

Label          | Data type | Description
-------------- | ----------| -----------
total_1grams   | int       | The total number of words in the corpus
total_volumes  | int       | The total number of volumes (individual sources) in the corpus
total_isograms | int       | The total number of isograms found in the corpus (before compacting)
total_palindromes | int    | How many of the isograms found are palindromes
total_tautonyms | int      | How many of the isograms found are tautonyms

To get an idea of the various ways you could query the databse for various bits of data you could have a look at the R script below used to compute statistics based on the SQLite database.

### Statistical processing

The repository includes an R script (R version 3) that computes a number of statistics about the distribution of isograms by length, frequency, contextual diversity, etc. You can use this as a starting point for running your own stats. It uses RSQLite to access the SQLite database version of the data described above. The R script can be found in the "./scripts" folder.


## Getting more details

To get more details about the methodology/procedures used in the script and the various caveats to go with the dataset please have a look at the Methodology section of my isograms paper, see citation below<!-- (a copy of this is also included in the Git repository)-->.

To see further options for running the script, use the "--help" parameter, i.e.
```bash
python isograms.py --help
```
This will print a detailed list of all the options and functions the script offers.

If you have problems with the SQL or R scripts, try running them chunk by chunk; especially with SQLite I've noticed that sometimes works better.

If after that any issues, questions or suggestions remain please do get in touch. Either use the [GitHub issue tracker](https://github.com/fffree/isograms/issues) or email me ([florian.breit.12@ucl.ac.uk](florian.breit.12@ucl.ac.uk)).


## Citation
If you use the scripts or data contained here in academic work, please cite the associated paper:
* Breit, Florian (2016) The Distribution of English Isograms in Google Ngrams and the British National Corpus. *Opticon1826*, 18: 2, pp. 1-28. <!-- DOI: http://dx.doi.org/10.14324/111.2049-8128.001 -->

If you use it in some other way then appropriate acknowledgement would be appreciated.

## Licensing
* All the scripts are available under the *GNU Affero General Public License* (version 3 or higher).
* For the datasets themselves you have a choice between the Creative Commons *CC-BY* (version 4 or higher) or the Open Data Commons *ODC-By* license in addition to the above GNU license.
<!--* The paper is licensed under the Creative Commons *CC-BY* license (version 4 or higher).-->
If none of these options suit your requirements just get in touch.