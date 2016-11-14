class ContentViewController < ApplicationController
  protect_from_forgery with: :exception

  def landing
    @js_flags["menuItem"] = :landing
    @texts = LandingText.current(I18n.locale).texts
    render 'landing', layout: 'content'
  end

  def docs
    @js_flags["menuItem"] = :docs
    render 'docs', layout: 'content'
  end
end
