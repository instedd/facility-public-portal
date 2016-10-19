class DocsController < ApplicationController
  protect_from_forgery with: :exception

  def index
    render :index, layout: 'content'
  end
end
