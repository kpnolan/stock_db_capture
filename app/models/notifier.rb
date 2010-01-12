class Notifier < ActionMailer::Base
  def csv_notification(filename)
    recipients   'LNS@star-mountain.com'
    cc           'kpnolan@comcast.net'
    from         'kpnolan@satvatrader.com'
    subject      File.basename(filename)
    reply_to     'kpnolan@comcast.net'
    body         :watch_list => WatchList.find(:all, :conditions => 'opened_on is NULL')
    content_type 'text/html'
    attachment   :content_type => 'application/csv', :body => File.read(filename)
   end
end
