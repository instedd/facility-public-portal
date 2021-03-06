class ContentEditionController < ApplicationController
  before_action :authenticate_user!
  before_action :set_editing_locale, except: :index
  before_action { @js_flags["menuItem"] = :editor }

  def edit
    unless @edit_locale
      redirect_to action: :edit, edit_locale: I18n.default_locale
      return
    end

    @texts = LandingText.draft(@edit_locale).texts
    render layout: 'content'
  end

  def save
    texts = {
      title: params[:title],
      heading: params[:heading],
      subsection: params[:subsection],
      left_column: params[:left_column],
      right_column: params[:right_column],
      contact_info: params[:contact_info],
      intro_to_search: params[:intro_to_search]
    }

    if params[:commit] == 'Publish'
      LandingText.publish(@edit_locale, texts)
      LandingText.discard_draft(@edit_locale)
      redirect_to root_path
    else
      draft = LandingText.draft(@edit_locale)
      draft.texts = texts
      draft.save!
      redirect_to action: :preview, edit_locale: @edit_locale
    end
  end

  def preview
    @in_preview = true
    @texts = LandingText.draft(@edit_locale).texts
    render '/content_view/landing', layout: 'content'
  end

  def discard_draft
    LandingText.discard_draft(@edit_locale)
    redirect_to action: :edit, edit_locale: @edit_locale
  end

  def publish_draft
    LandingText.publish_draft(@edit_locale)
    redirect_to action: :edit, edit_locale: @edit_locale
  end

  private

  def set_editing_locale
    @edit_locale = params[:edit_locale].try(:to_sym)
  end
end
