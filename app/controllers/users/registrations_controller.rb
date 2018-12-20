class Users::RegistrationsController < Devise::RegistrationsController
  def edit
    @js_flags["menuItem"] = :account
    super
  end
end
