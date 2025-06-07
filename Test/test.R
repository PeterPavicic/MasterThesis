# chooseCRANmirror("cran.wu.ac.at")
install.packages("python")


prices  <- c(
    "SimionBig" = 0.16,
    "SimionSmall" = 0.22,
    "DanSmall" = 0.32,
    "DanBig" = 0.14
)

returns <- 1 / prices

returns

matrix(1:12, nrow = 3)
