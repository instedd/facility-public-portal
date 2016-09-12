class ApiController < ActionController::Base
  protect_from_forgery with: :exception

  def suggest
    query = params[:q]
    render json: [
             { kind: "facility", name: "#{query} 1"},
             { kind: "facility", name: "#{query} 2"},
             { kind: "facility", name: "#{query} 3"},

             { kind: "service", name: "s #{query} 1"},
             { kind: "service", name: "s #{query} 2"},
             { kind: "service", name: "s #{query} 3"},
           ]
  end
end
