# frozen_string_literal: true

class ScimV2::UsersController < Scimitar::ActiveRecordBackedResourcesController
  def storage_class
    User
  end

  def storage_scope
    User.all
  end
end
