require "securerandom"

class ServicesModule::V2::PaymentGatewayService < ServicesModule::V2::BaseService

  def initialize
    @rest_service = ServicesModule::V2::RestService.new
  end

  def add_credit_card(credit_card_cata, customer_data)
    response = @rest_service.post(
      "#{ENV['WIRECARD_API_URL']}/customers/#{customer_data.customer_wirecard_id}/fundinginstruments",
      credit_card_cata.to_json,
      {
        'Content-Type' => 'application/json',
        'Authorization' => ENV['WIRECARD_OAUTH_TOKEN']
      }
    )

    if response.code == 201
      response
    else
      raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
        JSON.parse(response.body), 
        'falha ao adicionar cartão de crédito na Wirecard', response.code
      )
    end
  end

  def get_customer_credit_card_data(customer_wirecard_id)
    begin
      response = get_wirecard_customer(customer_wirecard_id)
      parsed_response = JSON.parse(response.body)
      if parsed_response["fundingInstruments"]
        parsed_response["fundingInstruments"]
      else
        []
      end
    rescue ServicesModule::V2::ExceptionsModule::WebApplicationException => e
      raise e
    end
  end

  def remove_customer_credit_card_data(card_id)
    response = @rest_service.delete(
      "#{ENV['WIRECARD_API_URL']}/fundinginstruments/#{card_id}",
      {
        'Content-Type' => 'application/json',
        'Authorization' => ENV['WIRECARD_OAUTH_TOKEN']
      }
    )

    if response.code != 200
      raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
        JSON.parse(response.body), 
        'falha ao remover cartão de crédito na Wirecard', response.code
      )
    end
  end

  def get_wirecard_customer(customer_wirecard_id)
    response = @rest_service.get(
      "#{ENV['WIRECARD_API_URL']}/customers/#{customer_wirecard_id}",
      {
        'Content-Type' => 'application/json',
        'Authorization' => ENV['WIRECARD_OAUTH_TOKEN']
      }
    )

    if response.code == 200
      response
    else
      raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
        JSON.parse(response.body), 
        'falha ao buscar cliente na Wirecard', response.code
      )
    end
  end

  def create_wirecard_payment(payment_data, order)
    response = @rest_service.post(
      "#{ENV['WIRECARD_API_URL']}/orders/#{order.order_wirecard_id}/payments",
      payment_data.to_json,
      {
        'Content-Type' => 'application/json',
        'Authorization' => ENV['WIRECARD_OAUTH_TOKEN']
      }
    )

    if response.code == 201
      response
    else
      raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
        JSON.parse(response.body), 'falha ao criar pagamento na Wirecard', response.code
      )
    end
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
    elsif response.code == 404
      false
    else
      raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
        JSON.parse(response.body), 'falha ao verificar cpf na Wirecard', response.code
      )
    end
  end

  def create_wirecard_order(order, value, session_user)
      wirecard_order = {
        ownId: SecureRandom.uuid,
        amount: {
          currency: "BRL"
        },
        items: [
          {
            product: order.category.name,
            quantity: 1,
            detail: "Prestação de serviço residencial",
            price: calculate_service_value(value)[:value_with_tax].to_i
          }
        ],
        customer: {
          id: order.user.customer_wirecard_id
        },
        receivers: [
          {
            type: "PRIMARY",
            feePayor: true,
            moipAccount: {
              id: "#{ENV['MOIP_ACCOUNT_ID']}"
            },
            amount: {
              fixed: calculate_service_value(value)[:tax_value].to_i
            }
          },
          {
            type: "SECONDARY",
            feePayor: false,
            moipAccount: {
              id: session_user.id_wirecard_account
            },
            amount: {
              fixed: value.to_i
            }
          }
        ]
      }

    response = @rest_service.post(
      "#{ENV['WIRECARD_API_URL']}/orders",
      wirecard_order.to_json,
      {
        'Content-Type' => 'application/json',
        'Authorization' => ENV['WIRECARD_OAUTH_TOKEN']
      }
    )

    if response.code == 201
      response
    else
      raise ServicesModule::V2::ExceptionsModule::WebApplicationException.new(
        JSON.parse(response.body), 'falha ao criar pedido na Wirecard', response.code
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

  def calculate_service_value(value)
    value_with_tax = 0

    if value < 80
      value_with_tax = value * 1.25
    elsif value < 500
      value_with_tax = value * 1.2
    else
      value_with_tax = value * 1.15
    end

    { value_with_tax: value_with_tax, tax_value: value_with_tax - value }
  end
end
