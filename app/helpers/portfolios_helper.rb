module PortfoliosHelper
  def portfolios_path
    objects_path
  end

  def portfolio_path(obj)
    object_path(obj)
  end
end
