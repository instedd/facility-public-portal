require_relative 'devise'

if User.none?
  User.create! username: Settings.admin_user, password: Settings.admin_pass
end
