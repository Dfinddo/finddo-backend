require "securerandom"

class ServicesModule::V2::PaymentGatewayService < ServicesModule::V2::BaseService

  def initialize
    @rest_service = ServicesModule::V2::RestService.new
  end

  def create_wirecard_customer(customer_data, address_data)
    new_customer = {
      ownId: SecureRandom.uuid,
      fullname: "#{customer_data[:name]} #{customer_data[:surname]}",
      email: customer_data[:email],
      birthDate: "#{customer_data[:birthdate].split('/')[2]}-#{customer_data[:birthdate].split('/')[1]}-#{customer_data[:birthdate].split('/')[0]}",
      taxDocument: {
          type: "CPF",
          number: customer_data[:cpf]
      },
      phone: {
          countryCode: "55",
          areaCode: customer_data[:cellphone].slice(0, 2),
          number: customer_data[:cellphone].slice(2, customer_data[:cellphone].length - 1)
      },
      shippingAddress: {
          city: address_data[:city],
          complement: address_data[:complement],
          district: address_data[:district],
          street: address_data[:street],
          streetNumber: address_data[:number],
          zipCode: address_data[:cep],
          state: address_data[:state],
          country: "BRA"
      }
    }

    response = @rest_service.post(
      "#{ENV['WIRECARD_API_URL']}/customers",
      new_customer.to_json,
      {
        'Content-Type' => 'application/json',
        'Authorization' => ENV['WIRECARD_OAUTH_TOKEN']
      }
    )

    if response.code == 201
      response
    else
      raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
        JSON.parse(response.body), 'falha ao criar usuário na Wirecard', response.code
      )
    end
  end

  def generate_classical_wirecard_account(account_data, address_data)
    new_account = {
      email: {
          address: account_data[:email]
      },
      person: {
          name: account_data[:name],
          lastName: account_data[:surname],
          taxDocument: {
              "type": "CPF",
              "number": CPF.new(account_data[:cpf]).formatted
          },
          birthDate: "#{account_data[:birthdate].split('/')[2]}-#{account_data[:birthdate].split('/')[1]}-#{account_data[:birthdate].split('/')[0]}",
          phone: {
              "countryCode": "55",
              areaCode: account_data[:cellphone].slice(0, 2),
              number: account_data[:cellphone].slice(2, account_data[:cellphone].length - 1)
          },
          address: {
            city: address_data[:city],
            complement: address_data[:complement],
            district: address_data[:district],
            street: address_data[:street],
            streetNumber: address_data[:number],
            zipCode: address_data[:cep],
            state: address_data[:state],
            country: "BRA"
          }
      },
      type: "MERCHANT"
    }

    response = @rest_service.post(
      "#{ENV['WIRECARD_API_URL']}/accounts",
      new_account.to_json,
      {
        'Content-Type' => 'application/json',
        'Authorization' => ENV['WIRECARD_OAUTH_TOKEN']
      }
    )

    if response.code == 201
      response
    else
      raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
        JSON.parse(response.body), 'falha ao criar usuário na Wirecard', response.code
      )
    end
  end

  def wirecard_account_exists?(cpf)
    cpf_formatted = CPF.new(cpf).formatted
    response = @rest_service.get(
      "#{ENV['WIRECARD_API_URL']}/accounts/exists?tax_document=#{cpf_formatted}",
      {
        'Content-Type' => 'application/json',
        'Authorization' => ENV['WIRECARD_OAUTH_TOKEN']
      }
    )

    if response.code == 200
      true
    elsif response.code = 404
      false
    else
      raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
        JSON.parse(response.body), 'falha ao verificar cpf na Wirecard', response.code
      )
    end
  end

  def generate_access_token_professional(code)
    response = @rest_service.post("#{ENV['WIRECARD_CONNECT_URL']}", 
      "client_id=#{ENV['WIRECARD_APP_ID']}&client_secret=#{ENV['WIRECARD_CLIENT_SECRET']}&redirect_uri=#{ENV['WIRECARD_REDIRECT_URI']}&grant_type=authorization_code&code=#{code}",
      {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'charset' => 'utf-8',
        'Authorization' => ENV['WIRECARD_OAUTH_TOKEN'],
      }
    )
    if response.code == 200
      response
    else
      raise ServicesModule::V2::ExceptionsModule::PaymentGatewayException.new(response.body)
    end
  end
end
