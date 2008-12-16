class DailyClosesController < ApplicationController
  make_resourceful do
    actions :all
  end

  def reload
  end

  def begin_load
    num_workers = session[:num_workers] = params[:num_workers].to_i
    ticker_groups = Ticker.id_groups(num_workers)
    session[:job_keys] = []
    1.upto(num_workers).each do |i|
      session[:job_keys] << MiddleMan.new_worker(:class => :load_historical_quotes_worker,
                                                 :args => { :start_date => 1.year.ago,
                                                            :end_date => Date.today,
                                                            :ticker_ids => ticker_groups[i-1] })
    end
    render_js do |page|
      1.upto(num_workers).each do |i|
        page.insert_html :after, 'progress_bars', "<div id='progressbar_#{i}' class='progress'></div>"
      end
    end
  end

  def progress
    progress_percent = Array.new(session[:num_workers])
    1.upto(session[:num_workers]) do |i|
      progress_percent[i-1] = ((MiddleMan.get_worker(session[:job_keys][i-1]).progress)*100).round
    end
    render_js do |page|
      1.upto(session[:num_workers]) do |i|
        page.call('progressPercent', "progressbar_#{i}", progress_percent[i-1])
      end
    end
  end
end
