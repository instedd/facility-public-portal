class LandingText < ActiveRecord::Base

  scope :drafts, -> { where(draft: true) }
  scope :published, -> { where(draft: false) }

  def self.empty
    LandingText.new(draft: false, locale: nil, texts: empty_texts)
  end

  def self.current(locale)
    LandingText.published.where(locale: locale).first
  end

  def self.draft(locale)
    draft = LandingText.drafts.where(locale: locale).first

    unless draft
      real = LandingText.current(locale) || LandingText.empty
      draft = LandingText.create locale: locale, draft: true, texts: real.texts
    end

    draft
  end

  def self.publish(locale, texts)
    current = LandingText.current(locale)
    if !current
      current = LandingText.empty
      current.locale = locale
    end
    current.texts = texts
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
      "heading" => "",
      "subsection" => "",
      "left_column" => "",
      "right_column" => "",
      "intro_to_search" => ""
    }
  end
  def texts
    read_attribute(:texts).with_indifferent_access
  end
end
