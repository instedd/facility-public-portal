class ElasticsearchService

  attr_reader :client

  def initialize(url, index_name, locales: Settings.locales.keys, should_log: Rails.env.development?)
    @client     = Elasticsearch::Client.new url: url, log: should_log
    @index_name = index_name
    @locales    = locales
  end

  def setup_index
    client.indices.create index: @index_name
  end

  def setup_mappings
    client.indices.put_mapping({
      index: @index_name,
      type: 'facility',
      body: {
        facility: {
          properties: {
            id: {
              type: 'long'
            },
            source_id: {
              type: 'string',
              index: 'not_analyzed'
            },
            name: {
              type: 'string',
              index: 'analyzed',
              analyzer: "standard",
              fields: {
                raw: {
                  # Needed for sorting.
                  # See https://www.elastic.co/guide/en/elasticsearch/guide/current/multi-fields.html
                  type: 'string',
                  index: 'not_analyzed'
                }
              }
            },
            address: {type: 'string'},
            contact_name: {type: 'string'},
            contact_email: {type: 'string'},
            contact_phone: {type: 'string'},
            opening_hours: localized_string_type,
            ownership: {type: 'string', index: 'not_analyzed'},
            facility_type: {type: 'string', index: 'not_analyzed'},
            position: {type: 'geo_point'},
            photo: {type: 'string', index: 'not_analyzed'},
            last_updated: {
              type: 'date'
            }
          }
        }
      }
    })
  end

  def localized_string_type
    { properties: Hash[@locales.map { |locale| [locale, {type: 'string'}] }] }
  end

  def drop_index
    client.indices.delete index: @index_name
  end

  def index_facility(facility)
    index_document 'facility', facility
  end

  def index_facility_batch(facilities)
    index_batch 'facility', facilities
  end

  def index_facility_types(facility_types)
    index_batch 'facility_type', facility_types
  end

  def index_ownerships(ownerships)
    index_batch 'ownership', ownerships
  end

  def index_category_group(category_group)
    index_document 'category_group', category_group
  end

  def index_category_group_batch(category_groups)
    index_batch 'category_group', category_groups
  end

  def index_category(category)
    index_document 'category', category
  end

  def index_category_batch(categories)
    index_batch 'category', categories
  end

  def index_location(location)
    index_document 'location', location
  end

  def index_location_batch(locations)
    index_batch 'location', locations
  end

  def search_facilities(params)
    list_facilities(params, {_source: [ "id", "name", "priority", "facility_type", "position", "adm" ]})
  end

  def max_administrative_level
    result = client.search({
      index: @index_name,
      type: 'location',
      body: {
        query: { match_all: {} },
        size: 0,
        aggregations: {
          max_level: {max: { field: :level }}
        }
      },
    })

    result["aggregations"]["max_level"]["value"].to_i
  end

  def dump_facilities(params)
    list_facilities(params, {})
  end

  def get_facility_types
    result = client.search({index: @index_name, type: 'facility_type', body: { sort: { id: { order: "asc" } } }})
    result["hits"]["hits"].map { |h| h["_source"] }
  end

  def get_ownerships
    result = client.search({index: @index_name, type: 'ownership', body: { sort: { id: { order: "asc" } } }})
    result["hits"]["hits"].map { |h| h["_source"] }
  end

  def get_locations
    result = client.search({index: @index_name, type: 'location', body: { size: 1000 }})
    result["hits"]["hits"].map { |h| h["_source"] }
  end

  def get_category_groups
    result = client.search({index: @index_name, type: 'category_group', body: { size: 1000, sort: { order: { order: "asc" } }}})

    result["hits"]["hits"].map { |r|
      h = r["_source"]
      keep_i18n_field h, "name"
      h
    }
  end

  def get_categories
    result = client.search({index: @index_name, type: 'category', body: { size: 1000 }})

    result["hits"]["hits"].map { |r|
      h = r["_source"]
      keep_i18n_field h, "name"
      h
    }
  end

  def get_facility(id)
    result = client.search({
      index: @index_name,
      type: 'facility',
      body: {
        size: 1,
        query: {
          match: {id: id}
        },
    }})

    item = result["hits"]["hits"].first["_source"]

    keep_localized_field item, :opening_hours
    keep_localized_field item, :categories_by_group

    api_latlng item
  end

  def suggest_categories(query)
    result = client.search({
      index: @index_name,
      type: 'category',
      body: {
        query: {
          match_phrase_prefix: {
            i18n_key(:name, I18n.locale) => query
          }
        },
    }})

    result["hits"]["hits"].map { |r|
      h = r["_source"]
      keep_i18n_field h, "name"
      h
    }
  end

  def keep_localized_field(hash, field)
    hash[field] = hash[field.to_s][I18n.locale.to_s]
  end

  def keep_i18n_field(hash, field)
    hash[field] = hash[i18n_key(field, I18n.locale)]
    Settings.locales.to_h.each_key { |lang| hash.delete(i18n_key(field, lang)) }
  end

  def i18n_key(name, lang)
    "#{name}:#{lang}"
  end

  def suggest_facilities(params)
    # TODO
    #
    # For the moment we are just perforing a search restricted to 5 results.
    # Suggesting will probably involve using the suggest Elasticsearch API, which
    # trades scoring and analysis capabilities in favour of search speed.
    #
    # Also, we should consider returning a summary payload to reduce network traffic.
    search_facilities(params.merge({size: 5}))[:items]
  end

  def suggest_locations(query)
    result = client.search({
                             index: @index_name,
                             type: 'location',
                             body: {
                               size: 3,
                               query: {
                                 match_phrase_prefix: {
                                   name: query
                                 }
                               },
                             }})

    result["hits"]["hits"].map { |r| r["_source"] }
  end


  def refresh_index
    client.indices.refresh index: @index_name
  end

  def self.instance
    @@instance ||= self.new(ENV['ELASTICSEARCH_URL'] || 'localhost',
                            ENV['ELASTICSEARCH_INDEX'] || 'fpp',
                            should_log: !(ENV['ELASTICSEARCH_LOG'].eql? "0"))
  end

  def self.instance=(instance)
    @@instance = instance
  end

  def self.client
    self.instance.client
  end

  private

  def validate_search(params)
    # TODO
  end

  def api_latlng(document)
    document["position"] = {
      "lat" => document["position"]["lat"].to_f,
      "lng" => document["position"]["lon"].to_f
    }
    document
  end

  def index_document(type, doc)
    client.index({
      index: @index_name,
      type: type,
      id: doc[:id],
      body: doc,
    })
  end

  def index_batch(type, docs)
    actions = docs.flat_map do |doc|
      [{ index: { _index: @index_name, _type: type, _id: doc[:id] } }, doc]
    end

    client.bulk body: actions
  end

  def page_result(result, from, size)
    { items: result["hits"]["hits"].map { |r| api_latlng r["_source"] },
      from: from,
      size: size,
      total: result["hits"]["total"]
    }.tap do |h|
      h[:next_from] = h[:from] + h[:size] if result["hits"]["hits"].count == h[:size]
    end
  end

  def list_facilities(params, search_body)
    validate_search(params)

    size = params[:size].to_i
    size = 1000 if size == 0
    from = params[:from].to_i || 0

    search_body.merge!({
      size: size,
      from: from,
      query: { bool: { must: [] } },
      sort: {}
    })

    if params[:q]
      search_body[:query][:bool][:must] << { match_phrase_prefix: { name: params[:q] } }
    end

    if params[:category]
      search_body[:query][:bool][:must] << { match: { categories_ids: params[:category] } }
    end

    if params[:type]
      search_body[:query][:bool][:must] << { match: { facility_type_id: params[:type] } }
    end

    if params[:ownership]
      search_body[:query][:bool][:must] << { match: { ownership_id: params[:ownership] } }
    end

    if params[:location]
      search_body[:query][:bool][:must] << { match: { adm_ids: params[:location] } }
    end


    sort = params[:sort].try(:to_sym) || :distance

    case sort
    when :type
      search_body[:sort] = {
        priority: { order: "desc" },
        facility_type_id: { order: "desc" }
      }
    when :name
      search_body[:sort] = {
        'name.raw': { order: "asc" },
      }
    else
      if params[:lat] && params[:lng]
        search_body[:sort] = {
          _geo_distance: {
            position: {
              lat: params[:lat],
              lon: params[:lng]
            },
            order: "asc",
            unit:  "km",
            distance_type: "plane"
          }
        }
      else
        # Default sorting "_doc" has no semantic meaning, but is the  most efficient mechanism
        # and ensures consistent result order when paginating and scrolling results.
        #
        # See https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-sort.html
        search_body[:sort] = { _doc: { order: "asc" } }
      end
    end

    result = client.search({
      index: @index_name,
      type: 'facility',
      body: search_body
    })

    page_result(result, from, size)
  end
end
