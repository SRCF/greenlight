class SharedFilesController < ApplicationController
  def retrieve
    blob = ActiveStorage::Blob.find_by(key: params[:key])
    send_data(blob.download, filename: blob.filename.to_s)
  end
end
