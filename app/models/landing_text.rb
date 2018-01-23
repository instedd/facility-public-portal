class LandingText < ActiveRecord::Base

  scope :drafts, -> { where(draft: true) }
  scope :published, -> { where(draft: false) }

  def self.current(locale)
    current = LandingText.published.where(locale: locale).first

    if current
      current.texts = current.texts.reverse_merge(empty_texts)
      current
    else
      LandingText.create(draft: false, locale: locale, texts: empty_texts)
    end
  end

  def self.draft(locale)
    draft = LandingText.drafts.where(locale: locale).first

    unless draft
      real = LandingText.current(locale)
      draft = LandingText.create locale: locale, draft: true, texts: real.texts
    end

    draft
  end

  def self.publish(locale, texts)
    if current = LandingText.current(locale)
      current.texts = texts
    else
      current = LandingText.new(draft: false, locale: locale, texts: texts)
    end
    current.save!
  end

  def self.discard_draft(locale)
    LandingText.drafts.where(locale: locale).destroy_all
  end

  def self.publish_draft(locale)
    draft = LandingText.drafts.where(locale: locale).first
    raise "no draft to publish" unless draft

    LandingText.published.where(locale: locale).destroy_all

    draft.draft = false
    draft.save
  end

  def self.empty_texts
    {
      "title" => "",
      "heading" => "",
      "subsection" => "",
      "left_column" => "",
      "right_column" => "",
      "contact_info" => "",
      "intro_to_search" => ""
    }
  end
  def texts
    read_attribute(:texts).with_indifferent_access
  end
end
