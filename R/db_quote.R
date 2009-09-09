require(RMySQL)
require(tseries)
require(gtools)


get.id.quote <-
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
  sql <- paste("select bartime, opening as Open, high as High, low as Low, close as Close from intra_day_bars left outer join tickers ",
    " on tickers.id = ticker_id where symbol = '", instrument, "' and date(start_date) >= '", start, "' and date(start_date) <= '", end, "' order by bartime desc", sep="")
  res = dbSendQuery(con, sql)
  x = fetch(res, n = -1)
  dbDisconnect(con)

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
  function(pos_id, origin = "1899-12-30", retclass = c("zoo", "its", "ts"), indicators = c('rsi', 'rvi', 'macd_hist'),
           quiet = FALSE, drop = FALSE)  {
  sql <- paste("select date,",
                "sum(if(name='rsi', value, 0)) as rsi,",
                "sum(if(name='rvi', value, 0)) as rvi,",
                "sum(if(name='macd_hist', value, 0)) as macd_hist",
               "from position_series left outer join indicators on indicators.id = indicator_id",
               "where position_id = ", pos_id, "group by date order by date desc")
  con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
  res = dbSendQuery(con, sql)
  x = fetch(res, n = -1)
  dbDisconnect(con)

  x$macd_hist = x$macd_hist * 10.0

  names(x) <- gsub("\\.", "", names(x))
  nser <- pmatch(indicators, names(x)[-1]) + 1
  n <- nrow(x)

  dat <- as.Date(as.character(x[, 1]), "%Y-%m-%d")

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


get.db.quote <-
function (instrument, start, end, quote = c("Open", "High", "Low", "Close"),
          method = NULL, origin = "1899-12-30",
          retclass = c("zoo", "its", "ts"), quiet = FALSE, drop = FALSE)
{
  if (missing(start))
    start <- "2009-01-02"
  if (missing(end) || is.na(end))
    end <- format(Sys.Date() - 1, "%Y-%m-%d")
  retclass <- match.arg(retclass)
  start <- as.Date(start)
  end <- as.Date(end)
  con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
  sql <- paste("select date(bartime) as date, opening as Open, high as High, low as Low, close as Close from daily_bars left outer join tickers ",
    " on tickers.id = ticker_id where symbol = '", instrument, "' and bartime between '", start, "' and '", end, "' order by bartime desc", sep="")
  res = dbSendQuery(con, sql)
  x = fetch(res, n = -1)
  dbDisconnect(con)

  names(x) <- gsub("\\.", "", names(x))
  nser <- pmatch(quote, names(x)[-1]) + 1
  n <- nrow(x)

  print(paste("Rows:", n))

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

## get.positions <-
##   function( origin = "1899-12-30", quote=c("entry_price", "exit_price")) {
##     con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
##     sql <- paste("select symbol, date(entry_date) as entry_date, date(exit_date) as exit_date, entry_price, exit_price from positions left outer join tickers",
##                  "on tickers.id = ticker_id order by symbol, entry_date")
##     res = dbSendQuery(con, sql)
##     x = fetch(res, n = -1)
##     if ( nrow(x) == 0 ) {
##       cat("Positions table is empty")
##       return(FALSE);
##     }
##     nser <- pmatch(quote, names(x))
##     n <- nrow(x)

##     edat <- as.Date(as.character(x[, 2]), "%Y-%m-%d")
##     xdat <- as.Date(as.character(x[, 3]), "%Y-%m-%d")

##     ejdat <- unclass(julian(edat, origin = as.Date(origin)))
##     xjdat <- unclass(julian(xdat, origin = as.Date(origin)))
##     sdate <- ejdat - 7
##     endate <- xjdat + 7
##     ind
##     ind <- as.vector(c(sdate, endate))
##     y <- matrix(NA, nrow = max(ind), ncol = length(nser))
##     y[ind, ] <- as.matrix(x[, nser, drop = FALSE])
##     colnames(y) <- names(x)[nser]
##     y <- y[, seq_along(nser), drop = drop]
##     return(ts(y, start = e, end = jdat[1]))
##   }

do.positions <-
  function(type="normal") {
    if ( type == "normal" ) {
      pos = get.positions(order="order by triggered_at, ticker_id")
    } else if ( type == "losers" ) {
      pos = get.positions(where="where year(entry_date) = 2009 and roi < 0 and closed is not null", order="order by roi")
    } else if ( type == "winners" ) {
      pos = get.positions(where="where year(entry_date) = 2009 and roi > 0 and closed is not null", order="order by roi desc")
    } else if ( type == "non" ) {
      pos = get.positions(where="where year(entry_date) = 2009 and closed is null", order="order by roi")
    } else {
      print("invalid arg")
    }
    plot.positions(type, pos)
#    pos
  }

strategy=""

get.positions <-
  function( origin = "1899-12-30", quote=c("entry_price", "exit_price"), order="order by symbol, triggered_at", where="") {
    con <- dbConnect(MySQL(), user="kevin", pass="Troika3.", db="active_trader_production")
    sql <- paste("select positions.id as id, symbol, date(triggered_at) as tdate, date(entry_date) as edate, date(exit_date) as xdate, trigger_price as tprice, entry_price as eprice, exit_price as xprice, roi, days_held from positions left outer join tickers",
                 "on tickers.id = ticker_id", where, strategy, order)
    res = dbSendQuery(con, sql)
    x = fetch(res, n = -1)
    if ( nrow(x) == 0 ) {
      cat("Positions table is empty")
      return(FALSE);
    }
    x
  }

plot.positions <-
  function(type, x,  origin = "1899-12-30", scale=10.0) {
    ids = x$id
    syms = x$symbol
    closed = x$closed
    tdates = x$tdate
    edates = x$edate
    xdates = x$xdate
    tprices = x$tprice
    eprices = x$eprice
    xprices = x$xprice
    rois = x$roi
    dh = x$days_held
    print(paste("There are", length(syms), "entries in this set"))
    op <- par(pty = "m", bg="white")

    if ( !ps.empty() )
      split.screen(c(2,1))

    for ( i in 1:length(syms) )  {
      if ( is.na(edates[i]) )
        next

      symbol = syms[i]
      tdate = as.Date(tdates[i])
      edate = as.Date(edates[i])
      xdate = as.Date(xdates[i])
      tprice = tprices[i]
      eprice = eprices[i]
      xprice = xprices[i]

      roi = rois[i]
      days_held = dh[i]
      edate14 = edate - 14
      xdate14 = xdate + 14

      q = get.db.quote(symbol, start=edate14, end=xdate14, retclass="ts", quiet=TRUE)
      tjdate <- unclass(julian(tdate, origin = as.Date(origin)))
      ejdate <- unclass(julian(edate, origin = as.Date(origin)))
      xjdate <- unclass(julian(xdate, origin = as.Date(origin)))
      days = xjdate-ejdate

      roi = roi * 100.0
      xlabel = paste("Time, ret:", format(roi, digits=5), "%", "Days held:", days_held)

      if ( !ps.empty() )
          screen(1)

      plotOHLC(q, ylab=symbol, xlab=xlabel, main=paste(symbol, "entry:", edate, "exit:", xdate))
      if ( !is.na(days) && days > 1 ) {
        fit = lsfit(seq(ejdate, xjdate, len=days), seq(eprice, xprice, len=days))
        abline(fit, col='purple')
      }

      x0 = tjdate
      y0 = tprice
      x1 = tjdate
      y1 = tprice+.01
      arrows(x0, y0, x1, y1, col='yellow')
      x0 = ejdate
      y0 = eprice
      x1 = ejdate
      y1 = eprice+.01
      arrows(x0, y0, x1, y1, col='green')
      if ( !is.na(xprice) ) {
        x0 = xjdate
        y0 = xprice
        x1 = xjdate
        y1 = xprice-.01
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
