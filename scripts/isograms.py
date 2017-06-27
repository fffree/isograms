#!/usr/bin/env python
# -*- coding: utf-8 -*-
#-------------------------------------------------------------------------------
# Name:        isograms
# Purpose:     To extract isograms from Google 1-grams and BNC frequency lists
#
# Author:      Florian Breit <florian.breit.12@ucl.ac.uk>
#
# Created:     11/06/2014
# Last Update: 02/09/2015
# Copyright:   (c) Florian Breit 2014, 2015
# Licence:     Affero General Public License Version 3, or
#-------------------------------------------------------------------------------

import unicodedata
import os
import gzip
import sys
import codecs
import time
from optparse import OptionParser
import time
import fnmatch

def main():
    #Parse command line arguments
    usage = "Usage: %prog [-i] STRING\n"
    usage+= "       %prog --test\n"
    usage+= "       %prog --ngrams --indir=INDIR   --outfile=OUTFILE\n"
    usage+= "       %prog --bnc    --infile=INFILE --outfile=OUTFILE\n"
    usage+= "       %prog --batch  --infile=INFILE --outfile=OUTFILE\n"
    parser = OptionParser(usage=usage, version="%prog 1.0")
    parser.add_option("", "--test", action="store_true", dest="test",
                      help="Run some tests to make sure the program works.",
                      default=False)
    parser.add_option("", "--ngrams", action="store_true", dest="ngrams",
                      help="Prepare a wordlist from a Google 1gram directory."
                      + " Requires --indir and --outfile.", default=False)
    parser.add_option("", "--bnc", action="store_true", dest="bnc",
                      help="Prepare a wordlist from the BNC frequency list."
                      + " Requires --infile and --outfile.", default=False)
    parser.add_option("-b", "--batch", action="store_true", dest="batch",
                      help="Batch process a given word list."
                      + " Requires --indir and --outfile.", default=False)
    parser.add_option("-i", "--isogramy", dest="isogramy", metavar="STRING",
                      help="Return the isogramy of STRING. Returns 0 if STRING"
                      + " is not an isogram.")
    parser.add_option("-f", "--infile", dest="infile", metavar="FILE",
                      help="Specify FILE as the input file for --batch.")
    parser.add_option("-o", "--outfile", dest="outfile", metavar="FILE",
                      help="Specify FILE as the output file for --ngrams or"
                      + " --batch.")
    parser.add_option("-d", "--indir", dest="indir", metavar="DIRECTORY",
                      help="Specify DIRECTORY as the input directory for"
                      + " --ngrams.")
    (opts, args) = parser.parse_args()

    #Make sure only one of --test, --ngrams, --batch, --isogramy is given.
    count_opts = 0;
    if(opts.test): count_opts +=1
    if(opts.ngrams): count_opts +=1
    if(opts.batch): count_opts +=1
    if(opts.isogramy): count_opts +=1
    if(count_opts > 1):
        print("The options --test, --ngrams, --batch and --isogramy are mutually"
        + " exclusive.\nTry --help for more information.")

    #Process options
    if(opts.test):
        test()
        exit()
    if(opts.ngrams):
        if(opts.indir is None or opts.outfile is None):
            print("The option --ngrams requires both --indir and --outfile to be"
            + " specified.\nTry --help for more information.")
            exit()
        print("Preparing 1grams from %s..." % opts.indir)
        print("")
        prepareNgrams(opts.indir, opts.outfile)
        print("")
        print("Preparation of all 1grams is complete.")
        exit()
    if(opts.bnc):
        if(opts.infile is None or opts.outfile is None):
            print("The option --bnc requires both --infile and --outfile to be"
            + " specified.\nTry --help for more information.")
            exit()
        print("Preparing BNC wordlist from %s..." % opts.indir)
        print("")
        prepareBNC(opts.infile, opts.outfile)
        print("")
        print("Preparation of BNC word list is complete.")
        exit()
    if(opts.batch):
        if(opts.infile is None or opts.outfile is None):
            print("The option --batch requires both --infile and --outfile to"
            + "be specified.\nTry --help for more information.")
            exit()
        print("Processsing %s..." % opts.infile)
        print("")
        detectIsograms(opts.infile, opts.outfile)
        print("")
        print("Processing of isograms complete.")
        exit()
    if(opts.isogramy):
        print(isogram(isogramy))
        exit()
    if(count_opts is 0 and len(args) > 0):
        print(isogram(args[0]))
        exit()

    #No options nor arguments given, refer to --help.
    print("Ooops. Missing options or arguments. See --help for usage.")
    exit()


def test():
    """Runs some examples to test the isogram(), tidyString() and
    prepareNgrams() functions."""
    #Test isogram()
    print("Testing isogram function.")
    time.sleep(2)
    candidates = [
        'abca',   # 0-isogram
        'abcd',   # 1-isogram
        'baba',   # 2-isogram
        'ababab'  # 3-isogram
    ]
    print("Candidates:", candidates)
    print("Results:")
    for cand in candidates:
        print("  ", cand, ":", isogram(cand))
    print("\n")
    time.sleep(1)

    #Test tidyString()
    print("Testing string tidy function.")
    time.sleep(2)
    candidate = 'TestBl$a\'h-foo.bar.áÉìÒüẄŷẐ_FOO_BAR'
    print("Candidate:", candidate)
    print("Result:", tidyString(candidate))
    print("\n")
    time.sleep(1)

    #Test prepareNGrams()
    print("Testing ngram extraction (this may take an hour or more).")
    time.sleep(2)
    try:
        prepareNgrams("./test/testgrams", "./test/testgrams.csv")
        print("Ngram extraction was successful.")
    except Exception:
        print("An error occurred:", Exception)
    print("\n")
    time.sleep(1)

    print("All tests are complete.")


def prepareNgrams(directory, outfile):
    """Extract strings from Google Ngrams and prepare them for running isogram()
    on them.

    The function extracts all entries from all the ngram files in the given
    directory and compacts them, so that there is only one entry per ngram. The
    output file then contains one line for each ngram, with the original ngram,
    a tidied version (run through tidyString()), the combined match_count and
    the combined volume_count, all separated by a single tabstop.

    If the total_counts file from the Google Ngrams corpus is found in the
    directory, a second file of the name outfile.totals is written which
    includes the cumulative total of the match and volume counts. This data can
    later be used to calculate relative frequencies, and the function
    detectIsograms() automatically looks for this file.

    The function has been written to run on the 1-gram files from Google Ngrams
    version 2, http://storage.googleapis.com/books/ngrams/books/datasetsv2.html.

    Keyword arguments:
    directory -- The path of the directory where all the ngram files are located
    outfile -- path to the file the output should be written to
    """
    #Remove trailing slashes from directory path
    directory = directory.rstrip("\\/")
    sys.stdout.write("Reading directory: "+directory+"\n")
    sys.stdout.write("Writing to: "+outfile+"\n")
    outfh = codecs.open(outfile, 'w', "utf8")
    #Read all files in directory
    for infile in os.listdir(directory):
        if(fnmatch.fnmatch(infile, "*.gz")): #Process a 1-gram file
            sys.stdout.write("Reading file: "+infile+"\n")
            infh = gzip.open(directory+"/"+infile, 'rb')
            i = 0 #Counter to give progress feedback
            current_headword = None
            current_ngram = None
            for line in infh:
                i += 1
                line = str(line, encoding="utf8")
                line = line.strip().split("\t")
                #Still on the same ngram, so add match_count and volume_count
                if line[0] == current_headword:
                    if( i < 100000 ):
                            sys.stdout.write("Processing line: %i\r" % i)
                    else:
                        if( i % 10000 is 0 ):
                            sys.stdout.write("Processing line: %i\r" % i)
                    #print("Adding to Ngram:", current_headword)
                    current_ngram[2] += int(line[2])
                    current_ngram[3] += int(line[3])
                #New ngram. Save current ngram and move on to new ngram.
                if line[0] != current_headword and current_headword != None:
                    current_ngram.insert(0, tidyString(current_ngram[0])) #Prepend tidied version
                    current_ngram.remove(current_ngram[2]) #Remove year column (FIXME: Currently removes the value, not the key index [2])
                    current_ngram[2] = str(current_ngram[2])
                    current_ngram[3] = str(current_ngram[3])
                    #Write ngram, but skip those containing numbers...
                    if( current_ngram[0].isalpha() ):
                        current_ngram = "\t".join(current_ngram)
                        outfh.write(current_ngram + "\n")
                #First or new ngram
                if current_headword == None or line[0] != current_headword:
                    current_headword = line[0]
                    current_ngram = line
                    current_ngram[2] = int(current_ngram[2])
                    current_ngram[3] = int(current_ngram[3])
            infh.close()
            sys.stdout.write("Finished processing file.\n")
        elif(fnmatch.fnmatch(infile, "*totalcounts*.txt")): #Process the total_counts file
            sys.stdout.write("Reading total_counts file: "+infile+"\n")
            infh = open(directory+"/"+infile)
            counts = infh.read()
            infh.close()
            counts = counts.split("\t")
            total_1grams = 0
            total_volumes = 0
            for year in counts:
                year = year.split(",")
                if(len(year) < 4): #Skip fields that are empty (e.g. first and last)
                    pass
                else:
                    total_1grams += int(year[1])
                    total_volumes += int(year[3])
            sys.stdout.write("Counted %i 1-grams and %i volumes.\n" % (total_1grams, total_volumes))
            sys.stdout.write("Writing totals to file: %s\n" % (outfile+".totals"))
            totfh = codecs.open(outfile+".totals", "w", "utf8")
            totfh.write("!total\t!any\t%i\t%i\n" % (total_1grams, total_volumes))
            totfh.close()
            sys.stdout.write("Finished processing total_counts file.\n")
    outfh.close()
    sys.stdout.write("Finished processing all files in directory.\n")

def prepareBNC(infile, outfile):
    """Prepare a tidied up word list from the BNC word frequency list, in
    preparation for running isogram() on the list.

    A second file of the name outfile.totals is written which includes the total
    word and volume counts from the corpus. This data can later be used to
    calculate relative frequencies, and the function detectIsograms()
    automatically looks for this file.

    Keyword arguments:
    infile -- The input file (should be the file usually named "all.al.gz")
    outfile -- The file for writing the resulting word list
    """
    #Open the infile
    infh = gzip.open(infile, "rb")
    outfh = codecs.open(outfile, "w", "utf8")
    i = 0 #Counter to show progress
    current_headword = None #To keep track of and combine tokens regardless of POS
    current_item = None
    sys.stdout.write("Preparing word list from file %s...\n" % infile)
    #Read line by line
    for line in infh:
        i += 1
        if( i < 100000 ):
                sys.stdout.write("Processing line: %i\r" % i)
        else:
            if( i % 10000 is 0 ):
                sys.stdout.write("Processing line: %i\r" % i)
        line = str(line, encoding="utf8")
        item = line.strip().split(" ") #Fields separated by spaces
        #Check for total counts (given as "!!WHOLE_CORPUS")
        if(item[1] == "!!WHOLE_CORPUS"):
            total_1grams = int(item[0])
            total_volumes = int(item[3])
            sys.stdout.write("Detected total counts: %i 1-grams and %i volumes.\n" % (total_1grams, total_volumes))
            sys.stdout.write("Writing totals to file: %s\n" % (outfile+".totals"))
            totfh = codecs.open(outfile+".totals", "w", "utf8")
            totfh.write("!total\t!any\t%i\t%i\n" % (total_1grams, total_volumes))
            totfh.close()
            sys.stdout.write("Finished writing total counts. Resuming processing.\n")
            continue
        #Tidy string
        tidy = tidyString(item[1])
        #Ignore empty strings
        if(len(tidy) is 0):
            continue
        #Exclude items with "%", "_", "&", "/", ":" or numbers in them
        if(   item[1].find("&") > -1
           or item[1].find("_") > -1
           or item[1].find("%") > -1
           or item[1].find("/") > -1
           or item[1].find(":") > -1
           or not tidy.isalpha()
          ):
            continue
        #Exclude number-initial strings
        if(tidy[0].isdigit()):
            continue
        #Still on the same headword, so add frequencies and file_counts
        if(tidy == current_headword and current_headword != None):
            current_item[2] += int(item[0]) #Add FREQ
            current_item[3] += int(item[3]) #Add FILE_COUNT (Maybe not best of ideas?)
        #New headword, save current item and move on
        if(tidy != current_headword and current_headword != None):
            current_item[2] = str(current_item[2])
            current_item[3] = str(current_item[3])
            current_item = "\t".join(current_item)
            outfh.write(current_item + "\n")
        #First or new headword
        if(tidy != current_headword or current_headword == None):
            #Reorder them, as they are FREQ, WORD, POS, FILE_COUNT
            #We want: WORD, WORD_POS, FREQ, FILE_COUNT
            #Similar to: tidied, original_ngram, match_count, volume_count
            current_item = [tidy, item[1]+"_"+item[2], int(item[0]), int(item[3])]
            current_headword = tidy
    sys.stdout.write("Done preparing word list from BNC frequency list.\n")


def tidyString(string):
    """Tidies up strings from Google Ngrams to give a uniform lowecase string
    suitable for evaluation as an isogram.

    The function removes everything after the first underscore, which is used to
    attach Part of Speech information. It then strips the string of all
    diacritics and special characters and finally transforms the entire string
    to lowercase.

    Keyword arguments:
    string -- The string to be tidied. This should be in utf8.
    """
    #Strip anything appended by an underscore (i.e. POS info in Google Ngrams)
    if "_" in string:
        string = string[0:string.find("_")]

    #Strip all combining marks
    string = str(unicodedata.normalize('NFKD', string).encode('ASCII', 'ignore'), encoding="ASCII")

    #Lowercase entire string
    string = string.lower()

    #Strip everything that is not an alphanumeric character
    string = ''.join(c for c in str(string) if c.isalnum())

    return string

def isPalindrome(candidate):
    """Returns true if the given string is a palindrome or false if it is not.

    Note that the function is case sensitive, so you may want to lowercase or
    uppercase the entire string before passing it to this function.
    """
    if(candidate == ''.join(reversed(candidate))):
        return True
    return False


def isTautonym(candidate):
    """Returns true if the given string is a tautonym or false if it is not.

    Note that the function is case sensitive, so you may want to lowercase or
    uppercase the entire string before passing it to this function.
    """
    if(len(candidate)%2 != 0):
        return False
    if(candidate[int(len(candidate)/2):] == candidate[:int(len(candidate)/2)]):
        return True
    return False


def isogram(candidate):
    """Returns the order of isogram for a given string.

    The function returns 0 if the given string is not an isogram.

    Some examples:
    "abca"   -- not an isogram, returns 0
    "abcd"   -- a 1-isogram, returns 1
    "abab"   -- a 2-isogram, returns 2
    "ababab" -- a 3-isogram, returns 3
    ...

    Note that this function will treat each character as unique, thus while
    "abab" and "AbAb" will be treated as a 2-isogram, "ab ab", "Abab", "ab-ab",
    "aBab", etc. will not be recognised as isograms. You may want to strip all
    extra characters and whitespace, as well as irrelevant diacritics and either
    uppercase or lowercase the entire string before using this function.

    Keyword arguments:
    candidate -- the string to be examined
    """
    #Count occurences of each letter
    letters = {}
    for letter in candidate:
        if letter in letters:
            letters[letter] += 1
        else:
            letters[letter] = 1
    #Establish order of isogram
    order = 0
    for k in letters:
        if order == 0:
            order = letters[k] #Set "order" to count of first letter
        if order != letters[k]: #Check if all letters are of same order
            return 0 #Letter count differs -> this is not an isogram
    return order #No letter count differences -> this is an n-isogram

def frequencyPerMillion(x, total):
    """Calculate the frequency per million of x given total."""
    return ((float(x)/float(total))*1000000)

def percentageOfTotal(x, total):
    """Calculate the percentage (i.e. frequency per hundred) of x given total."""
    return ((float(x)/float(total))*100)

def detectIsograms(infile, outfile):
    """Extract isograms from a list of words.

    This function reads every line from infile, which is a tab separated word
    list of the form (tidied_word  original_word  match_count  volume_count) and
    then writes these to outfile as (isogramy  string_length  tidied_word
    original_word  match_count  volume_count  match_count_per_million
    volume_count_as_percent  is_palindrome  is_tautonym), where "isogramy" is a
    numeric value indicating the number of times each grapheme occurs in the
    isogram. Relative frequencies, i.e. counts per million and percentage of
    volumes is computed from the .totals files generated by prepateNgrams()
    and prepareBNC(), if the file is not found these will always default to
    zero.

    A second file of the name outfile.totals is written which includes the
    total number of 1grams and volumes from the input .totals file and the total
    number of isograms, palindromes and tautonyms found. Note that the number
    of palindromes and tautonyms is that actually present in the word list, and
    thus usually larger than the total number of all palindromes/tautonyms
    which are also isograms. This is so that a relative percentage can be
    computed to indicate which proportion of all palindromes/tautonyms in the
    corpus are also isograms.

    Keyword arguments:
    infile -- the input file
    outfile -- the output file
    """
    sys.stdout.write("Input file: " + infile + "\n")
    sys.stdout.write("Output file: " + outfile + "\n")
    #Open input and output files
    infh = codecs.open(infile, "r", "utf8")
    outfh = codecs.open(outfile, "w", "utf8")
    #See if total counts are available for infile
    try:
        totfh = open(infile+".totals", "r")
        totals = totfh.read()
        totals = totals.split()
        if(len(totals) > 3):
            total_1grams = int(totals[2])
            total_volumes = int(totals[3])
        else:
            total_1grams = 0
            total_volumes = 0
        totfh.close()
    except Exception:
        total_1grams = 0
        total_volumes = 0
    i = 0 #Counter to indicated progress
    total_isograms = 0 #Counter for isograms
    total_palindromes = 0
    total_tautonyms = 0
    #Traverse through input lines and test for isogramy
    for line in infh:
        i += 1
        if( i < 100000 ):
                sys.stdout.write("Processing line: %i\r" % i)
        else:
            if( i % 10000 is 0 ):
                sys.stdout.write("Processing line: %i\r" % i)
        item = line.strip().split("\t")
        if(isPalindrome(item[0])):
            total_palindromes += 1
        if(isTautonym(item[0])):
            total_tautonyms += 1
        isogramy = isogram(item[0])
        if isogramy > 0:
            if(total_1grams > 0):
                item.append(str(float(frequencyPerMillion(item[2], total_1grams)))) #Append frequency per million
            else:
                item.append(str(0)) #Append 0 for frequency
            if(total_volumes > 0):
                item.append(str(float(percentageOfTotal(item[3], total_volumes))))   #Append volume count as percentage
            else:
                item.append(str(0))   #Append 0 for volume percentage
            item.append(str(int(isPalindrome(item[0])))) #Append palindromy
            item.append(str(int(isTautonym(item[0]))))   #Append tautonymy
            item.insert(0, str(len(item[0])))            #Prepend string length
            item.insert(0, str(isogramy))                #Prepend isogramy
            line = "\t".join(item)
            outfh.write(line + "\n")
            total_isograms += 1
    sys.stdout.write("Finished processing.        \n")
    sys.stdout.write("Found %i isograms, %i palindromes and %i tautonyms.\n" % (total_isograms, total_palindromes, total_tautonyms))
    sys.stdout.write("Writing totals to file %s...   " % (outfile+".totals"))
    totfh = codecs.open(outfile+".totals", "w", "utf8")
    totfh.write("!total_1grams\t%i\n" % total_1grams)
    totfh.write("!total_volumes\t%i\n" % total_volumes)
    totfh.write("!total_isograms\t%i\n" %total_isograms)
    totfh.write("!total_palindromes\t%i\n" %total_palindromes)
    totfh.write("!total_tautonyms\t%i\n" %total_tautonyms)
    totfh.close()
    sys.stdout.write("Done.\n")




if __name__ == '__main__':
    main()
