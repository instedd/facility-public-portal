require 'rails_helper'

describe LandingText do
  describe "drafts" do
    it "automatically creates an empty draft if no content for a locale exists" do
      expect {
        LandingText.draft(:en)
      }.to change{LandingText.count}.from(0).to(1)

      expect {
        LandingText.draft(:en)
      }.not_to change{LandingText.count}
    end

    it "automatically creates a draft based on the currently published text if it exists" do
      texts = LandingText.empty_texts.tap { |t| t["heading"] = "foo" }
      LandingText.create locale: :en, draft: false, texts: texts

      draft = LandingText.draft(:en)
      expect(draft.texts["heading"]).to eq("foo")

      expect(LandingText.where(draft: false).count).to eq(1)
      expect(LandingText.where(draft: true).count).to eq(1)
    end


    it "creates drafts with all required sections" do
      draft = LandingText.draft(:en)
      expect(draft.texts.keys).to match_array(["heading", "intro_to_search", "left_column", "right_column", "subsection"])
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
       }.to change{LandingText.count}.from(2).to(1)

      expect(LandingText.where(locale: :es).count).to eq(1)
    end
  end

  describe "published" do
    it "allows to publish and retrieve texts" do
      texts = LandingText.empty_texts.tap { |t| t["heading"] = "foo" }
      LandingText.publish(:en, texts)

      expect(LandingText.where(draft: false).count).to eq(1)
      expect(LandingText.current(:en).texts["heading"]).to eq("foo")
    end

    it "updates previous content if exists" do
      texts = LandingText.empty_texts
      texts["heading"] = "foo"
      LandingText.publish(:en, texts)

      texts["heading"] = "bar"
      expect {
        LandingText.publish(:en, texts)
      }.not_to change{LandingText.where(draft: false).count}


      expect(LandingText.current(:en).texts["heading"]).to eq("bar")
    end
  end
end
