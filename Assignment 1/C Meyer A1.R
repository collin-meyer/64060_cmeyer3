# I got this data set from data.gov
# City of New York: 2013-2019 English Language Arts (ELA) Test Results Charter School
# https://catalog.data.gov/dataset/2013-2019-english-language-arts-ela-test-results-charter-school

# Load the data
ela <- read.csv("D:/GoogleDrive/Studenting/2021 Spring/Machine Learning/Assignments/A1/2013-2019_English_Language_Arts__ELA__Test_Results_Charter_-_School.csv", header=TRUE)

# Preview it
head(ela, 20)

# Okay, that's a lot more columns than we need right now. Let's focus on just
# a few columns: School, Grade, Year, Number Tested, and Mean Scale Score

# We could do this:
# mydata <- ela[c("School.Name", "Grade", "Year", "Number.Tested", "Mean.Scale.Score")]
# ...but I see under "Grade" there are individual grade levels in addition to
# what is presumably a pooled average of all the school's grades via that "All 
# Grades" row. Let's remove that so we're not counting the same data twice.
# Let's remove those.
elatemp <- subset(ela,ela$Grade!="All Grades")
head(elatemp, 20)

# Okay, that looks right. Now let's prune away extraneous columns:
mydata <- elatemp[c("School.Name", "Grade", "Year", "Number.Tested", "Mean.Scale.Score")]
head(mydata, 20)

# Looks good. Don't need the previous data frames anymore. Cleanup time:
rm(ela)
rm(elatemp)

# It's great that we have longitudinal data, but let's just look at a 
# cross-section from an arbitrarily chosen year:
y2018 <- subset(mydata,mydata$Year=="2018")
head(y2018, 20)

# Looks good, but "Year" (column 3) is redundant now...
y2018 <- y2018[-c(3)]
head(y2018, 20)

# Might there be a relationship between mean scores and the number tested?

# R wants to read Mean.Scale.Score as a char variable, so let's be specific:
summary(as.integer(y2018$Mean.Scale.Score))
summary(as.integer(y2018$Number.Tested))

# Typing out the full variable names each time will cause me physical pain, so:
x <- as.integer(y2018$Mean.Scale.Score)
y <- as.integer(y2018$Number.Tested)

hist(x, main = "Grades: Histogram of Scores", xlab = "Mean Scale Score")
hist(y, main = "Grades: Histogram of Numbers Tested", xlab = "Number Tested")

table(x)
table(y)

plot(x,y,main="Grades: Testing Volume vs. Mean Score", xlab="Mean Score", 
     ylab="Number Tested", xlim=c(580,630), ylim=c(10,210))
abline(lm(y ~ x), col="blue")
rm(x)
rm(y)

# Stick a fork in it--that hypothesis is dead. But maybe there are different 
# relationships by grade level?
table(y2018$Grade)
# We have six consecutive grade levels (3-8) so let's iterate through them:
for (i in 3:8) {
  tempdata <- subset(y2018,y2018$Grade==i)
  x <- as.integer(tempdata$Mean.Scale.Score)
  y <- as.integer(tempdata$Number.Tested)
  label <- paste("Grades: Testing Volume vs. Mean Score, Year", i)
  
  plot(x,y,main=label, 
       xlab="Mean Score", 
       ylab="Number Tested", 
       xlim=c(580,630), ylim=c(15,210))
  abline(lm(y ~ x), col="blue")

  rm(label)  
  rm(x)
  rm(y)
  rm(tempdata)
}
rm(i)

# And we've plotted three positive correlations, followed by three negative
# correlations. That explains the flat regression line overall, but it isn't
# very exciting or informative. What if we look at school-level data?

# Let's condense our data frame down to one row per school. I'm essentially
# just recreating the All_Grades rows that I purged earlier here, but potentially
# with different precision, depending on how these schools calculated that field
# to begin with. It might be more methodologically defensible to restore the
# original data frame and extract a subset of only the "All_Grades" rows, but we
# already know I can do that, so let's manipulate existing data instead.

library(dplyr)
sorted <- y2018 %>%
  group_by(School.Name) %>%
  summarise(
    grades = n(),
    n = sum(Number.Tested),
    m_score = mean(as.numeric(Mean.Scale.Score))
  )
head(sorted, 20)

# Looking good. Let's verify:
sum(y2018$Number.Tested)
sum(sorted$n)
# Same total N, so it looks like that worked. Hooray!

# Let's return to plotting, now using this condensed data:
x <- sorted$m_score
y <- sorted$n

summary(x)
summary(y)

hist(x, main = "Schools: Histogram of Scores", xlab = "Mean Scale Score")
hist(y, main = "Schools: Histogram of Numbers Tested", xlab = "Number Tested")

plot(x,y,main="Schools: Testing Volume vs. Mean Score", xlab="Mean Score", 
     ylab="Number Tested", xlim=c(580,630), ylim=c(30,715))
abline(lm(y ~ x), col="red")
rm(x)
rm(y)

# Now we're looking at the relationship between scores and number tested within
# schools, instead of within grade levels. This seems more reasonable.

#And that's it! Clean up our workspace, I guess.
rm(mydata)
rm(sorted)
rm(y2018)