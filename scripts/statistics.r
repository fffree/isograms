###
### SETUP AND LOAD DATA FILES
###

# Set working directory
setwd("C:\\Users\\florian.breit.12\\Documents\\Documents\\Publications\\in-prep\\isograms")

# Load DBI and RSQLite
library("DBI")
library("RSQLite")

# Connect to database
db.h <- dbConnect(RSQLite::SQLite(), dbname="./results/isograms.db")
db.tables <- dbListTables(db.h)

# Retrieve data
#bnc.raw            <- dbGetQuery(db.h, "SELECT * FROM bnc")
#bnc.compacted      <- dbGetQuery(db.h, "SELECT * FROM bnc_compacted")
#bnc.totals         <- dbGetQuery(db.h, "SELECT * FROM bnc_totals")
#ngrams.raw         <- dbGetQuery(db.h, "SELECT * FROM ngrams")
#ngrams.compacted   <- dbGetQuery(db.h, "SELECT * FROM ngrams_compacted")
#ngrams.totals      <- dbGetQuery(db.h, "SELECT * FROM ngrams_totals")
#combined.raw       <- dbGetQuery(db.h, "SELECT * FROM combined")
#combined.compacted <- dbGetQuery(db.h, "SELECT * FROM combined_compacted")
#intersected        <- dbGetQuery(db.h, "SELECT * FROM intersected")
#
# There is a problem with 64-bit integers and RSQLite that causes a buffer overflow in the count column.
# See links [1], [2]. We address this by selecting as cast(x as text) then re-converting to as.numeric(x).
# [1] https://github.com/rstats-db/RSQLite/issues/65
# [2] http://stackoverflow.com/questions/32423330/how-to-retrieve-large-numbers-from-database-with-rsqlite-buffer-overflow
tmp.select.workaround <- "SELECT isogramy, length, word, source_pos, CAST(count as TEXT) as count, vol_count, count_per_million, vol_count_as_percent, is_palindrome, is_tautonym FROM"
bnc.raw            <- dbGetQuery(db.h, paste(tmp.select.workaround, "bnc"))
bnc.compacted      <- dbGetQuery(db.h, paste(tmp.select.workaround, "bnc_compacted"))
ngrams.raw         <- dbGetQuery(db.h, paste(tmp.select.workaround, "ngrams"))
ngrams.compacted   <- dbGetQuery(db.h, paste(tmp.select.workaround, "ngrams_compacted"))
combined.raw       <- dbGetQuery(db.h, paste(tmp.select.workaround, "combined"))
combined.compacted <- dbGetQuery(db.h, paste(tmp.select.workaround, "combined_compacted"))
intersected        <- dbGetQuery(db.h, paste(tmp.select.workaround, "intersected"))
bnc.totals         <- dbGetQuery(db.h, "SELECT * FROM bnc_totals")
ngrams.totals      <- dbGetQuery(db.h, "SELECT * FROM ngrams_totals")
rm(tmp.select.workaround)
# Recast the count column as numeric
bnc.raw$count            <- as.numeric(bnc.raw$count)
bnc.compacted$count      <- as.numeric(bnc.compacted$count)
ngrams.raw$count         <- as.numeric(ngrams.raw$count)
ngrams.compacted$count   <- as.numeric(ngrams.compacted$count)
combined.raw$count       <- as.numeric(combined.raw$count)
combined.compacted$count <- as.numeric(combined.compacted$count)
intersected$count        <- as.numeric(intersected$count)

# Make short aliases for the compacted datasets (we'll use them most)
bnc      <- bnc.compacted
ngrams   <- ngrams.compacted
combined <- combined.compacted



###
### TYPE TOTALS
###

# Type totals
cat(
  sprintf(
    "ISOGRAMS FOUND BEFORE COMPACTING\n  In Ngrams: %i\n  In BNC:    %i\n  Combined:  %i\n\n",
    dim(ngrams.raw)[1],
    dim(bnc.raw)[1],
    dim(combined.raw)[1]
  )
)

cat(
  sprintf(
    "ISOGRAMS FOUND AFTER COMPACTING\n  In Ngrams: %i\n  In BNC:    %i\n  Combined:  %i\n  Intersect: %i\n\n",
    dim(ngrams)[1],
    dim(bnc)[1],
    dim(combined)[1],
    dim(intersected)[1]
  )
)



##
## ISOGRAM LENGTHS
##

# Isogram Distribution by Length
cat(
  sprintf(
    "LONGEST ISOGRAMS\n  In Ngrams: %i\n  In BNC:   %i\n  Intersect: %i\n\n",
    max(ngrams$length),
    max(bnc$length),
    max(intersected$length)
  )
)

# Median lengths of isograms and standard deviations
cat(
  sprintf(
    paste0(
      "SUMMARY OF LENGTH DISTRIBUTION OF ISOGRAMS\n",
      "             MIN   MAX  MEDIAN    MEAN    SD\n",
      "  In Ngrams: %i    %i   %i        %.2f    %.2f\n",
      "  In BNC:    %i    %i   %i        %.2f    %.2f\n",
      "  Combined:  %i    %i   %i        %.2f    %.2f\n",
      "  Intersect: %i    %i   %i        %.2f    %.2f\n\n"
    ),
    min(ngrams$length),      max(ngrams$length),      median(ngrams$length),      mean(ngrams$length),      sd(ngrams$length),
    min(bnc$length),         max(bnc$length),         median(bnc$length),         mean(bnc$length),         sd(bnc$length),
    min(combined$length),    max(combined$length),    median(combined$length),    mean(combined$length),    sd(combined$length),
    min(intersected$length), max(intersected$length), median(intersected$length), mean(intersected$length), sd(intersected$length)
  )
)

# How many isograms of each length are there? Let's get counts for the length distributions!
ngrams.length.dist <- dbGetQuery(db.h, "SELECT length, count(*) as count FROM ngrams_compacted GROUP BY length")
bnc.length.dist <- dbGetQuery(db.h, "SELECT length, count(*) as count FROM bnc_compacted GROUP BY length")
combined.length.dist <- dbGetQuery(db.h, "SELECT length, count(*) as count FROM combined_compacted GROUP BY length")
intersected.length.dist <- dbGetQuery(db.h, "SELECT length, count(*) as count FROM intersected GROUP BY length")

# Make a plot of the length distribution of isograms
plot(x=c(0,20), y=c(0, 300000), type="n", xlab="Length", ylab="Number of Isograms", xlim=c(0, 20), ylim=c(0, 300000))
title(main="Isogram Counts by Length")
lines(ngrams.length.dist[1:20,], type="o", col="red", lwd=2, pch=1)
lines(bnc.length.dist[1:20,], type="o", col="blue", lwd=2, pch=4)
legend(x=14, y=300000, c("Ngrams compacted", "BNC compacted"), pch=c(1, 4), lwd=c(2, 2), col=c("red", "blue"))
#lines(intersected.length.dist[1:20,], type="o", col="yellow", lwd=2, pch="x") # Matches bnc
#lines(combined.length.dist[1:20,], type="o", col="green", lwd=2, pch="@")     # Matches ngrams

# Test whether the length distributions between the different data sets are significantly different
# Use Kolmogorov-Smirnov Tests Two Samples Test (checks if two distrubutions are of the same type using ecdf)
tmp.result <- ks.test(x=ngrams.length.dist$length, y=bnc.length.dist$length)
cat("DIFFERENCE BETWEEN LENGTH DISTRIBUTION OF NGRAMS AND BNC\n"); tmp.result; cat("\n")
rm(tmp.result)

# Plot the fall-off/tail of the length distributions (lengths 10-20?)
plot(x=c(10,20), y=c(0, 30000), type="n", xlab="Length", ylab="Number of Isograms", xlim=c(10, 20), ylim=c(0, 30000))
title(main="Length Distribution of Isograms Between Lengths 10 and 20")
lines(ngrams.length.dist[ngrams.length.dist$length %in% 10:20,], type="o", col="red", lwd=2, pch=1)
lines(bnc.length.dist[bnc.length.dist$length %in% 10:20,], type="o", col="blue", lwd=2, pch=4)
legend(x=17, y=30000, c("Ngrams compacted", "BNC compacted"), pch=c(1, 4), lwd=c(2, 2), col=c("red", "blue"))

# Find an alternative for subjective "interesting because of rarity" - 99.9th percentile?
tmp.ecdf.bnc <- ecdf(bnc$length)
tmp.ecdf.ngrams <- ecdf(ngrams$length)
tmp.ecdf.combined <- ecdf(combined$length)
tmp.ecdf.intersected <- ecdf(intersected$length)

# Borgmann (1974) gauged that isograms become interesting at length 15, what percentile is this?
cat(
  sprintf(
    "WHAT PERCENTILE IS A 15-letter CUTOFF (BORGMANN 1974)?\n  In Ngrams: %.4f\n  In BNC:   %.4f\n  Combined: %.4f\n  Intersect: %.4f\n(N.B.: Rounded to even, precision 4)\n\n",
    round(tmp.ecdf.ngrams(15), digits=4),
    round(tmp.ecdf.bnc(15), digits=4),
    round(tmp.ecdf.combined(15), digits=4),
    round(tmp.ecdf.intersected(15), digits=4)
  )
)

# Taking it the other way around, what is the 95th percentile?
cat(
  sprintf(
    "WHAT IS THE 95th PERCENTILE FOR THE LENGTH DISTRIBUTION?\n  In Ngrams: %i\n  In BNC:   %i\n  Combined: %i\n  Intersect: %i\n\n",
    quantile(ngrams$length, .95),
    quantile(bnc$length, .95),
    quantile(combined$length, .95),
    quantile(intersected$length, .95)
  )
)

# What is the 99th percentile?
cat(
  sprintf(
    "WHAT IS THE 99th PERCENTILE FOR THE LENGTH DISTRIBUTION?\n  In Ngrams: %i\n  In BNC:   %i\n  Combined: %i\n  Intersect: %i\n\n",
    quantile(ngrams$length, .99),
    quantile(bnc$length, .99),
    quantile(combined$length, .99),
    quantile(intersected$length, .99)
  )
)

# What is the 99.95th percentile?
cat(
  sprintf(
    "WHAT IS THE 99.95th PERCENTILE FOR THE LENGTH DISTRIBUTION?\n  In Ngrams: %i\n  In BNC:   %i\n  Combined: %i\n  Intersect: %i\n\n",
    quantile(ngrams$length, .9995),
    quantile(bnc$length, .9995),
    quantile(combined$length, .9995),
    quantile(intersected$length, .9995)
  )
)

# Make an ecdf plot of all three distributions
plot(tmp.ecdf.ngrams, col="grey", pch=NA, lty=2, xlim=c(0, 20), xlab="Length", ylab="ecdf", main="", verticals=TRUE)
plot(tmp.ecdf.ngrams, col="red", pch=1, lwd=2, add=TRUE)
plot(tmp.ecdf.bnc, col="blue", pch=4, lwd=2, add=TRUE)
#plot(tmp.ecdf.combined, col="yellow", pch=5, lwd=2, add=TRUE) # Nearly identical to Ngrams so no point drawing
plot(tmp.ecdf.intersected, col="green", pch=6, lwd=2, add=TRUE)
title(main="Empirical Cumulative Distribution of Isograms by Length")
legend(x=14, y=0.3, c("Ngrams compacted", "BNC compacted", "Intersected"), pch=c(1, 4, 6), lwd=c(2, 2), col=c("red", "blue", "green"))

rm(tmp.ecdf.ngrams, tmp.ecdf.bnc, tmp.ecdf.combined, tmp.ecdf.intersected)



##
## LENGTH OF HIGHER ORDER ISOGRAMS
##

tmp.old.par <- par() # Save state of plotting device before modifying it

# Make a plot of the length distribution of isograms by order of isogramy
layout(matrix(c(1,1,1,  7,2,3,  7,4,5,  7,6,6), 4, 3, byrow=TRUE), heights=c(0.1, 0.35, 0.35, 0.2), widths=c(0.05, 0.475, 0.475))

par(mar=c(0,0,4,0))
plot.new()
title(main="Length Distribution of Higher Order Isograms", cex.main=2)

par(mar=c(2,4,2,2)) #mar=c(bottom, left, top, right)
plot(x=c(0,16), y=c(0, 2500), type="n", xlab="", ylab="", main="Ngrams compacted", cex.main=1.5)
lines(table(ngrams$length[ngrams$isogramy==2]), type="o", col="red", lwd=2, pch=1)
lines(table(ngrams$length[ngrams$isogramy==3]), type="o", col="blue", lwd=2, pch=4)
lines(table(ngrams$length[ngrams$isogramy>=4]), type="o", col="green", lwd=2, pch=6)

par(mar=c(2,2,2,2)) #mar=c(bottom, left, top, right)
plot(x=c(0,16), y=c(0, 300), type="n", xlab="", ylab="", main="BNC compacted", cex.main=1.5)
lines(table(bnc$length[bnc$isogramy==2]), type="o", col="red", lwd=2, pch=1)
lines(table(bnc$length[bnc$isogramy==3]), type="o", col="blue", lwd=2, pch=4)
lines(table(bnc$length[bnc$isogramy>=4]), type="o", col="green", lwd=2, pch=6)

par(mar=c(2,4,2,2)) #mar=c(bottom, left, top, right)
plot(x=c(0,16), y=c(0, 2500), type="n", xlab="", ylab="", main="Combined", cex.main=1.5)
lines(table(combined$length[combined$isogramy==2]), type="o", col="red", lwd=2, pch=1)
lines(table(combined$length[combined$isogramy==3]), type="o", col="blue", lwd=2, pch=4)
lines(table(combined$length[combined$isogramy>=4]), type="o", col="green", lwd=2, pch=6)

par(mar=c(2,2,2,2)) #mar=c(bottom, left, top, right)
plot(x=c(0,16), y=c(0, 300), type="n", xlab="", ylab="", main="Intersected", cex.main=1.5)
lines(table(intersected$length[intersected$isogramy==2]), type="o", col="red", lwd=2, pch=1)
lines(table(intersected$length[intersected$isogramy==3]), type="o", col="blue", lwd=2, pch=4)
lines(table(intersected$length[intersected$isogramy>=4]), type="o", col="green", lwd=2, pch=6)

par(mar=c(0,0,0,0))
plot.new()
legend(x=0.25, y=0.45, c("2-isograms", "3-isograms", "4-isograms or higher"), pch=c(1, 4, 6), lwd=c(2, 2), col=c("red", "blue", "green"), horiz=TRUE, xpd=TRUE)
text(x=0.5, y=0.7, labels="Length", cex=1.5)

par(mar=c(0,0,0,0))
plot.new()
text(x=0.7, y=0.6, labels="Number of Isograms", cex=1.5, srt=90)

par(tmp.old.par) #Reset plotting device
rm(tmp.old.par)

# Median, mean and SD for length of different order isograms
cat(
  sprintf(
    paste0(
      "SUMMARY OF LENGTH DISTRIBUTION OF ISOGRAMS BY ORDER OF ISOGRAMY\n",
      "               MIN   MAX  MEDIAN    MEAN    SD\n",
      "  1-isograms:  %i     %i   %i         %.2f    %.2f\n",
      "  2-isograms:  %i     %i   %i         %.2f    %.2f\n",
      "  3-isograms:  %i     %i   %i         %.2f    %.2f\n",
      "  4-isograms+: %i     %i   %i         %.2f    %.2f\n",
      "  (NB: This is for the intersected dataset only.)\n\n"
    ),
    min(intersected$length[intersected$isogramy==1]), max(intersected$length[intersected$isogramy==1]), median(intersected$length[intersected$isogramy==1]), mean(intersected$length[intersected$isogramy==1]), sd(intersected$length[intersected$isogramy==1]),
    min(intersected$length[intersected$isogramy==2]), max(intersected$length[intersected$isogramy==2]), median(intersected$length[intersected$isogramy==2]), mean(intersected$length[intersected$isogramy==2]), sd(intersected$length[intersected$isogramy==2]),
    min(intersected$length[intersected$isogramy==3]), max(intersected$length[intersected$isogramy==3]), median(intersected$length[intersected$isogramy==3]), mean(intersected$length[intersected$isogramy==3]), sd(intersected$length[intersected$isogramy==3]),
    min(intersected$length[intersected$isogramy>=4]), max(intersected$length[intersected$isogramy>=4]), median(intersected$length[intersected$isogramy>=4]), mean(intersected$length[intersected$isogramy>=4]), sd(intersected$length[intersected$isogramy>=4])
  )
)

# Calculate 95th, 99th and 99.95th percentile based on order of isogramy
cat(
  sprintf(
    paste0(
      "95th, 99th and 99.95th PERCENTILE BY ORDER OF ISOGRAMY\n",
      "               95      99      99.95\n",
      "  1-isograms:   %.2f   %.2f   %.2f\n",
      "  2-isograms:  %.2f   %.2f   %.2f\n",
      "  3-isograms:  %.2f   %.2f   %.2f\n",
      "  4-isograms+: %.2f   %.2f   %.2f\n",
      "  (NB: This is for the intersected dataset only.)\n\n"
    ),
    quantile(intersected$length[intersected$isogramy==1], .95), quantile(intersected$length[intersected$isogramy==1], .99), quantile(intersected$length[intersected$isogramy==1], .9995),
    quantile(intersected$length[intersected$isogramy==2], .95), quantile(intersected$length[intersected$isogramy==2], .99), quantile(intersected$length[intersected$isogramy==2], .9995),
    quantile(intersected$length[intersected$isogramy==3], .95), quantile(intersected$length[intersected$isogramy==3], .99), quantile(intersected$length[intersected$isogramy==3], .9995),
    quantile(intersected$length[intersected$isogramy>=4], .95), quantile(intersected$length[intersected$isogramy>=4], .99), quantile(intersected$length[intersected$isogramy>=4], .9995)
  )
)



##
## FREQUENCY DISTRIBUTION OF ISOGRAMS
##

# Let's find the ten most frequent isograms in each data set

tmp.n <- 10 # How many items to return
tmp.cols <- c(1:3, 5:10) # Which columns to show

cat(
  "MOST FREQUENT ISOGRAMS BY TOKEN FREQUENCY\n",
  "NGRAMS:\n"
); head(ngrams[order(ngrams$count_per_million, decreasing=TRUE),], n=tmp.n)[,tmp.cols]; cat(
  "BNC:\n"
); head(bnc[order(bnc$count_per_million, decreasing=TRUE),], n=tmp.n)[,tmp.cols]; cat(
  "COMBINED COMPACTED:\n"
); head(combined[order(combined$count_per_million, decreasing=TRUE),], n=tmp.n)[,tmp.cols]; cat(
  "INTERSECTED:\n"
); head(intersected[order(intersected$count_per_million, decreasing=TRUE),], n=tmp.n)[,tmp.cols]; cat(
  "\n\n"
)

cat(
  "MOST FREQUENT ISOGRAMS BY VOLUME COUNT\n",
  "NGRAMS:\n"
); head(ngrams[order(ngrams$vol_count_as_percent, decreasing=TRUE),], n=tmp.n)[,tmp.cols]; cat(
  "BNC:\n"
); head(bnc[order(bnc$vol_count_as_percent, decreasing=TRUE),], n=tmp.n)[,tmp.cols]; cat(
  "COMBINED COMPACTED:\n"
); head(combined[order(combined$vol_count_as_percent, decreasing=TRUE),], n=tmp.n)[,tmp.cols]; cat(
  "INTERSECTED:\n"
); head(intersected[order(intersected$vol_count_as_percent, decreasing=TRUE),], n=tmp.n)[,tmp.cols]; cat(
  "\n\n"
)

rm(tmp.n); rm(tmp.cols)

# Let's find the ten LEAST frequent isograms in each data set

tmp.n <- 10 # How many items to return
tmp.cols <- c(1:3, 5:10) # Which columns to show

cat(
  "LEAST FREQUENT ISOGRAMS BY TOKEN FREQUENCY\n",
  "NGRAMS:\n"
); head(ngrams[order(ngrams$count_per_million),], n=tmp.n)[,tmp.cols]; cat(
  "BNC:\n"
); head(bnc[order(bnc$count_per_million),], n=tmp.n)[,tmp.cols]; cat(
  "COMBINED COMPACTED:\n"
); head(combined[order(combined$count_per_million),], n=tmp.n)[,tmp.cols]; cat(
  "INTERSECTED:\n"
); head(intersected[order(intersected$count_per_million),], n=tmp.n)[,tmp.cols]; cat(
  "\n\n"
)

cat(
  "LEAST FREQUENT ISOGRAMS BY VOLUME COUNT\n",
  "NGRAMS:\n"
); head(ngrams[order(ngrams$vol_count_as_percent),], n=tmp.n)[,tmp.cols]; cat(
  "BNC:\n"
); head(bnc[order(bnc$vol_count_as_percent),], n=tmp.n)[,tmp.cols]; cat(
  "COMBINED COMPACTED:\n"
); head(combined[order(combined$vol_count_as_percent),], n=tmp.n)[,tmp.cols]; cat(
  "INTERSECTED:\n"
); head(intersected[order(intersected$vol_count_as_percent),], n=tmp.n)[,tmp.cols]; cat(
  "\n\n"
)

rm(tmp.n); rm(tmp.cols)

# Are there hapax legomena?
cat(
  sprintf(
    paste0(
      "ARE THERE HAPAX LEGOMENA IN THE DATA SETS?\n",
      "  Ngrams:     %s  (%i)\n",
      "  BNC:        %s   (%i)\n",
      "  Combined:   %s   (%i)\n",
      "  Intersect:  %s  (%i)\n\n"
    ),
    dim(ngrams[ngrams$count==1,])[1]>0,           dim(ngrams[ngrams$count==1,])[1],
    dim(bnc[bnc$count==1,])[1]>0,                 dim(bnc[bnc$count==1,])[1],
    dim(combined[combined$count==1,])[1]>0,       dim(combined[combined$count==1,])[1],
    dim(intersected[intersected$count==1,])[1]>0, dim(intersected[intersected$count==1,])[1]
  )
)

# Are there hapax legomena?
cat(
  sprintf(
    paste0(
      "ARE THERE ISOGRAMS WHICH OCCUR IN ONLY A SINGLE VOLUME?\n",
      "  Ngrams:     %s  (%i)\n",
      "  BNC:        %s   (%i)\n",
      "  Combined:   %s   (%i)\n",
      "  Intersect:  %s  (%i)\n\n"
    ),
    dim(ngrams[ngrams$vol_count==1,])[1]>0,           dim(ngrams[ngrams$vol_count==1,])[1],
    dim(bnc[bnc$vol_count==1,])[1]>0,                 dim(bnc[bnc$vol_count==1,])[1],
    dim(combined[combined$vol_count==1,])[1]>0,       dim(combined[combined$vol_count==1,])[1],
    dim(intersected[intersected$vol_count==1,])[1]>0, dim(intersected[intersected$vol_count==1,])[1]
  )
)

# Summary statistics for normalised token frequency distribution
cat(
  sprintf(
    paste0(
      "SUMMARY OF NORMALISED VOLUME FREQUENCIES OF ISOGRAMS\n",
      "             MIN     MAX         MEDIAN      MEAN    SD\n",
      "  In Ngrams: %.4f  %.2f    %.4f      %.2f    %.2f\n",
      "  In BNC:    %.4f  %.2f    %.4f      %.2f    %.2f\n",
      "  Combined:  %.4f  %.2f    %.4f      %.2f    %.2f\n",
      "  Intersect: %.4f  %.2f    %.4f      %.2f    %.2f\n\n"
    ),
    min(ngrams$vol_count_as_percent),      max(ngrams$vol_count_as_percent),      median(ngrams$vol_count_as_percent),      mean(ngrams$vol_count_as_percent),      sd(ngrams$vol_count_as_percent),
    min(bnc$vol_count_as_percent),         max(bnc$vol_count_as_percent),         median(bnc$vol_count_as_percent),         mean(bnc$vol_count_as_percent),         sd(bnc$vol_count_as_percent),
    min(combined$vol_count_as_percent),    max(combined$vol_count_as_percent),    median(combined$vol_count_as_percent),    mean(combined$vol_count_as_percent),    sd(combined$vol_count_as_percent),
    min(intersected$vol_count_as_percent), max(intersected$vol_count_as_percent), median(intersected$vol_count_as_percent), mean(intersected$vol_count_as_percent), sd(intersected$vol_count_as_percent)
  )
)

# Let's plot the frequency distribution of isograms

tmp.old.par <- par()

layout(matrix(c(1,1,1, 5,2,3, 5,2,3, 5,4,4), 4, 3, byrow=TRUE), heights=c(0.15, 0.375, 0.375, 0.1), widths=c(0.05, 0.475, 0.475))
par(mar=c(0,0,4,0))
plot.new()
title(main="ECDF and Histogram of Normalised Isogram Token Frequencies", cex.main=2)

par(mar=c(tmp.old.par$mar[1]/2, tmp.old.par$mar[2], 0, tmp.old.par$mar[4])) #mar=c(bottom, left, top, right)
plot(ecdf(combined$count_per_million), xlim=c(0, 25), main="", xlab="", ylab="", col="blue")
hist(combined$count_per_million, freq=F, xlim=c(0, 25), ylim=c(0, 1), xlab="", col="blue", breaks=as.integer(max(combined$count_per_million)/2), add=TRUE)

legend(x=10, y=0.2, c("Combined compacted"), col=c("blue"), lwd=c(2), cex=1.1)

plot(ecdf(intersected$count_per_million), xlim=c(0, 25), main="", xlab="", ylab="", col="red", pch="1")
hist(intersected$count_per_million, freq=F, xlim=c(0, 25), ylim=c(0, 1), xlab="", col="red", breaks=as.integer(max(intersected$count_per_million)/2), add=TRUE)

legend(x=15, y=0.2, c("Intersected"), col=c("red"), lwd=c(2), cex=1.1)

par(mar=c(0,0,0,0))
plot.new()
text(x=0.5, y=0.85, labels="Frequency per million", cex=1.5)

par(mar=c(0,0,0,0))
plot.new()
text(x=0.7, y=0.6, labels="ecdf and Density", cex=1.5, srt=90)

par(tmp.old.par)
rm(tmp.old.par)


# Summary statistics for normalised token frequency distribution
cat(
  sprintf(
    paste0(
      "SUMMARY OF NORMALISED TOKEN FREQUENCIES OF ISOGRAMS\n",
      "             MIN     MAX         MEDIAN      MEAN    SD\n",
      "  In Ngrams: %.4f  %.2f    %.4f      %.2f    %.2f\n",
      "  In BNC:    %.4f  %.2f    %.4f      %.2f    %.2f\n",
      "  Combined:  %.4f  %.2f    %.4f      %.2f    %.2f\n",
      "  Intersect: %.4f  %.2f    %.4f      %.2f    %.2f\n\n"
    ),
    min(ngrams$count_per_million),      max(ngrams$count_per_million),      median(ngrams$count_per_million),      mean(ngrams$count_per_million),      sd(ngrams$count_per_million),
    min(bnc$count_per_million),         max(bnc$count_per_million),         median(bnc$count_per_million),         mean(bnc$count_per_million),         sd(bnc$count_per_million),
    min(combined$count_per_million),    max(combined$count_per_million),    median(combined$count_per_million),    mean(combined$count_per_million),    sd(combined$count_per_million),
    min(intersected$count_per_million), max(intersected$count_per_million), median(intersected$count_per_million), mean(intersected$count_per_million), sd(intersected$count_per_million)
  )
)



##
## RELATIONSHIP BETWEEN TOKEN FREQUENCY AND LENGTH AND ISOGRAMY
##

# Let's get some summary data for the distribution of freqyebct grouped by length
combined.frequency.by.length      = dbGetQuery(db.h, "SELECT length, AVG(count_per_million) AS average_cpm   FROM combined_compacted GROUP BY length")
intersected.frequency.by.length   = dbGetQuery(db.h, "SELECT length, AVG(count_per_million) AS average_cpm   FROM intersected        GROUP BY length")
combined.frequency.by.isogramy    = dbGetQuery(db.h, "SELECT isogramy, AVG(count_per_million) AS average_cpm FROM combined_compacted GROUP BY isogramy")
intersected.frequency.by.isogramy = dbGetQuery(db.h, "SELECT isogramy, AVG(count_per_million) AS average_cpm FROM intersected        GROUP BY isogramy")

# Let's get some summary data for the distribution of freqyebct grouped by length
combined.diversity.by.length      = dbGetQuery(db.h, "SELECT length, AVG(vol_count_as_percent) AS average_cpm   FROM combined_compacted GROUP BY length")
intersected.diversity.by.length   = dbGetQuery(db.h, "SELECT length, AVG(vol_count_as_percent) AS average_cpm   FROM intersected        GROUP BY length")
combined.diversity.by.isogramy    = dbGetQuery(db.h, "SELECT isogramy, AVG(vol_count_as_percent) AS average_cpm FROM combined_compacted GROUP BY isogramy")
intersected.diversity.by.isogramy = dbGetQuery(db.h, "SELECT isogramy, AVG(vol_count_as_percent) AS average_cpm FROM intersected        GROUP BY isogramy")

# Let's plot the relation between frequency and length and frequency and isogramy
tmp.old.par <- par()

layout(matrix(c(1,1,1, 7,2,3, 7,4,5, 7,6,6), 4, 3, byrow=TRUE), heights=c(0.15, 0.375, 0.375, 0.1), widths=c(0.05, 0.475, 0.475))
par(mar=c(0,0,4,0))
plot.new()
title(main="Normalised Token and Volume Count by Length and Order of Isogramy", cex.main=2)

par(mar=c(tmp.old.par$mar[1]/2, tmp.old.par$mar[2], 0, tmp.old.par$mar[4])) #mar=c(bottom, left, top, right)
plot(x=c(0, 25), y=c(0, max(combined.frequency.by.length$average_cpm)), type="n", xlab="", ylab="")
lines(combined.frequency.by.length,    type="o", col=adjustcolor("blue", alpha.f = 0.8), lwd=2, pch=1)
lines(intersected.frequency.by.length, type="o", col=adjustcolor("red", alpha.f = 0.8),  lwd=2, pch=4, lty=2)

legend(x=12, y=700, c("Combined compacted", "Intersected"), col=c("blue", "red"), lwd=c(2, 2), pch=c(1, 4), lty=c(1, 2), cex=1.1)

plot(x=c(0, 10), y=c(0, max(intersected.frequency.by.isogramy$average_cpm)), type="n", xlab="", ylab="")
lines(combined.frequency.by.isogramy,    type="o", col=adjustcolor("blue", alpha.f = 0.8), lwd=2, pch=1)
lines(intersected.frequency.by.isogramy, type="o", col=adjustcolor("red", alpha.f = 0.8),  lwd=2, pch=4)

legend(x=4.8, y=3.4, c("Combined compacted", "Intersected"), col=c("blue", "red"), lwd=c(2, 2), pch=c(1, 4), cex=1.1)

plot(x=c(0, 25), y=c(0, max(combined.diversity.by.length$average_cpm)), type="n", xlab="", ylab="")
lines(combined.diversity.by.length,    type="o", col=adjustcolor("blue", alpha.f = 0.8), lwd=2, pch=1)
lines(intersected.diversity.by.length, type="o", col=adjustcolor("red", alpha.f = 0.8),  lwd=2, pch=4, lty=2)

legend(x=12, y=100, c("Combined compacted", "Intersected"), col=c("blue", "red"), lwd=c(2, 2), pch=c(1, 4), lty=c(1, 2), cex=1.1)

plot(x=c(0, 10), y=c(0, max(intersected.diversity.by.isogramy$average_cpm)), type="n", xlab="", ylab="")
lines(combined.diversity.by.isogramy,    type="o", col=adjustcolor("blue", alpha.f = 0.8), lwd=2, pch=1)
lines(intersected.diversity.by.isogramy, type="o", col=adjustcolor("red", alpha.f = 0.8),  lwd=2, pch=4)

legend(x=4.8, y=1.95, c("Combined compacted", "Intersected"), col=c("blue", "red"), lwd=c(2, 2), pch=c(1, 4), cex=1.1)

par(mar=c(0,0,0,0))
plot.new()
text(x=0.25, y=0.85, labels="Length", cex=1.5)
text(x=0.8, y=0.85, labels="Order of Isogramy", cex=1.5)

par(mar=c(0,0,0,0))
plot.new()
text(x=0.7, y=0.35, labels="Vol Count per 100", cex=1.5, srt=90)
text(x=0.7, y=0.85, labels="Token Count per 1m", cex=1.5, srt=90)

par(tmp.old.par)
rm(tmp.old.par)

# Test the correlation between order of isogramy and length
#hist(intersected$length)
#hist(intersected$isogramy)
#lm(formula=intersected$length~intersected$isogramy)
#plot(intersected$length, intersected$isogramy)
#abline(lm(formula=intersected$length~intersected$isogramy))
tmp.cor <- cor.test(intersected$isogramy, intersected$length, method = "spearman", exact=FALSE)
cat("CORRELATION BETWEEN ISOGRAMY AND LENGTH\n  (Tie-corrected Spearman's Correlation)\n"); tmp.cor; cat("\n")



##
## COUNT PALINDROMES AND TAUTONYMS
##

cat(
  sprintf(
    paste0(
      "ISOGRMS WHICH ARE ALSO TAUTONYMS, PALINDROMES OR BOTH\n",
      "           Isograms   Tautonyms   Palindromes   Both\n",
      "  Ngrams:  %i    %i        %i          %i\n",
      "  BNC:     %i     %i         %i           %i\n\n"
    ),
    dim(ngrams)[1], dim(ngrams[ngrams$is_tautonym==1,])[1], dim(ngrams[ngrams$is_palindrome==1,])[1], dim(ngrams[ngrams$is_tautonym==1 & ngrams$is_palindrome==1,])[1],
    dim(bnc)[1],    dim(bnc[bnc$is_tautonym==1,])[1],       dim(bnc[bnc$is_palindrome==1,])[1],       dim(bnc[bnc$is_tautonym==1 & bnc$is_palindrome==1,])[1]
  )
)

cat(
  sprintf(
    paste0(
      "2-ISOGRMS WHICH ARE ALSO TAUTONYMS, PALINDROMES OR BOTH\n",
      "           Isograms   Tautonyms   Palindromes   Both\n",
      "  Ngrams:  %i       %i        %i           %i\n",
      "  BNC:     %i        %i         %i           %i\n\n"
    ),
    dim(ngrams[ngrams$isogramy==2,])[1], dim(ngrams[ngrams$isogramy==2 & ngrams$is_tautonym==1,])[1], dim(ngrams[ngrams$isogramy==2 & ngrams$is_palindrome==1,])[1], dim(ngrams[ngrams$isogramy==2 & ngrams$is_tautonym==1 & ngrams$is_palindrome==1,])[1],
    dim(bnc[bnc$isogramy==2,])[1],       dim(bnc[bnc$isogramy==2 & bnc$is_tautonym==1,])[1],          dim(bnc[bnc$isogramy==2 & bnc$is_palindrome==1,])[1],          dim(bnc[bnc$isogramy==2 & bnc$is_tautonym==1 & bnc$is_palindrome==1,])[1]
  )
)

cat(
  sprintf(
    paste0(
      "3 or higher-ISOGRMS WHICH ARE ALSO TAUTONYMS, PALINDROMES OR BOTH\n",
      "           Isograms   Tautonyms   Palindromes   Both\n",
      "  Ngrams:  %i       %i        %i           %i\n",
      "  BNC:     %i        %i         %i           %i\n\n"
    ),
    dim(ngrams[ngrams$isogramy>3,])[1], dim(ngrams[ngrams$isogramy>3 & ngrams$is_tautonym==1,])[1], dim(ngrams[ngrams$isogramy>3 & ngrams$is_palindrome==1,])[1], dim(ngrams[ngrams$isogramy>3 & ngrams$is_tautonym==1 & ngrams$is_palindrome==1,])[1],
    dim(bnc[bnc$isogramy>3,])[1],       dim(bnc[bnc$isogramy>3 & bnc$is_tautonym==1,])[1],          dim(bnc[bnc$isogramy>3 & bnc$is_palindrome==1,])[1],          dim(bnc[bnc$isogramy>3 & bnc$is_tautonym==1 & bnc$is_palindrome==1,])[1]
  )
)

cat(
  sprintf(
    paste0(
      "TOTAL NUMBER OF TAUTONYMS AND PALINDROMES\n",
      "           Isograms   Tautonyms   Palindromes\n",
      "  Ngrams:  %i    %i       %i\n",
      "  BNC:     %i   %i        %i\n\n"
    ),
    ngrams.totals$total_isograms, ngrams.totals$total_tautonyms, ngrams.totals$total_palindromes,
    bnc.totals$total_isograms, bnc.totals$total_tautonyms,    bnc.totals$total_palindromes
  )
)



###
### END OF SCRIPT
###

# Close Database connection
dbDisconnect(db.h)