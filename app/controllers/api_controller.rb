class ApiController < ActionController::Base
  protect_from_forgery with: :exception

  def suggest
    query = params[:q]

    render json: [
             { kind: "facility", name: "facility #{query} 1"},
             { kind: "facility", name: "facility #{query} 2"},
             { kind: "facility", name: "facility #{query} 3"},

             { kind: "service", name: "service #{query} 1"},
             { kind: "service", name: "service #{query} 2"},
             { kind: "service", name: "service #{query} 3"},
           ]
  end
end
