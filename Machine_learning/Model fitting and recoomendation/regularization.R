library(dslabs)
library(tidyverse)
library(caret)
data("movielens")
set.seed(755)
test_index <- createDataPartition(y = movielens$rating, times = 1,
                                  p = 0.2, list = FALSE)
train_set <- movielens[-test_index,]
test_set <- movielens[test_index,]
test_set <- test_set %>% 
  semi_join(train_set, by = "movieId") %>%
  semi_join(train_set, by = "userId")
RMSE <- function(true_ratings, predicted_ratings){
  sqrt(mean((true_ratings - predicted_ratings)^2))
}
mu_hat <- mean(train_set$rating)
naive_rmse <- RMSE(test_set$rating, mu_hat)
rmse_results <- data_frame(method = "Just the average", RMSE = naive_rmse)
mu <- mean(train_set$rating) 
movie_avgs <- train_set %>% 
  group_by(movieId) %>% 
  summarize(b_i = mean(rating - mu))
predicted_ratings <- mu + test_set %>% 
  left_join(movie_avgs, by='movieId') %>%
  .$b_i
model_1_rmse <- RMSE(predicted_ratings, test_set$rating)
rmse_results <- bind_rows(rmse_results,
                          data_frame(method="Movie Effect Model",
                                     RMSE = model_1_rmse ))
user_avgs <- test_set %>% 
  left_join(movie_avgs, by='movieId') %>%
  group_by(userId) %>%
  summarize(b_u = mean(rating - mu - b_i))
predicted_ratings <- test_set %>% 
  left_join(movie_avgs, by='movieId') %>%
  >     left_join(user_avgs, by='userId') %>%
  mutate(pred = mu + b_i + b_u) %>%
  .$pred
model_2_rmse <- RMSE(predicted_ratings, test_set$rating)
rmse_results <- bind_rows(rmse_results,
                          data_frame(method="Movie + User Effects Model",  
                                     RMSE = model_2_rmse ))

test_set %>% 
  left_join(movie_avgs, by='movieId') %>%
  mutate(residual = rating - (mu + b_i)) %>%
  arrange(desc(abs(residual))) %>% 
  select(title,  residual) %>% slice(1:10) %>% knitr::kable()

movie_titles <- movielens %>% 
  select(movieId, title) %>%
  distinct()
movie_avgs %>% left_join(movie_titles, by="movieId") %>%
  arrange(desc(b_i)) %>% 
  select(title, b_i) %>% 
  slice(1:10) %>%  
  knitr::kable()

movie_avgs %>% left_join(movie_titles, by="movieId") %>%
  arrange(b_i) %>% 
  select(title, b_i) %>% 
  slice(1:10) %>%  
  knitr::kable()

train_set %>% dplyr::count(movieId) %>% 
  left_join(movie_avgs) %>%
  left_join(movie_titles, by="movieId") %>%
  arrange(desc(b_i)) %>% 
  select(title, b_i, n) %>% 
  slice(1:10) %>% 
  knitr::kable()

train_set %>% dplyr::count(movieId) %>% 
  left_join(movie_avgs) %>%
  left_join(movie_titles, by="movieId") %>%
  arrange(b_i) %>% 
  select(title, b_i, n) %>% 
  slice(1:10) %>% 
  knitr::kable()
lambda <- 3
mu <- mean(train_set$rating)
movie_reg_avgs <- train_set %>% 
  group_by(movieId) %>% 
  summarize(b_i = sum(rating - mu)/(n()+lambda), n_i = n()) 

data_frame(original = movie_avgs$b_i, 
           regularlized = movie_reg_avgs$b_i, 
           n = movie_reg_avgs$n_i) %>%
  ggplot(aes(original, regularlized, size=sqrt(n))) + 
  geom_point(shape=1, alpha=0.5)

train_set %>%
  dplyr::count(movieId) %>% 
  left_join(movie_reg_avgs) %>%
  left_join(movie_titles, by="movieId") %>%
  arrange(desc(b_i)) %>% 
  select(title, b_i, n) %>% 
  slice(1:10) %>% 
  knitr::kable()

train_set %>%
  dplyr::count(movieId) %>% 
  left_join(movie_reg_avgs) %>%
  left_join(movie_titles, by="movieId") %>%
  arrange(b_i) %>% 
  select(title, b_i, n) %>% 
  slice(1:10) %>% 
  knitr::kable()

predicted_ratings <- test_set %>% 
  left_join(movie_reg_avgs, by='movieId') %>%
  mutate(pred = mu + b_i) %>%
  .$pred

model_3_rmse <- RMSE(predicted_ratings, test_set$rating)
rmse_results <- bind_rows(rmse_results,
                          data_frame(method="Regularized Movie Effect Model",  
                                     RMSE = model_3_rmse ))
rmse_results %>% knitr::kable()

lambdas <- seq(0, 10, 0.25)
mu <- mean(train_set$rating)
just_the_sum <- train_set %>% 
  group_by(movieId) %>% 
  summarize(s = sum(rating - mu), n_i = n())
rmses <- sapply(lambdas, function(l){
  predicted_ratings <- test_set %>% 
    left_join(just_the_sum, by='movieId') %>% 
    mutate(b_i = s/(n_i+l)) %>%
    mutate(pred = mu + b_i) %>%
    .$pred
  return(RMSE(predicted_ratings, test_set$rating))
})
qplot(lambdas, rmses)  
lambdas[which.min(rmses)]

lambdas <- seq(0, 10, 0.25)
rmses <- sapply(lambdas, function(l){
  mu <- mean(train_set$rating)
  b_i <- train_set %>%
    group_by(movieId) %>%
    summarize(b_i = sum(rating - mu)/(n()+l))
  b_u <- train_set %>% 
    left_join(b_i, by="movieId") %>%
    group_by(userId) %>%
    summarize(b_u = sum(rating - b_i - mu)/(n()+l))
  predicted_ratings <- 
    test_set %>% 
    left_join(b_i, by = "movieId") %>%
    left_join(b_u, by = "userId") %>%
    mutate(pred = mu + b_i + b_u) %>%
    .$pred
  return(RMSE(predicted_ratings, test_set$rating))
})

qplot(lambdas, rmses)  

lambda <- lambdas[which.min(rmses)]
lambda

rmse_results <- bind_rows(rmse_results,
                          data_frame(method="Regularized Movie + User Effect Model",  
                                     RMSE = min(rmses)))
rmse_results %>% knitr::kable()

#COMPREHENSION CHECK
options(digits = 7)
set.seed(1986, sample.kind = "Rounding")
n <- round(2^rnorm(1000, 8, 1))
n

set.seed(1, sample.kind = "Rounding")
mu <- round(80 + 2*rt(1000, 5))
range(mu)
?rt
schools <- data.frame(id = paste("PS",1:1000),
                      size = n,
                      quality = mu,
                      rank = rank(-mu))
schools

schools %>% top_n(10, quality) %>% arrange(desc(quality))

# now with fictive test scores
set.seed(1, sample.kind = "Rounding")
mu <- round(80 + 2*rt(1000, 5))

scores <- sapply(1:nrow(schools), function(i){
  scores <- rnorm(schools$size[i], schools$quality[i], 30)
  scores
})

schools <- schools %>% mutate(score = sapply(scores, mean))

# top schools based on the average score
schools %>% select(id, size, score) %>%
  top_n(10, score) %>%
  arrange(desc(score))

# median school size compared to median school size top 10 schools
schools %>% 
  summarize(median = median(size))

schools %>% select(id, size, score) %>%
  top_n(-10, score) %>%
  arrange(desc(score)) %>%
  summarize(median = median(size))

?top_n

#plot average score versus school size
Top_schools <- schools %>% select(id, size, quality, score) %>%
  top_n(10, quality) %>%
  arrange(desc(quality))


schools %>% select(id, size, score, quality) %>%
  ggplot(aes(x = size, y = score)) +
  geom_point() +
  geom_point(data = Top_schools, aes(x = size, y = score), color='red')
  
# use regularization to �icl the best schools
overall <- mean(sapply(scores, mean))
overall
alpha = 25
score_reg<-sapply(1:nrow(schools), function(i){ 
  score<-sapply(scores[i], mean) 
  overall + (sum(score-overall)/(schools$size[i] + alpha)) 
  })

schools %>% select(id, size, score, quality) %>%
  mutate(adj_score = score_reg) %>%
  top_n(10, adj_score) %>%
  arrange(desc(adj_score))

schools %>% select(id, size, score, quality) %>%
  mutate(adj_score = overall + ((score - overall)*size)/(alpha+size)) %>%
  top_n(10, adj_score) %>%
  arrange(desc(adj_score))

# alpha which minimizes RMSE
alphas <- seq(10, 250, 1)

RMSE <- function(quality, estimate){
  sqrt(mean((quality - estimate)^2))
}

rmses <- sapply(alphas, function(l){
  estimate <- overall + ((schools$score - overall)*schools$size)/(l+schools$size)
  return(RMSE(estimate, schools$quality))
})

qplot(alphas, rmses)
alphas[which.min(rmses)]

alphas <- seq(10,250)
rmse <- sapply(alphas, function(alpha){
  score_reg <- sapply(scores, function(x) overall+sum(x-overall)/(length(x)+alpha))
  sqrt(mean((score_reg - schools$quality)^2))
})
plot(alphas, rmse)
alphas[which.min(rmse)]

# now rank the schools using the best alpha
alpha <- 135
schools %>% select(id, size, score, quality) %>%
  mutate(adj_score = overall + ((score - overall)*size)/(alpha+size)) %>%
  top_n(10, adj_score) %>%
  arrange(desc(adj_score))

# commom mistake is to use regularization for values that are not centred around 0
# therefore now determine alpha without removing the average score
alphas <- seq(10, 250, 1)

RMSE <- function(quality, estimate){
  sqrt(mean((quality - estimate)^2))
}

rmses <- sapply(alphas, function(l){
  estimate <- ((schools$score)*schools$size)/(l+schools$size)
  return(RMSE(estimate, schools$quality))
})

qplot(alphas, rmses)
alphas[which.min(rmses)]
