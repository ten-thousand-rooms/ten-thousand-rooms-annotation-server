class AnnotationList < ActiveRecord::Base
  attr_accessible  :list_id,
                   :list_type,
                   :resources,
                   :within,
                   :label,
                   :description
  def to_iiif
    # get the list's annotation records via the sequencing map table
    @resourcesArr = Array.new
    @annoIds = ListAnnotationsMap.where(list_id:list_id).order(:sequence)

    @annoIds.each do |annoId|
      @Anno = Annotation.where(annotation_id: annoId.annotation_id).first
      @annoJson = Hash.new
      @annoJson['@id'] = @Anno.annotation_id
      @annoJson['@type'] = @Anno.annotation_type
      @annoJson['@context'] = "http://iiif.io/api/presentation/2/context.json"
      @annoJson['@motivation'] = @Anno.motivation
      @annoJson['resource'] = JSON.parse(@Anno.resource)
      @annoJson['annotatedBy'] = JSON.parse(@Anno.annotated_by)
      @resourcesArr.push(@annoJson)
      #@resourceJson = @idJson.merge(JSON.parse(@Anno.resource))
     # @resourcesArr.push(@resourceJson)
    end

    iiif = Hash.new
    iiif['@id'] = list_id
    iiif['@type'] = list_type
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"
    iiif['label'] = label if !label.nil?
    iiif['description'] = description if !description.nil?
    iiif['within'] = LayerListsMap.getLayersForList list_id
    iiif['resources'] = @resourcesArr
    iiif
  end
end
