class ServicesModule::V2::AddressService < ServicesModule::V2::BaseService

  def set_selected_address(user, selected_address)
    Address.transaction do
      user.addresses.each do |address|
        if !address.update(selected: false)
          raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
            address.errors, 'falha ao atualizar endereço', 422
          )
        end
      end

      if !selected_address.update(selected: true)
        raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
          selected_address.errors, 'falha ao atualizar endereço', 422
        )
      end
    end
  end
end