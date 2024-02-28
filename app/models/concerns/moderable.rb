# app/models/concerns/moderable.rb
require 'net/http'

module Moderable
  extend ActiveSupport::Concern

  included do
    after_save :moderate_content if respond_to?(:after_save)
  end

  private

  def moderate_content
    content_column = :content
    is_accepted_column = :is_accepted
    language_code = :language
    # Check if the columns to moderate are present
    return unless [content_column, is_accepted_column].all? { |column| self.class.column_names.include?(column.to_s) }

    # Call moderation API
    content = send(content_column)
    language_code = send(language_code) # Adjust according to your needs
    rejection_probability = predict_moderation(content, language_code)

    # Store the result in the is_accepted column
    update(is_accepted_column => rejection_probability < 0.5)
  end

  def predict_moderation(content, language_code)
    uri = URI('https://moderation.logora.fr/predict')
    params = { text: content, language: language_code }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      prediction = JSON.parse(response.body)['prediction']
      prediction['0']
    else
      # Handle moderation API errors
      Rails.logger.error("Failed to get moderation prediction: #{response.code} - #{response.message}")
      0.5 # Neutral value if prediction fails
    end
  end
end
