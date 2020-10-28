class ChatSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :message, :is_read, :sender_id, :receiver_id, :created_at, :updated_at, :order_id
end
