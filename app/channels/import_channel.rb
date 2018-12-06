class ImportChannel < ActionCable::Channel::Base
  def subscribed
    stream_for params[:pid]
  end
end
