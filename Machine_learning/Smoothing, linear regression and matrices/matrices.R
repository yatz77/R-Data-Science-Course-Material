library(tidyverse)
library(dslabs)
if(!exists("mnist")) mnist <- read_mnist()

class(mnist$train$images)

x <- mnist$train$images[1:1000,]
y <- mnist$train$labels[1:1000]

length(x[,1])
x_1 <- 1:5
x_2 <- 6:10
cbind(x_1, x_2)
dim(x)
dim(x_1)
dim(as.matrix(x_1))
dim(x)

my_vector <- 1:15

# fill the matrix by column
mat <- matrix(my_vector, 5, 3)
mat

# fill by row
mat_t <- matrix(my_vector, 3, 5, byrow = T)
mat_t
identical(t(mat), mat_t)
matrix(my_vector, 5, 5)
grid <- matrix(x[3,], 28, 28)
image(1:28, 1:28, grid)

#flip the image back 
image(1:28, 1:28, grid[, 28:1])

sums <- rowSums(x)
avg <- rowMeans(x)
sums
avg

data_frame(labels = as.factor(y), row_averages = avg) %>%
  qplot(labels, row_averages, data = ., geom = "boxplot")

avgs <- apply(x, 2, mean)
sds <- apply(x, 2, sd)
avgs
sds

install.packages("matrixStats")
library(matrixStats)

sds <- colSds(x)
qplot(sds, bins = "30", color = I("black"))
image(1:28, 1:28, matrix(sds, 28, 28)[, 28:1])

#extract columns and rows
x[ ,c(351,352)]
x[c(2,3),]
new_x <- x[ ,colSds(x)>60]
dim(new_x)
class(x[,1])
dim(x[1,])

# preserve the matrix class
class(x[ , 1, drop=F])
dim(x[, 1, drop=F])

mat <- matrix(1:15, 5, 3)
as.vector(mat)
qplot(as.vector(x), bins = 30, color = I("black"))
new_x <- x
new_x[new_x < 50] <- 0

mat <- matrix(1:15, 5, 3)
mat[mat < 3] <- 0
mat

mat <- matrix(1:15, 5, 3)
mat[mat > 6 & mat < 12] <- 0
mat

# binarize the data
bin_x <- x
bin_x[bin_x < 255/2] <- 0
bin_x[bin_x > 255/2] <- 1
bin_X <- (x > 255/2)*1
bin_X

#scale each row of a matrix
(x - rowMeans(x)) / rowSds(x)

#scale each column
t(t(x) - colMeans(x))

#take eaxh entry of a vector and subtracts it from the corresponding row or column
x_mean_0 <- sweep(x, 2, colMeans(x))

# divide by the standard deviation
x_mean_0 <- sweep(x, 2, colMeans(x))

# divide by the standard deviation
x_mean_0 <- sweep(x, 2, colMeans(x))
x_standardized <- sweep(x_mean_0, 2, colSds(x), FUN = "/")

#COMPREHEMSION CHECK
x <- matrix(rnorm(100*10), 100, 10)
dim(x)
dim(x[1,])
seq(nrow(x))

x <- mnist$train$images
y <- mnist$train$labels


vec_x <- as.vector(x)
mean(ifelse(vec_x > 50 & vec_x < 205, 1, 0))

mnist <- read_mnist()
x[x>50 & x<205]
qplot(as.factor(mnist$train$labels), y, geom = "boxplot")
mnist$train$images>50
