class UserProfilePhotoSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :photo

  def photo
    if object.photo
      rails_blob_path(object.photo, only_path: true)
    else
      nil
    end
  end
end
