require "rails_helper"

RSpec.describe OnaTransformation do
  def facility_data_sample
    [
      ["id", "fac_field_1", "fac_field_2", "fac_field_3"],
      ["1", "value_1_1", "value_1_2", "value_1_3"]
    ]
  end

  CATEGORIES_HEADER = ["id", "category_group_id", "name:en"]

  def categories_data_sample
    [
      CATEGORIES_HEADER,
      ["category_id_1", "category_group_id_1", "Category 1"]
    ]
  end

  MAPPINGS_HEADER = ["category_id", "data_column", "true values", "false values"]

  def mappings_data_sample
    [
      MAPPINGS_HEADER,
      ["category_id_1", "data_column_1", "true value 1", "false value 1"]
    ]
  end

  FACILITY_CATEGORIES_HEADER = ["facility_id", "category_id"]

  it "yields empty output for empty input" do
    facility_data = []
    categories = []
    mappings = []

    facility_categories = OnaTransformation.facility_categories(facility_data, categories, mappings)

    expect(facility_categories).to eq([["facility_id", "category_id"]])
  end

  it "yields empty output for empty facility_data" do
    facility_data = []

    categories = [
      ["id", "category_group_id", "name:en"],
      ["foo", "bar", "baz"]
    ]

    mappings = [
      ["category_id", "data_column", "True values", "False values"],
      ["foo", "bar", "baz", "not baz"]
    ]

    facility_categories = OnaTransformation.facility_categories(facility_data, categories, mappings)

    expect(facility_categories).to eq([["facility_id", "category_id"]])
  end

  it "yields empty output for empty categories" do
    facility_data = facility_data_sample
    categories = categories_data_sample

    mappings = []

    facility_categories = OnaTransformation.facility_categories(facility_data, categories, mappings)

    expect(facility_categories).to eq([["facility_id", "category_id"]])
  end

  it "checks mapping columns are valid" do
    facility_data = facility_data_sample
    categories = categories_data_sample
    mappings = [["foo", "bar", "baz"]]

    expect {OnaTransformation.facility_categories(facility_data, categories, mappings)}
      .to raise_error(ArgumentError,
        "I don't understand this mapping file. I expect its headers to be exactly: #{MAPPINGS_HEADER.to_s}\nInstead, it was: [\"foo\", \"bar\", \"baz\"]")
  end

  it "is case insensitive for mapping columns names" do
    facility_data = facility_data_sample
    categories = categories_data_sample
    mappings = [["CaTeGoRy_id", "DaTa_CoLuMn", "True VaLuEs", "FaLsE VaLuES"]]
    OnaTransformation.facility_categories(facility_data, categories, mappings)
  end

  it "raises if mapping contains invalid data column" do
    facility_data = facility_data_sample
    categories = categories_data_sample
    mappings = [
      MAPPINGS_HEADER,
      ["foo", "not-a-column-in-data-file", "Yes", "No"]
    ]

    expect{OnaTransformation.facility_categories(facility_data, categories, mappings)}
      .to raise_error(ArgumentError,
        "I can't find column 'not-a-column-in-data-file' in ONA data file.")
  end

  it "finds a mapping" do
    facility_data = facility_data_sample
    categories = categories_data_sample
    mappings = [
      MAPPINGS_HEADER,
      ["category_id_1", "fac_field_1", "value_1_1", ""]
    ]

    expect(OnaTransformation.facility_categories(facility_data, categories, mappings))
      .to eq([
        FACILITY_CATEGORIES_HEADER,
        ["1", "category_id_1"]
      ])
  end

  it "ignores true values if there false values also match" do
    facility_data = facility_data_sample
    categories = categories_data_sample
    mappings = [
      MAPPINGS_HEADER,
      ["category_id_1", "fac_field_1", "value_1_1", "value_1_1"]
    ]

    expect(OnaTransformation.facility_categories(facility_data, categories, mappings))
      .to eq([FACILITY_CATEGORIES_HEADER])
  end

  it "matches any true value" do
    facility_data = facility_data_sample
    categories = categories_data_sample
    mappings = [
      MAPPINGS_HEADER,
      ["category_id_1", "fac_field_1", "sarasa,value_1_1", ""]
    ]

    expect(OnaTransformation.facility_categories(facility_data, categories, mappings))
      .to eq([
        FACILITY_CATEGORIES_HEADER,
        ["1", "category_id_1"]
      ])
  end

  it "defaults to true if there are false values but no true values" do
    facility_data = facility_data_sample
    categories = categories_data_sample
    mappings = [
      MAPPINGS_HEADER,
      ["category_id_1", "fac_field_1", "", "sarasa,serese"]
    ]

    expect(OnaTransformation.facility_categories(facility_data, categories, mappings))
      .to eq([
        FACILITY_CATEGORIES_HEADER,
        ["1", "category_id_1"]
      ])
  end

  it "searches for true or false values as substrings of the facility field value" do
    facility_data = facility_data_sample
    facility_data.push ["2", "crazyvalue", "somestringamongotherthings", "otherthingsandastring"]

    categories = categories_data_sample
    categories.push ["category_id_2", "category_group_id_2", "Category 2"]

    mappings = [
      MAPPINGS_HEADER,
      ["category_id_1", "fac_field_1", "zyva", ""],
      ["category_id_2", "fac_field_3", "otherthingsandastring", "astring"],
      ["category_id_3", "fac_field_2", "option1,stringamongo,option2", ""]
    ]

    expect(OnaTransformation.facility_categories(facility_data, categories, mappings))
      .to eq([
        FACILITY_CATEGORIES_HEADER,
        ["2", "category_id_1"],
        ["2", "category_id_3"]
      ])
  end

  it "supports nil true/false values" do
    facility_data = facility_data_sample
    categories = categories_data_sample
    mappings = [
      MAPPINGS_HEADER,
      ["category_id_1", "fac_field_1", nil, nil],
    ]
    OnaTransformation.facility_categories(facility_data, categories, mappings)
  end

  it "validates there is an 'id' column in data file" do
    facility_data = [["facility_id", "fac_field_1", "fac_field_2", "fac_field_3"]]
    categories = categories_data_sample
    mappings = mappings_data_sample

    expect {OnaTransformation.facility_categories(facility_data, categories, mappings)}
      .to raise_error(ArgumentError,
        "ONA data.csv file must have an 'id' column containing the facility ids.")
  end

  it "grabs facility ids from the 'id' column" do
    facility_data = [
      ["fac_field_1", "fac_field_2", "id", "fac_field_3"],
      ["value_1_1", "value_1_2", "1", "value_1_3"]
    ]
    categories = categories_data_sample
    mappings = [
      MAPPINGS_HEADER,
      ["category_id_1", "fac_field_1", "sarasa,value_1_1", ""]
    ]

    expect(OnaTransformation.facility_categories(facility_data, categories, mappings))
      .to eq([
        FACILITY_CATEGORIES_HEADER,
        ["1", "category_id_1"]
      ])
  end

  it "allows data to be nil for a mapped field" do
    facility_data = [
      ["id", "fac_field_1", "fac_field_2", "fac_field_3"],
      ["1", nil, "value_1_2", "value_1_3"]
    ]

    categories = categories_data_sample

    mappings = [
      MAPPINGS_HEADER,
      ["category_id_1", "fac_field_1", "", "no result"]
    ]
    expect(OnaTransformation.facility_categories(facility_data, categories, mappings))
      .to eq([
        FACILITY_CATEGORIES_HEADER,
        ["1", "category_id_1"]
      ])
  end
end
