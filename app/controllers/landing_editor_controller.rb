class LandingEditorController < ApplicationController
  http_basic_authenticate_with name: Settings.admin_user, password: Settings.admin_pass

  def index
    @texts = LandingText.where(preview: true).first.texts
    render 'index', layout: 'content'
  end

  def edit
    texts = {heading: params[:heading],
      subsection: params[:subsection],
      left_column: params[:left_column],
      right_column: params[:right_column],
      intro_to_search: params[:intro_to_search]
    }
    preview = LandingText.where(preview: true).first
    preview.texts = texts
    preview.save!
    if params[:commit] == 'Publish'
      published = LandingText.where(preview: false).first
      published.texts = texts
      published.save!
      redirect_to root_path
    else
      redirect_to preview_path
    end
  end

  def preview
    @texts = LandingText.where(preview: true).first.texts
    render '/application/landing', layout: 'content'
  end

  def discard_draft
    @texts = LandingText.where(preview: false).first.texts
    draft = LandingText.where(preview: true).first
    draft.texts = @texts
    draft.save!
    redirect_to edit_path
  end

end
