class LandingText < ActiveRecord::Base

  def texts
    read_attribute(:texts).with_indifferent_access
  end
end
