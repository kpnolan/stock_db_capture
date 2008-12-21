class RealTimeQuotesController < ApplicationController
  protect_from_forgery :except => [ :progress
                                  ]
  make_resourceful do
    actions :all
  end

  def reload
  end

  def begin_load
    symbols = Ticker.symbols

    $cache.set('Ticker:RealTimeQuoteWorker:index', 0, nil, false)
    $cache.set('Ticker:RealTimeQuoteWorker:iteration_count', 0, nil, false)
    $cache.set('RealTimeQuote:Status', 'initializing', nil, false)
    $cache.set('RealTimeQuote:TotalCount', symbols.length, nil, false)
    $cache.set('RealTimeQuote:Counter', 0, nil, false)

        count = $cache.get('RealTimeQuote:Counter', false).to_i
    num_workers = session[:num_real_time_workers] = params[:num_workers].to_i
    session[:real_time_job_keys] = []
    1.upto(num_workers).each do |i|
      session[:real_time_job_keys] << MiddleMan.new_worker(:class => :real_time_quoter_worker,
                                                           :args => { :symbols => symbols,
                                                                      :chunk_size => 500 })
    end

    render_js do |page|
      page.insert_html :after, 'progress_bars', "<div id='progressbar' class='progress'></div>"
    end
  end


  def progress
    render_js do |page|
      while true
        count = 0
        status = $cache.get('RealTimeQuote:Status', false)
        total = $cache.get('RealTimeQuote:TotalCount', false).to_i
        #count = $cache.get('RealTimeQuote:Counter', false).to_i
        count += 1
        page << "<script type='text/javascript'>updateStatus('#{status}', #{count}, #{count}, #{total});</script>\n"
        sleep(1)
      end
    end
  end
end
