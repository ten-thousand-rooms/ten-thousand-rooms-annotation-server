require 'csv'
require 'open-uri'

class ExportController < ApplicationController
  def export
    project_id = params[:project_id]
    user_id = params[:user_id]
    logger.debug("project_id:#{project_id} user_id:#{user_id}")
    @error = nil

    @collection = get_collection(project_id, user_id)

    respond_to do |format|
      format.html do
        headers['Content-Type'] = 'text/html'

        if @collection.nil?
          @error = "Failed to retrieve collection data"
          next
        elsif @collection.manifests.empty?
          @error = "The collection is empty"
          next
        end

        @file_hash = SecureRandom.uuid
        @file_name = build_download_file_name(@collection.label, @file_hash)
        file_path = build_export_file_path(@collection.label, @file_hash)
        @download_prefix = Rails.application.config.s3_download_prefix

        layers = get_layers(project_id)

        @job = ::Collection.delay.export(collection: @collection,
          layers: layers,
          local_file_path: file_path,
          remote_file_name: @file_name)
      end
    end
  end

  ## Check status of the background job
  def check_status
    job_id = params[:job_id]
    job = Delayed::Job.find_by_id(job_id)

    if job.nil?
      isComplete = true
      errorCode = 0
    else
      isComplete = false
      errorMessage = job.last_error
      errorCode = errorMessage ? 1 : 0
    end

    render json: {
      jobId: job_id,
      isComplete: isComplete,
      errorCode: errorCode,
      errorMessage: errorMessage
    }
  end

private
  def get_collection(project_id, user_id)
    service_host=Rails.application.config.iiif_collections_host
    url = "#{service_host}/node/#{project_id}/collection?user_id=#{user_id}"
    logger.debug("Contacting #{url} to get collection data...")
    collection_json = open(url).read
    logger.debug("Collection data received")
    IIIF::Collection.parse_collection(collection_json)
  rescue Exception => e
    logger.error "Failed to get collection from #{url} and parse it - #{e}"
    nil
  end

  def get_layers(project_id)
    group = Group.where(group_id: project_id).first
    group.annotation_layers
  end

  def build_export_file_path(collection_label, file_hash)
    name = s3_escape(collection_label).gsub(/\s+/, '_')
    "#{Rails.root}/tmp/export.#{name}.#{file_hash}.xlsx"
  end

  def build_download_file_name(collection_label, file_hash)
    name = s3_escape(collection_label).gsub(/\s+/, '_')
    "#{name}.#{file_hash}.xlsx"
  end

  # To make filename safe for S3 upload
  def s3_escape(s)
    s = s.encode('ASCII')
    s.gsub! /[^0-9A-Za-z]/, '_'
  rescue Encoding::UndefinedConversionError => e
    'Export'
  end
end