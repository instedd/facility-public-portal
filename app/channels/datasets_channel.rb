class DatasetsChannel < ActionCable::Channel::Base
  def subscribed
    d = datasets
    transmit(d)
  end

  private

  def datasets
    {
      "categories": {
        "updated_at": DateTime.now,
        "size": 234234,
        "md5": "2b00042f7481c7b056c4b410d28f33cf",
        "applied": false
      },
      "categories_groups": nil,
      "facilities": nil,
      "facility_categories": nil,
      "facility_types": nil,
      "locations": nil
    }
  end
end
