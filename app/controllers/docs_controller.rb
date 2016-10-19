class DocsController < ActionController::Base
  protect_from_forgery with: :exception

  def index
    render :index, layout: 'application'
  end
end
