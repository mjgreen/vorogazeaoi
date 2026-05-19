library(markdown)
library(lorem)

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}