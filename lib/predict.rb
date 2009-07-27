module Predict
  def linear(xvec, yvec, xval)
    x = xvec.is?(Array) ? xvec.to_gv : xvec
    y = yvec.is?(Array) ? yvec.to_gv : yvec
    inter, slope, cov00, cov01, cov11, chisq, status = GSL::Fit.linear(x, y)
    raise Exception, "Non-zero status for GSL::Fit.linear" unless status.zero?
    GSL::Fit::linear_est(xval, inter, slope, cov00, cov01, cov11)
  end
end
