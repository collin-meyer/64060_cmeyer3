# Homework 5: Hierarchical Clustering
library(class)
library(cluster)
library(dplyr)
library(caret)
Cereals <- read.csv("D:/GoogleDrive/Studenting/2021 Spring/Machine Learning/Assignments/A5 Hierarchical Clustering/Cereals.csv"
                    , header=TRUE, row.names=1)

#Data Preprocessing. Remove all cereals with missing values. 
table(complete.cases(Cereals))
#Three rows have one or more missing values.
cdata <- Cereals[complete.cases(Cereals),]
table(complete.cases(cdata))
#...and those three are now gone! Remaining cereals: 74.

#Apply hierarchical clustering to the data using Euclidean distance to the 
#normalized measurements. Use Agnes to compare the clustering from 
#single linkage, complete linkage, average linkage, and Ward. 
#Choose the best method. 
normed<-cdata
normed[3:15] <- sapply(cdata[,3:15], scale)
dist.normed <- dist(normed[,c(3:15)], method = "euclidean")

set.seed(555) # Keeping with the seeding tradition!
#AGNES
hc_single <- agnes(normed[,3:15], method="single")
hc_complete  <- agnes(normed[,3:15], method="complete")
hc_average  <- agnes(normed[,3:15], method="average")
hc_ward  <- agnes(normed[,3:15], method="ward")
#Print agglomerative coefficients:
print(hc_single$ac)
print(hc_complete$ac)
print(hc_average$ac)
print(hc_ward$ac)
# The best linkage method here was the Ward distance.

#How many clusters would you choose? 
pltree(hc_ward, cex = 0.6, hang = -1, main = "Agnes Clusters, Ward Distance, k=5")
rect.hclust(hc_ward, k=5, border = 1:4)
pltree(hc_ward, cex = 0.6, hang = -1, main = "Agnes Clusters, Ward Distance, k=6")
rect.hclust(hc_ward, k=6, border = 1:4)
pltree(hc_ward, cex = 0.6, hang = -1, main = "Agnes Clusters, Ward Distance, k=7")
rect.hclust(hc_ward, k=7, border = 1:4)
pltree(hc_ward, cex = 0.6, hang = -1, main = "Agnes Clusters, Ward Distance, k=8")
rect.hclust(hc_ward, k=8, border = 1:4)
# k=5 has too large clusters for adequate distinction, and because k=8 is
# splitting off such a small group, 8 is too many. The ideal appears to be k=7, 
# as this gives a range of groups, but no group is disproportionately large
# compared to the others. We have one very small cluster, but that was present 
# in all permutations above.

clust_ID <- cutree(hc_ward, k=7)
clustered <- cbind(clust_ID,normed)

heatmap(as.matrix(clustered[4:16]), Colv = NA, hclustfun = hclust, 
        col=rev(paste("gray",1:99,sep="")))
aggregate(clustered[,c(4:16)], list(clustered$clust_ID), mean)
# We can see concentrations of higher and lower sugar in multiple clusters, but
# it looks like vitamins are considerably more homogeneous. High "rating" scores
# are also clustered together at the bottom of the heatmap. Other cluster-based
# patterns are visible in calories, protein, sodium, carbohydrates, potassium, 
# and weight. This is a good sign that our clusters have meaningful differences.

#Comment on the structure of the clusters and on their stability.
#Hint: To check stability, partition the data and see how well clusters formed
#based on one part apply to the other part. To do this: 

#(1) Cluster partition A 

set.seed(555) # Keeping with the seeding tradition!
train.rows <- sample(rownames(cdata), dim(cdata)[1]*.5) #50-50 split
train.data <- cdata[train.rows, ]
valid.rows <- setdiff(rownames(cdata), train.rows)
valid.data <- cdata[valid.rows, ]

norm.values <- preProcess(train.data[, c(3:15)], method=c("center", "scale"))
train.norm <- train.data
train.norm[, c(3:15)] <- predict(norm.values, train.data[, c(3:15)])
valid.norm <- valid.data
valid.norm[, c(3:15)] <- predict(norm.values, valid.data[, c(3:15)])

hc_single <- agnes(train.norm, method="single")
hc_complete  <- agnes(train.norm, method="complete")
hc_average  <- agnes(train.norm, method="average")
hc_ward  <- agnes(train.norm, method="ward")

#Validating the previous agglomerative coefficient conclusion:
print(hc_single$ac)
print(hc_complete$ac)
print(hc_average$ac)
print(hc_ward$ac)
#Ward is still superior.
pltree(hc_ward, cex = 0.6, hang = -1, main = "Partition A Clusters")
rect.hclust(hc_ward, k=7, border = 1:4)
clust_ID <- cutree(hc_ward, k=7)
train.clust <- cbind(clust_ID,train.norm)

train_centroids <- aggregate(train.clust[,c(4:16)], list(train.clust$clust_ID), mean)

#(2) Use the cluster centroids from A to assign each record in partition B (each 
#record is assigned to the cluster with the closest centroid). 

nn <- as.data.frame(knn(train=train_centroids[, 2:14], test=valid.norm[,3:15], cl=train_centroids[, 1], k=1))
colnames(nn) <- "clust_ID"
valid.clust <- cbind(nn,valid.norm)

#(3) Assess how consistent the cluster assignments are compared to the 
#assignments based on all the data.

merged <- rbind(train.clust, valid.clust)

cross_comp <- cbind(clustered[1],merged[1])
cross_comp$same_c <- (cross_comp[1]==cross_comp[2])
colnames(cross_comp)[1] <- "orig_clust_ID"
colnames(cross_comp)[2] <- "valid_clust_ID"
#How many items are still in the same clusters?
(cross_sort <- cross_comp[order(cross_comp$orig_clust_ID) , ])
table(cross_sort$same_c)
# Only 15 of the cereals were placed into the same cluster number when using
# the cross-validation approach. This is a very low percentage, but the number
# itself is not necessarily important. It is theoretically possible for the same
# items to be clustered together but into a different cluster number. Therefore,
# it is important to review the patterns of difference. If the two cluster
# schemes produced identical groupings but different numbers, then we would
# expect to see groupings of the original cluster ID (column one) alongside 
# consistent (even if different) numbers in the cross-validation clusters 
# (column two). Instead, what we see is that although this pattern does exist
# for some items, most have been redistributed across multiple new clusters. 
# This instability confirms that hierarchical clustering is sensitive to changes
# in the data set.

#The elementary public schools would like to choose a set of
#cereals to include in their daily cafeterias. Every day a different cereal is 
#offered, but all cereals should support a healthy diet. For this goal, you are 
#requested to find a cluster of "healthy cereals." Should the data be 
#normalized? If not, how should they be used in the cluster analysis?

# First, yes, the data should still be normalized. This helps to ensure that
# differences in scale are not biasing the model. Principal components could
# be extracted, but this would still be normalizing the data.

# Second, since the school wants a different healthy cereal every day, our
# proposal needs to have at least five different members. Does our previous
# k=7 approach still work here?

set.seed(555) # Keeping with the seeding tradition!
hc_ward  <- agnes(normed[,3:15], method="ward")

pltree(hc_ward, cex = 0.6, hang = -1, main = "Cereal Clusters")
rect.hclust(hc_ward, k=7, border = 1:4)
clust_ID <- cutree(hc_ward, k=7)

clustered <- cbind(clust_ID,normed)
aggregate(clustered[,c(4:16)], list(clustered$clust_ID), mean)
# As before, we can see clear relative differences between clusters, but normed
# data can be very tricky to interpret. Thus, let's keep the same cluster data
# but reexamine these centroids using the pre-normed numbers:
clust_denormed <- cbind(clust_ID, cdata)
aggregate(clust_denormed[,c(5:16)], list(clust_denormed$clust_ID), mean)

# Based on their lower sugar totals, Clusters 1, 5, 6, and 7 are all potential
# candidates for "healthy cereals." Of these, the strongest groups are #1,
# which is high in fiber, and #7, which is high in vitamins. However, neither of
# these clusters alone is sufficient to meet the school's needs:
table(clustered$clust_ID)
# That is, neither group 1 nor 7 alone is big enough to allow a daily rotation 
# with no repetitions. Therefore, it would be suitable to combine these into a
# single cluster so that there are seven options that can be cycled through.
# If additional options are desired, they can be selected from group 5 or 6 as
# needed based on specific nutritional goals.