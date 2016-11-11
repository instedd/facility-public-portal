class LandingText < ActiveRecord::Base

  def self.empty
    LandingText.new(draft: false, locale: nil, texts: empty_texts)
  end

  def self.current(locale)
    LandingText.where(locale: locale, draft: false).first
  end

  def self.draft(locale)
    draft = LandingText.where(locale: locale, draft: true).first

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
    LandingText.where(locale: locale, draft: true).destroy_all
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
