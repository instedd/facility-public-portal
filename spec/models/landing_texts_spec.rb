require 'rails_helper'

describe LandingText do
  describe "drafts" do
    it "automatically creates an empty draft if no content for a locale exists" do
      expect {
        LandingText.draft(:en)
      }.to change{LandingText.drafts.count}.from(0).to(1)

      expect {
        LandingText.draft(:en)
      }.not_to change{LandingText.count}
    end

    it "automatically creates a draft based on the currently published text if it exists" do
      texts = LandingText.empty_texts.tap { |t| t["heading"] = "foo" }
      LandingText.create locale: :en, draft: false, texts: texts

      draft = LandingText.draft(:en)
      expect(draft.texts["heading"]).to eq("foo")

      expect(LandingText.published.count).to eq(1)
      expect(LandingText.drafts.count).to eq(1)
    end


    it "creates drafts with all required sections" do
      draft = LandingText.draft(:en)
      expect(draft.texts.keys).to match_array(["title", "heading", "intro_to_search", "left_column", "right_column", "subsection"])
    end

    it "creates drafts with empty texts" do
      draft = LandingText.draft(:en)
      draft.texts.values.each do |text|
        expect(text).to eq("")
      end
    end

    it "allows to discard a draft for a specific locale" do
      LandingText.draft(:en)
      LandingText.draft(:es)

      expect{
        LandingText.discard_draft(:en)
       }.to change{LandingText.drafts.count}.from(2).to(1)

      expect(LandingText.drafts.where(locale: :es).count).to eq(1)
    end
  end

  describe "publishing" do
    it "automatically created empty content if nothing exists" do
      content = LandingText.current(:en)

      expect(LandingText.count).to eq(1)
      expect(content.texts).to eq(LandingText.empty_texts)
    end

    it "automatically created new fields for content stored with old schema" do
      old_text = { "old_field" => "some text" }
      LandingText.create(locale: :en, draft: false, texts: old_text)

      current = LandingText.current(:en)
      expect(current.texts).to eq(old_text.merge(LandingText.empty_texts))
    end

    it "allows to publish and retrieve texts" do
      texts = LandingText.empty_texts.tap { |t| t["heading"] = "foo" }
      LandingText.publish(:en, texts)

      expect(LandingText.published.count).to eq(1)
      expect(LandingText.current(:en).texts["heading"]).to eq("foo")
    end

    it "updates previous content if exists" do
      texts = LandingText.empty_texts
      texts["heading"] = "foo"
      LandingText.publish(:en, texts)

      texts["heading"] = "bar"
      expect {
        LandingText.publish(:en, texts)
      }.not_to change{LandingText.published.count}


      expect(LandingText.current(:en).texts["heading"]).to eq("bar")
    end

    it "allows to publish a draft" do
      texts = LandingText.empty_texts
      texts["heading"] = "foo"

      draft = LandingText.draft(:en)
      draft.texts = texts
      draft.save

      expect(LandingText.drafts.count).to eq(1)

      LandingText.publish_draft(:en)

      expect(LandingText.drafts.count).to eq(0)
      expect(LandingText.published.count).to eq(1)

      current = LandingText.current(:en)
      expect(current.texts).to eq(texts)
    end
  end
end
