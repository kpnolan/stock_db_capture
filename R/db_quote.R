require(RMySQL)
require(tseries)


get.db.quote <-
function (instrument, start, end, quote = c("Open", "High", "Low", "Close"),
          method = NULL, origin = "1899-12-30",
          retclass = c("zoo", "its", "ts"), quiet = FALSE, drop = FALSE)
{
  if (missing(start))
    start <- "2000-01-02"
  if (missing(end))
    end <- format(Sys.Date() - 1, "%Y-%m-%d")
  retclass <- match.arg(retclass)
  start <- as.Date(start)
  end <- as.Date(end)
  con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
  sql <- paste("select date, open as Open, high as High, low as Low, close as Close from daily_bars left outer join tickers ",
    " on tickers.id = ticker_id where symbol = '", instrument, "' and date between '", start, "' and '", end, "' order by date desc", sep="")
  res = dbSendQuery(con, sql)
  x = fetch(res, n = -1)
  dbDisconnect(con)

  names(x) <- gsub("\\.", "", names(x))
  nser <- pmatch(quote, names(x)[-1]) + 1
  n <- nrow(x)
  dat <- as.Date(as.character(x[, 1]), "%Y-%m-%d")
  if (!quiet && dat[n] != start)
    cat(format(dat[n], "time series starts %Y-%m-%d\n"))
  if (!quiet && dat[1] != end)
    cat(format(dat[1], "time series ends   %Y-%m-%d\n"))
  if (retclass == "ts") {
    jdat <- unclass(julian(dat, origin = as.Date(origin)))
    ind <- jdat - jdat[n] + 1
    y <- matrix(NA, nrow = max(ind), ncol = length(nser))
    y[ind, ] <- as.matrix(x[, nser, drop = FALSE])
    colnames(y) <- names(x)[nser]
    y <- y[, seq_along(nser), drop = drop]
    return(ts(y, start = jdat[n], end = jdat[1]))
  }
  else {
    x <- as.matrix(x[, nser, drop = FALSE])
    rownames(x) <- NULL
    y <- zoo(x, dat)
    y <- y[, seq_along(nser), drop = drop]
    if (retclass == "its") {
      if ("package:its" %in% search() || require("its", quietly = TRUE)) {
        index(y) <- as.POSIXct(index(y))
        y <- its::as.its(y)
      }
      else {
        warning("package its could not be loaded: zoo series returned")
      }
    }
    return(y)
  }
}

get.rt.quote <-
function (instrument, date, drop=FALSE,  quote = c("Open", "High", "Low", "Close"))
{
  if (missing(date))
    date <- format(Sys.Date(), "%Y-%m-%d")
  retclass <- "ts"

  con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
  sql <- paste("select seq-88, open as Open, high as High, low as Low, close as Close from snapshots left outer join tickers ",
               " on tickers.id = ticker_id where symbol = '", instrument, "' and date(snaptime) = '", date ,"'",
               "AND seq between 89 and 479",
               " order by seq", sep="")
  res = dbSendQuery(con, sql)
  x = fetch(res, n = -1)
  if ( nrow(x) == 0 ) {
    cat("Returned data is empty. Make sure a snapshot has been taken today\n")
    return(FALSE);
  }

  dbDisconnect(con)

  nser <- pmatch(quote, names(x)[-1]) + 1
  n <- nrow(x)
  if (retclass == "ts") {
    ind <- x[,1]
    y <- matrix(NA, nrow = max(ind), ncol = length(nser))
    y[ind, ] <- as.matrix(x[, nser, drop = FALSE])
    colnames(y) <- names(x)[nser]
    y <- y[, seq_along(nser), drop = drop]
    return(ts(y, start = min(ind), end = max(ind)))
  }
  else {
    x <- as.matrix(x[, nser, drop = FALSE])
    rownames(x) <- NULL
    y <- zoo(x, dat)
    y <- y[, seq_along(nser), drop = drop]
    if (retclass == "its") {
      if ("package:its" %in% search() || require("its", quietly = TRUE)) {
        index(y) <- as.POSIXct(index(y))
        y <- its::as.its(y)
      }
      else {
        warning("package its could not be loaded: zoo series returned")
      }
    }
    return(y)
  }
}

plot.rt.snap <-
  function(symbol, date) {
  if (missing(date))
    date <- format(Sys.Date(), "%Y-%m-%d")
  frame = get.rt.quote(symbol, date)
  plot.rt.quote(frame, ylab=symbol, date=date, main=paste("Realtime 1 min bars for", symbol, "on", date))
}

plot.rt.quote <-
  function (x, xlab = "Time", ylab, col = par("col"),
            bg = par("bg"), axes = TRUE, frame.plot = axes, ann = par("ann"),
            main = NULL, lrline = FALSE, ...)
{
  if ((!is.mts(x)) || (colnames(x)[1] != "Open") || (colnames(x)[2] !=
                                    "High") || (colnames(x)[3] != "Low") || (colnames(x)[4] !=
                                                             "Close"))
    stop("x is not a open/high/low/close time series")
  xlabel <- if (!missing(x))
    deparse(substitute(x))
  else NULL
  if (missing(ylab))
    ylab <- xlabel
  time.x <- time(x)
  tseq <- timeSequence(paste(format(Sys.Date(), "%Y-%m-%d"), "09:30"), paste(format(Sys.Date(), "%Y-%m-%d"), "16:00"), by = "min")
  dt <- min(lag(time.x) - time.x)/3
  xlim <- range(time.x)
  ylim <- range(x[is.finite(x)])
  plot.new()
  plot.window(xlim, ylim, ...)
  segments(time.x, x[, "High"], time.x, x[, "Low"], col = col[1],  bg = bg)
  segments(time.x - dt, x[, "Open"], time.x, x[, "Open"], col = col[1],  bg = bg)
  segments(time.x, x[, "Close"], time.x + dt, x[, "Close"], col = col[1], bg = bg)

  if (ann)
    title(main = main, xlab = xlab, ylab = ylab, ...)

  times = lapply(tseq, function(str) { substr(str, 12, 16) } )
  n <- NROW(x)
  ticks = n/15
  lab.ind <- seq.int(1, n, 15)
  axis(1, at = time.x[lab.ind], lab = times[lab.ind], ...)
  axis(2, ...)
  if ( !is.null(lrline) ) {
    fit = lsfit(1:nrow(x), avg)
    abline(fit, col = 4)
  }

  if (frame.plot)
    box(...)
}
