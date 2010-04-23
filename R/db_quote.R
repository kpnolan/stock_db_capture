# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require(RMySQL)
require(tseries)
require(gtools)

get.histo <-
  function(value, table='positions', scale='lin', scan='', where='')
  {
    con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
    if ( scan == '' ) {
      sql <- paste("select ", value, " from ", table, where, sep="")
    } else {
      sql <- paste("select ", value, " from positions left outer join scans on scans.id = scan_id where closed = 1 and name = '", scan ,"'", sep="")
    }
    res = dbSendQuery(con, sql)
    x = fetch(res, n = -1)

    if ( nrow(x) == 0 ) {
      cat("Returned data is empty. Check SQL\n")
      return(FALSE);
    }
    main = paste("Histogram of", value, "for scan: ", scan)
    xlab = value
    dbDisconnect(con)
    if ( scale == 'log' )
      h = logHist(x[, value], breaks=100, col="red", main=main, xlab=xlab)
    else
      h = hist(x[, value], col="red", breaks=100, main=main, xlab=xlab)
  }

get.table <-
  function(table_name)
  {
    con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
    sql <- paste("SELECT * FROM", table_name)
    res = dbSendQuery(con, sql)
    x = fetch(res, n = -1)
    dbDisconnect(con)
    x
  }

get.close <-
  function(symbol, date)
  {
    con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
    sql <- paste("SELECT bardate, close FROM daily_bars join tickers on tickers.id = ticker_id where symbol = '", symbol, "' and bardate between '", date, "' and curdate() order by bardate", sep="")
    res = dbSendQuery(con, sql)
    x = fetch(res, n = -1)
    dbDisconnect(con)
    x
  }

get.rejects <-
  function()
  {
    con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
    sql <- "select date, total, rejected, (rejected/total)*100.0 as percent from position_stats order by date"
    res = dbSendQuery(con, sql)
    x = fetch(res, n = -1)
    dbDisconnect(con)
    x
  }

draw.down <-
  function(table='sim_summaries', origin=c(2000,1))
  {
    con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
    sql <- paste("select sim_date as date, portfolio_value + cash_balance as total from", table,"order by sim_date")
    res = dbSendQuery(con, sql)
    fr = fetch(res, n = -1)
    if ( nrow(fr) == 0 ) {
      cat("Returned data is empty. Check SQL\n")
      return(FALSE);
    }
    dbDisconnect(con)
    x = ts(fr$total, start=origin, frequency=252)

    mdd = maxdrawdown(x)
    main = paste("Max Draw Down: $", format(mdd$maxdrawdown, big.mark=','), sep='')
    ylab = "Market Value + Cash"
    plot(x,main=main, ylab=ylab)
    grid()
    segments(time(x)[mdd$from]-0.25, x[mdd$from], time(x)[mdd$to]+0.25, x[mdd$from])
    segments(time(x)[mdd$from]-0.25, x[mdd$to], time(x)[mdd$to]+0.25, x[mdd$to])
    mid = time(x)[(mdd$from + mdd$to)/2]
    arrows(mid, x[mdd$from], mid, x[mdd$to], col = 2)
    mdd
  }


sim.summary.ts <-
    function(retclass = c("zoo", "its", "ts"), origin = "1899-12-30", quote=c("total"), drop = FALSE)
  {
    con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
    sql <- "select sim_date as date, portfolio_value + cash_balance as total from sim_summaries order by sim_date"
    res = dbSendQuery(con, sql)
    x = fetch(res, n = -1)
    if ( nrow(x) == 0 ) {
      cat("Returned data is empty. Check SQL\n")
      return(FALSE);
    }
    return(x)
    nser <- pmatch(quote, names(x)[-1]) + 1
    n <- nrow(x)

    main = "Simulation Timeseries"
    xlab = value
    dbDisconnect(con)

    dat <- as.Date(as.character(x[, 1]), "%Y-%m-%d")

    if (retclass == "ts") {
      jdat <- unclass(julian(dat, origin = as.Date(dat[1])))
      ind <- jdat - jdat[1] + 1
      y <- matrix(NA, nrow = max(ind), ncol = length(nser))
      y[ind, ] <- as.matrix(x[, nser, drop = FALSE])
      colnames(y) <- names(x)[nser]
      y <- y[, seq_along(nser), drop = drop]
      return(ts(y, start = jdat[1], end = jdat[n]))
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



get.rejected.ts <-
  function(retclass = c("zoo", "its", "ts"), origin = "1899-12-30", drop = FALSE)
  {
    x = get.rejects()
    if ( nrow(x) == 0 ) {
      cat("Returned data is empty. Check SQL\n")
      return(FALSE);
    }
    n <- nrow(x)
    nser = names(x)[2:3]

    dat <- as.Date(as.character(x[, 1]), "%Y-%m-%d")

    if (retclass == "ts") {
      jdat <- unclass(julian(dat, origin = as.Date(orign)))
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


get.histo2d.all <-
  function(value1, value2, limit=20.0)
  {
    con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
    sql <- paste("select ", value1,",", value2, " from positions where entry_price < ", limit, sep="")
    res = dbSendQuery(con, sql)
    x = fetch(res, n = -1)
    if ( nrow(x) == 0 ) {
      cat("Returned data is empty. Check SQL\n")
      return(FALSE);
    }
    main = paste("Histogram of", value1, "+", value2)
    xlab = value1
    ylab = value2
    dbDisconnect(con)
    h2d = hist2d(x[, value1], x[, value2], main=main, xlab=xlab, ylab=ylab)
  }

get.histo2d <-
  function(value1, value2, scan)
  {
    con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
    sql <- paste("select ", value1,",", value2, " from positions left outer join scans on scans.id = scan_id where etival < 0 and xtival > 0 and name = '", scan ,"'", sep="")
    res = dbSendQuery(con, sql)
    x = fetch(res, n = -1)
    if ( nrow(x) == 0 ) {
      cat("Returned data is empty. Check SQL\n")
      return(FALSE);
    }
    main = paste("Histogram of", value1, "+", value2, "for scan: ", scan)
    xlab = value1
    ylab = value2
    dbDisconnect(con)
    h2d = hist2d(x[, value1], x[, value2], main=main, xlab=xlab, ylab=ylab)
#    write.table(h2d, "/work/railsapps/stock_db_capture/R/h2d.tsv")
    persp( h2d$x, h2d$y, h2d$counts,
          ticktype="detailed", theta=30, phi=30,
          expand=0.5, shade=0.5, col="cyan", ltheta=-30)
#    contour( h2d$x, h2d$y, h2d$counts, nlevels=4)
#                   col=gray((4:0)/4) )
   }

get.db.slope <-
  function(pass) {
  sql <- paste("select entry_pass,",
               "sum(if(name='pslope', value, 0)) as pslope,",
               "sum(if(name='eslope', value, 0)) as eslope,",
               "sum(if(name='cslope', value, 0)) as cslope",
               "from position_stats left outer join positions on positions.id = position_id",
               "where entry_pass = ", pass, "group by position_id order by position_id")
  con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
  res = dbSendQuery(con, sql)
  x = fetch(res, n = -1)
  dbDisconnect(con)
  x
}

ps.empty <-
  function() {
    sql <- "select count(*) from position_series"
    con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
    res = dbSendQuery(con, sql)
    x = fetch(res, n = -1)
    dbDisconnect(con)
    x == 0
  }

get.position.series <-
  function(pos_id, retclass = c("zoo", "its", "ts", "xts"), indicators = c('rsi', 'rvi'),
           quiet = FALSE, drop = FALSE)  {
  sql <- paste("select date,",
                "sum(if(name='rsi', value, 0)) as rsi,",
                "sum(if(name='rvi', value, 0)) as rvi",
               "from position_series join indicators on indicators.id = indicator_id",
               "where position_id = ", pos_id, "group by date order by date desc")
  con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
  res = dbSendQuery(con, sql)
  x = fetch(res, n = -1)
  dbDisconnect(con)

  x$macd_hist = x$macd_hist * 10.0
  print(max(x$rsi))
  print(max(x$rvi))

  names(x) <- gsub("\\.", "", names(x))
  nser <- pmatch(indicators, names(x)[-1]) + 1
  n <- nrow(x)

  origin <- as.Date(as.character(x[, 1][1]), "%Y-%m-%d")

  dat <- as.Date(as.character(x[, 1]), "%Y-%m-%d")
  if (!quiet && dat[n])
    cat(format(dat[n], "time series starts %Y-%m-%d\n"))
  if (!quiet && dat[1])
    cat(format(dat[1], "time series ends   %Y-%m-%d\n"))
  if (retclass == "ts") {
    jdat <- unclass(julian(dat, origin = origin))
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
  }
  if (retclass == "xts")
    return(as.xts(y))
  if (retclass == "its") {
    if ("package:its" %in% search() || require("its", quietly = TRUE)) {
      index(y) <- as.POSIXct(index(y))
      y <- its::as.its(y)
    }  else {
      warning("package its could not be loaded: zoo series returned")
    }
  }
  return(y)
}

rvig <-
  function(series, n=5) {
    open = series[, "Open"]
    close = series[, "Close"]
    high = series[, "High"]
    low = series[, "Low"]
    val1 = (close-open + 2.0*(Lag(close,1)-Lag(open,1)) + 2.0*(Lag(close,2)-Lag(open,2)) + Lag(close, 3)-Lag(open,3))/6.0
    val2 = (high-low + 2.0*(Lag(high,1)-Lag(low,1)) + 2.0*(Lag(high,2)-Lag(low,2)) + Lag(high, 3)-Lag(low,3))/6.0
    num = SMA(val1, n)
    denom = SMA(val2, n)
    rvi = 100.0 * num/denom
    rviSig = (rvi + 2.0*Lag(rvi,1) + 2.0*Lag(rvi, 2) + Lag(rvi,3))/6.0
    pair <- cbind(rvi, rviSig)
    colnames(pair) <- c("rvig", "signal")
    return(pair)
  }

get.input.matrix <-
  function(instrument, start, end) {
    con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
    # we left out the O0 column since we are not tracking that now
    if (missing(start))
      start <- "2009-01-02"
    if (missing(end) || is.na(end))
      end <- format(Sys.Date() - 1, "%Y-%m-%d")
    start <- as.Date(start)
    end <- as.Date(end)
    cols =  c("Open", "High", "Low", "Close", "Volume", "rsi", "macd", "rvig")
    sql <- paste("select date(bartime) as date, o as Open, h as High, l as Low, c as Close, v as Volume, rsi, macd, rvig from ann_inputs left outer join tickers ",
                 " on tickers.id = ticker_id where symbol = '", instrument, "' and bartime between '", start, "' and '", end+1, "' order by bartime", sep="")
    res = dbSendQuery(con, sql)
    x = fetch(res, n = -1)
    dbDisconnect(con)
    nser <- pmatch(cols, names(x)[-1]) + 1
    y <- as.matrix(x[, nser, drop = FALSE])
  }

ann <-
  function(P)
  {
    library(AMORE)
                                        # P is the input vector
                                        # The network will try to approximate the target P^2
    target <- (P[, 4])
                                        # We create a feedforward network, with two hidden layers.
                                        # The first hidden layer has three neurons and the second has two neurons.
                                        # The hidden layers have got Tansig activation functions and the output layer is Purelin.
    net <- newff(n.neurons=c(dim(P)[2],10,4,1), learning.rate.global=1e-1, momentum.global=0.5,
                 error.criterium="LMS", Stao=NA, hidden.layer="tansig",
                 output.layer="purelin", method="ADAPTgdwm")
    result <- train(net, P, target, error.criterium="LMS", report=TRUE, show.step=10000, n.shows=100)
    y <- sim(result$net, P)
    plot(P[, "Close"],y, col="blue", pch="+")
    points(P[,"Close"], target, col="red", pch=19)
  }




get.db.quote <-
function (instrument, start, end, quote = c("Open", "High", "Low", "Close", "Volume"),
          method = NULL,
          retclass = c("df", "zoo", "its", "ts", "xts"), quiet = FALSE, drop = FALSE)
{
  if (missing(start))
    start <- "2009-01-02"
  if (missing(end) || is.na(end))
    end <- format(Sys.Date() - 1, "%Y-%m-%d")
  if (missing(retclass))
    retclass='xts'
  retclass <- match.arg(retclass)
  start <- as.Date(start)
  end <- as.Date(end)
  con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
  sql <- paste("select date(bartime) as date, opening as Open, high as High, low as Low, close as Close, volume as Volume from daily_bars left outer join tickers ",
    " on tickers.id = ticker_id where symbol = '", instrument, "' and bardate between '", start, "' and '", end, "' order by bardate", sep="")
  res = dbSendQuery(con, sql)
  x = fetch(res, n = -1)
  dbDisconnect(con)

  names(x) <- gsub("\\.", "", names(x))
  nser <- pmatch(quote, names(x)[-1]) + 1
  n <- nrow(x)

  print(paste(instrument, "-- rows:", n))

  dat <- as.Date(as.character(x[, 1]), "%Y-%m-%d")

  if (!quiet && dat[1] != start)
    cat(format(dat[1], "time series starts %Y-%m-%d\n"))
  if (!quiet && dat[n] != end)
    cat(format(dat[n], "time series ends   %Y-%m-%d\n"))
  if (retclass == "ts") {
    jdat <- unclass(julian(dat, origin=as.Date("1899-12-30")))
    ind <- jdat-jdat[1] + 1
    y <- matrix(NA, nrow = max(ind), ncol = length(nser))
    return(ts(y, start = jdat[1], end = jdat[n]))
  }
  else {
    x <- as.matrix(x[, nser, drop = FALSE])
    rownames(x) <- NULL
    y <- zoo(x, dat)
    y <- y[, seq_along(nser), drop = drop]
  }
  if (retclass == "xts")
    return(as.xts(y))
  if (retclass == "its") {
    if ("package:its" %in% search() || require("its", quietly = TRUE)) {
      index(y) <- as.POSIXct(index(y))
      y <- its::as.its(y)
    }  else {
      warning("package its could not be loaded: zoo series returned")
    }
  }
  return(y)
}

get.csv <-
function (basename, retclass = c("df", "zoo", "its", "ts", "xts"), quiet = FALSE, drop = FALSE)
{
  retclass <- match.arg(retclass)
  x = read.csv(paste("/work/tdameritrade/stock_db_capture/tmp/", basename, ".csv", sep=''))

  names(x) <- gsub("\\.", "", names(x))
  nser <-pmatch(names(x)[-1], names(x))
  n <- nrow(x)

  print(paste("Rows:", n))
  if (retclass == "df") {
    x[,1] = date = as.Date(as.character(x[, 1]), "%Y-%m-%d")
    index = unclass(julian(date, origin=date[1])) + 1
    xx = data.frame(date, index)
    return(merge(x,xx))
  }

  dat <- as.Date(as.character(x[, 1]), "%Y-%m-%d")
    cat(format(dat[1], "time series starts %Y-%m-%d\n"))
    cat(format(dat[n], "time series ends   %Y-%m-%d\n"))
  if (retclass == "ts") {
    jdat <- unclass(julian(dat, origin=as.Date("1899-12-30")))
    ind <- jdat-jdat[1] + 1
    y <- matrix(NA, nrow = max(ind), ncol = length(nser))
    y[ind, ] <- as.matrix(x[, nser, drop = FALSE])
    colnames(y) <- names(x)[nser]
    y <- y[, seq_along(nser), drop = drop]
    return(ts(y, start = jdat[1], end = jdat[n]))
  }
  else {
    x <- as.matrix(x[, nser, drop = FALSE])
    rownames(x) <- NULL
    y <- zoo(x, dat)
    y <- y[, seq_along(nser), drop = drop]
  }
  if (retclass == "xts")
    return(as.xts(y))
  if (retclass == "its") {
    if ("package:its" %in% search() || require("its", quietly = TRUE)) {
      index(y) <- as.POSIXct(index(y))
      y <- its::as.its(y)
    }  else {
      warning("package its could not be loaded: zoo series returned")
    }
  }
  return(y)
}

## quantmod:addRSI <-
## function (n = 14, maType = "EMA", wilder = TRUE)
## {
##     stopifnot("package:TTR" %in% search() || require("TTR", quietly = TRUE))
##     lchob <- quantmod:::get.current.chob()
##     x <- as.matrix(lchob@xdata)
##     print(x)
##     chobTA <- new("chobTA")
##     chobTA@new <- TRUE
##     xx <- if (is.OHLC(x)) {
##         Cl(x)
##     }
##     else x
##     rsi <- RSI(xx, n = n, maType = maType, wilder = wilder)
##     chobTA@TA.values <- rsi[lchob@xsubset]
##     chobTA@name <- "chartRSI"
##     chobTA@call <- match.call()
##     chobTA@params <- list(xrange = lchob@xrange, colors = lchob@colors,
##         color.vol = lchob@color.vol, multi.col = lchob@multi.col,
##         spacing = lchob@spacing, width = lchob@width, bp = lchob@bp,
##         x.labels = lchob@x.labels, time.scale = lchob@time.scale,
##         n = n, wilder = wilder, maType = maType)
##     if (is.null(sys.call(-1))) {
##         TA <- lchob@passed.args$TA
##         lchob@passed.args$TA <- c(TA, chobTA)
##         lchob@windows <- lchob@windows + ifelse(chobTA@new, 1,
##             0)
##         do.call("chartSeries.chob", list(lchob))
##         invisible(chobTA)
##     }
##     else {
##         return(chobTA)
##     }
## }


do.winners <- function() { do.positions("winners") }
do.losers  <- function() { do.positions("losers") }
do.non     <- function() { do.positions("non") }
do.all     <- function() { do.positions("all") }

do.positions <-
  function(type) {
    if ( type == "all" ) {
      pos = get.positions(order="order by ettime, ticker_id")
    } else if ( type == "losers" ) {
      pos = get.positions(where="where year(entry_date) = 2009 and roi < 0 and exit_date is not null", order="order by roi asc")
    } else if ( type == "winners" ) {
      pos = get.positions(where="where year(entry_date) = 2009 and roi > 0 and exit_date is not null", order="order by roi desc")
    } else if ( type == "non" ) {
      pos = get.positions(where="where year(entry_date) = 2009 and exit_date is null", order="order by roi")
    } else {
      print("invalid arg")
    }
    chart.positions(pos)
#    plot.positions(type, pos)
#    pos
  }

strategy=""

## get.positions.raw <-
##   function( origin = "1899-12-30", order="order by entry_date, symbol", where="") {
##     con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
##         sql <- paste("select symbol, date(entry_date) as edate, date(exit_date) as xdate, entry_price, exit_price, roi, days_held from positions left outer join tickers",
##                      "on tickers.id = ticker_id", where, order)
table = 'rsirvig_positions'

get.positions <-
  function(origin = "1899-12-30", quote=c("entry_price", "exit_price"), order="order by symbol, ettime", where="") {
    con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
    sql <- paste("select symbol, date(ettime) as etdate, date(entry_date) as edate, date(exit_date) as xdate, date(xttime) as xtdate, entry_price as eprice, exit_price as xprice, etprice, xtprice, etival, xtival, roi, days_held from", table, "left outer join tickers on tickers.id = ticker_id", where, order)
    res = dbSendQuery(con, sql)
    x = fetch(res, n = -1)
    if ( nrow(x) == 0 ) {
      cat("Positions table is empty")
      return(FALSE);
    }
    x
  }

printSeries <-
  function(x)
  {
    print("PRINT SERIES:")
    print(x)
    x
  }

addRvig <- newTA(rvig, data.at=1, col=c("grey", "red"))

addRvig1 <-
  function (n = 5, ..., on = NA, legend = "auto")
{
    lchob <- quantmod:::get.current.chob()
    x <- as.matrix(lchob@xdata)

    x <- Cl(x)
    print(x)
    yrange <- NULL
    chobTA <- new("chobTA")
    if (NCOL(x) == 1) {
        chobTA@TA.values <- x[lchob@xsubset]
    }
    else chobTA@TA.values <- x[lchob@xsubset, ]
    chobTA@name <- "chartTA"
    if (any(is.na(on))) {
        chobTA@new <- TRUE
    }
    else {
        chobTA@new <- FALSE
        chobTA@on <- on
    }
    chobTA@call <- match.call()
    legend.name <- gsub("^add", "", deparse(match.call()))
    gpars <- c(list(...), list(col = c("grey", "red")))[unique(names(c(list(col = c("grey",
        "red")), list(...))))]
    chobTA@params <- list(xrange = lchob@xrange, yrange = yrange,
        colors = lchob@colors, color.vol = lchob@color.vol, multi.col = lchob@multi.col,
        spacing = lchob@spacing, width = lchob@width, bp = lchob@bp,
        x.labels = lchob@x.labels, time.scale = lchob@time.scale,
        isLogical = is.logical(x), legend = legend, legend.name = legend.name,
        pars = list(gpars))
    if (is.null(sys.call(-1))) {
        TA <- lchob@passed.args$TA
        lchob@passed.args$TA <- c(TA, chobTA)
        lchob@windows <- lchob@windows + ifelse(chobTA@new, 1,
            0)
        chartSeries.chob <- quantmod:::chartSeries.chob
        do.call("chartSeries.chob", list(lchob))
        invisible(chobTA)
    }
    else {
        return(chobTA)
    }
}


chart.positions <-
  function(x)
  {
    print(paste("There are", NROW(x), "entries in this set"))

    for ( i in 1:NROW(x) )  {
      if ( is.na(x$edate[i]) )
        next

      symbol = x$symbol[i]
      edate = as.Date(x$edate[i])
      xdate = as.Date(x$xdate[i])
      etdate = as.Date(x$etdate[i])
      xtdate = as.Date(x$xtdate[i])

      etprice = x$etprice[i]
      xtprice = x$xtprice[i]
      eprice = x$eprice[i]
      xprice = x$xprice[i]

      roi = x$roi[i]
      days_held = x$days_held[i]
      etival = x$etival[i]
      xtival = x$xtival[i]

      window.start = etdate - 7
      window.end = xdate +7

      edate14 = etdate - 60
      xdate14 = xtdate + 14
      subset = paste(window.start,'/',window.end, sep='')

      q = get.db.quote(symbol, start=edate14, end=xdate14, quiet=TRUE)

      chob = chartSeries(q, TA='addVo();addRvig();addMACD()', up.col="green", dn.col="red", subset=subset)
      print(paste('Entry Trig:', etdate, 'Exit Trig:', xtdate))
      print(paste('Entry', edate, 'Exit:', xdate, "Roi:", roi ))
      print(paste('Trigger Price:', etprice, 'Entry Price:', eprice, 'Exit Price:', xprice))
      print(paste('Trigger Ival:', etival, 'Exit Ival:', xtival))
      ask()
    }
  }


plot.positions <-
  function(type, x,  origin = "1899-12-30", scale=10.0, offset=0) {
    print(paste("There are", NROW(x), "entries in this set"))
    op <- par(pty = "m", bg="white")

    if ( !ps.empty() )
      split.screen(c(2,1))

    for ( i in 1:length(syms) )  {
      if ( is.na(edates[i]) )
        next

      symbol = x$symbol[i]
      edate = as.Date(x$edate[i])
      xdate = as.Date(x$xdate[i])
      etdate = as.Date(x$etdate[i])
      xtdate = as.Date(x$xtdate[i])

      etprice = x$etprice[i]
      xtprice = x$xtprice[i]
      eprice = x$eprice[i]
      xprice = x$xprice[i]

      roi = x$roi[i]
      days_held = x$days_held[i]

      edate14 = edate - 0
      xdate14 = xdate + 28

      q = get.db.quote(symbol, start=edate14, end=xdate14, retclass="ts", quiet=TRUE)
      q1 = get.db.quote(symbol, start=edate14, end=xdate14, retclass="df", quiet=TRUE)

      tjdate <- unclass(julian(tdate))
      ejdate <- unclass(julian(edate))
      xjdate <- unclass(julian(xdate))
      days = xjdate-ejdate

      xlabel = paste("Time, ret:", format(roi, digits=5), "%", "Days held:", days_held)

      if ( !ps.empty() )
          screen(1)

      plotOHLC(q, ylab=symbol, xlab=xlabel, main=paste(symbol, "entry:", edate, "exit:", xdate))
      if ( !is.na(days) && days > 1 ) {
        fit = lsfit(seq(ejdate, xjdate, len=days), seq(eprice, xprice, len=days))
        abline(fit, col='purple')
      }

      x0 = tjdate
      y0 = tprice*0.9
      x1 = tjdate
      y1 = tprice
      arrows(x0, y0, x1, y1, col='yellow')
      x0 = ejdate
      y0 = eprice*0.9
      x1 = ejdate
      y1 = eprice
      arrows(x0, y0, x1, y1, col='green')
      if ( !is.na(xprice) ) {
        x0 = xjdate
        y0 = xprice*0.9
        x1 = xjdate
        y1 = xprice
        arrows(x0, y0, x1, y1, col='red')
      }

      if ( !ps.empty() && !is.na(xdate) ) {
        screen(2)
        pos.stats = get.position.series(ids[i], retclass="its")
        plot(pos.stats)
      }
      ask()
      if ( !ps.empty() ) {
        erase.screen(1)
        erase.screen(2)
      }
    }
    par(op)
  }


get.snap.quote <-
  function (instrument, date, drop=FALSE,  quote = c("Open", "High", "Low", "Close"), retclass="ts")
{
  if (missing(date))
    date <- format(Sys.Date(), "%Y-%m-%d")
  instrument = toupper(instrument)

  con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
  sql <- paste("select seq-88, opening as Open, high as High, low as Low, close as Close from snapshots left outer join tickers ",
               " on tickers.id = ticker_id where symbol = '", instrument, "' and date(bartime) = '", date ,"'",
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
  function(symbol, date, lrline=FALSE, ...) {
  if (missing(date))
    date <- format(Sys.Date(), "%Y-%m-%d")
  frame = get.snap.quote(symbol, date)
  plot.rt.quote(frame, ylab=toupper(symbol), lrline=lrline, main=paste("Realtime 1 min bars for", toupper(symbol), "on", date, ...))
  NULL
}

plot.rt.quote <-
  function (x, xlab = "Time", ylab, col = par("col"), bg = par("bg"), axes = TRUE, frame.plot = axes, ann = par("ann"), main = NULL, lrline = NULL, ...)
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
  print(paste("lrline:", lrline))
  print(x[,1:4])
  if ( !is.null(lrline) ) {
    fit = lsfit(1:nrow(x), x[,4])
    abline(fit, col = 4)
  }

  if (frame.plot)
    box(...)
}

function (x, xlim = NULL, ylim = NULL, xlab = "Time", ylab, col = par("col"),
    bg = par("bg"), axes = TRUE, frame.plot = axes, ann = par("ann"),
    main = NULL, date = c("calendar", "julian"), format = "%Y-%m-%d",
    origin = "1899-12-30", ...)
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
    date <- match.arg(date)
    time.x <- time(x)
    dt <- min(lag(time.x) - time.x)/3
    if (is.null(xlim))
        xlim <- range(time.x)
    if (is.null(ylim))
        ylim <- range(x[is.finite(x)])
    plot.new()
    plot.window(xlim, ylim, ...)
    segments(time.x, x[, "High"], time.x, x[, "Low"], col = col[1],
        bg = bg)
    segments(time.x - dt, x[, "Open"], time.x, x[, "Open"], col = col[1],
        bg = bg)
    segments(time.x, x[, "Close"], time.x + dt, x[, "Close"],
        col = col[1], bg = bg)
    if (ann)
        title(main = main, xlab = xlab, ylab = ylab, ...)
    if (axes) {
        if (date == "julian") {
            axis(1, ...)
            axis(2, ...)
        }
        else {
            n <- NROW(x)
            lab.ind <- round(seq(1, n, length = 5))
            D <- as.vector(time.x[lab.ind] * 86400) + as.POSIXct(origin,
                tz = "GMT")
            DD <- format.POSIXct(D, format = format, tz = "GMT")
            axis(1, at = time.x[lab.ind], lab = DD, ...)
            axis(2, ...)
        }
    }
    if (frame.plot)
        box(...)
}

has.Vo <-
  function (x, which = FALSE)
{
    loc <- grep("Volume", colnames(x))
    if (!identical(loc, integer(0)))
        return(ifelse(which, loc, TRUE))
    ifelse(which, loc, FALSE)
}

arms_em <-
  function(x)
  {
    HLV <- try.xts(x, error = as.matrix)
    if (!has.Hi(HLV) || !has.Lo(HLV) || !has.Vo(HLV))
      stop("must have High, Low, and Volume")
    h = as.numeric(HLV[, "High"])
    l = as.numeric(HLV[, "Low"])
    v = as.numeric(HLV[, "Volume"])
    ((h+l)/2 - (Lag(h)-Lag(l))/2) / (v/(h-l))
  }

volPriceTrend <-
  function(price, volume)
  {
    lp = ifelse(is.na(Lag(price)), price, Lag(price))
    cumsum(volume*(price - lp)/lp)
  }

normalize.m <-
  function(x)
  {
    m = as.matrix(x)
    apply(x,2,normalize.v)
  }

normalize.v <-
  function(v)
  {
    mean.v = mean(v, na.rm=TRUE)
    v[which(is.na(v))] = mean.v
    min.v = min(v)
    max.v = max(v)
    delta = max.v - min.v
    v / delta - (min.v / delta)
  }


generate.ann.data <-
  function(symbol=NA, start_date=NA, end_date=NA)
  {
    if ( is.na(symbol) && is.na(start_date) && is.na(end_date) )
      data(ttrc)
    ts = ttrc
    rsi = rsiTA(ts[, "Close"])
    obv = OBV(ts[, "Close"], ts[, "Volume"])
    vpr = volPriceTrend(ts[, "Close"], ts[, "Volume"])
    HLC = as.matrix(cbind(ts[, "High"], ts[, "Low"], ts[, "Close"]))
    ad = chaikinAD(HLC, ts[, "Volume"])
    stoch.ret = stoch(HLC, 8, 5)
    perD = stoch.ret[,"fastD"]
    perK = stoch.ret[,"fastK"]
    wpr = WPR(HLC, 2)
    arms.em = arms_em(ts)
    perCloseIn4 = 100.0*(Next(ts[, "Close"], 4)-ts[, "Close"])/ts[,"Close"]
    m = as.matrix(cbind(ts$Open, ts$Close, ts$Volume, ad, rsi, perD, perK, wpr, arms.em, obv, vpr))
    target = normalize.v(perCloseIn4)
    m.norm = normalize.m(m)
    ann(m.norm, target)
    #df = data.frame(Date=ts$Date, Open=ts$Open, Close=ts$Close, Volume=ts$Volume, AccDist=ad, RSI=rsi, perD, perK, wpr, arms=arms.em, obv, vpr, perCloseIn4)
    #write.csv(df, "~/ann.csv", row.names=FALSE)
  }

ann <-
  function(inputs, target)
  {
    library(AMORE)
    ncol = NCOL(inputs)
    net <- newff(n.neurons=c(ncol, 8,4, 1), learning.rate.global=1e-2, momentum.global=0.5,
                 error.criterium="LMS", Stao=NA, hidden.layer="tansig", output.layer="purelin", method="ADAPTgdwm")
    result <- train(net, inputs, target, error.criterium="LMS", report=TRUE, show.step=1000, n.shows=50 )
    y <- sim(result$net, inputs)
    plot(target, y, col="blue", pch="+")
    points(target,target, col="red", pch="x")
  }

#do.losers()



