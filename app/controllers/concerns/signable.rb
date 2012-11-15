# This module is used to check the signature of a request coming
# form the physical device in a not secure channel (HTTP)

module Signable
  extend ActiveSupport::Concern

  def verify_signature
    # Ectract the source information
    source = params[:source] || request.headers['X-Request-Source']
    # the request must come from the physical device and in a not secure channel
    if source == 'physical' and not request.ssl?
      # get the article id
      article_id = Moped::BSON::ObjectId(find_id(@device.physical.uri))
      # find the product
      product = Product.where('articles._id' => article_id).first
      # get the signature
      signature  = request.headers['X-Physical-Signature']
      # remove a key that is automatically added by rails
      payload = request.request_parameters.delete_if {|k, v| k == 'property' }
      # unauthorize if the physical id does not exist
      render_401 if not product
      # unauthorize if the signature is not valid
      render_401 if not Signature.valid?(signature, payload, product.secret)
    end
  end
end
