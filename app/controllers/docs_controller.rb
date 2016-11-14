class DocsController < ApplicationController
  protect_from_forgery with: :exception

  def index
    @js_flags["menuItem"] = :docs
    render :index, layout: 'content'
  end
end
