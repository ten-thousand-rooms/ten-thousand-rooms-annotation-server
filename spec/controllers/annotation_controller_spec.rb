require 'rails_helper'
require "cancan/matchers"

include Warden::Test::Helpers
Warden.test_mode!
include Devise::TestHelpers

RSpec.describe AnnotationController, :type => :controller do

  before(:each) do
    @user = FactoryGirl.create(:jasper99)

    @annoList1 ='{"list_id": "http://localhost:5000/lists/list1", "list_type": "sc:AnnotationList", "label":"transcription layer 1 list 1"}'
    @annotation_list1 = AnnotationList.create(JSON.parse(@annoList1))
    @annoList2 ='{"list_id": "http://localhost:5000/lists/list2", "list_type": "sc:AnnotationList", "label":"transcription layer 1 list 2"}'
    @annotation_list2 = AnnotationList.create(JSON.parse(@annoList2))

    @grp='{"group_id": "http://localhost:5000/groups/testGroup", "group_description":"test group"}'
    @acl1 ='{"resource_id":"http://localhost:5000/layers/testLayer1", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl2 ='{"resource_id":"http://localhost:5000/layers/testLayer2", "acl_mode": "write", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl3 ='{"resource_id":"http://localhost:5000/layers/testLayer3", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup3"}'
    @acl4 ='{"resource_id":"http://localhost:5000/annotations/testAnnotation", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl5 ='{"resource_id":"http://localhost:5000/annotations/testAnnotation", "acl_mode": "update", "group_id": "http://localhost:5000/groups/testGroup"}'

    @group= Group.create(JSON.parse(@grp))
    @webAcl1= Webacl.create(JSON.parse(@acl1))
    @webAcl2= Webacl.create(JSON.parse(@acl2))
    @webAcl3= Webacl.create(JSON.parse(@acl3))
    @webAcl4= Webacl.create(JSON.parse(@acl4))
    @webAcl5= Webacl.create(JSON.parse(@acl5))
  end

  context 'when Post is called' do
    describe 'POST annotation json' do
      before(:each) do
        @annoString ='{"@type": "oa:annotation",
                      "motivation": "yale:transcribing",
                      "within":["http://localhost:5000/lists/list1"],
                      "resource":{"@type":"cnt:ContentAsText","chars":"transcription1 list 1 annotation 1 **","format":"text/plain"},
                      "annotatedBy":{"@id":"http://annotations.tenthousandrooms.yale.edu/user/5390bd85a42eedf8a4000001","@type":"prov:Agent","name":"Test User 8"},
                      "on":"http://dms-data.stanford.edu/Walters/zw200wd8767/canvas/canvas-359#xywh=47,191,1036,1140"}'
        sign_in @user
      end

      it 'returns a 201 ("created") response' do
        post :create, JSON.parse(@annoString), :format => 'json', :Content_Type => 'application/json', :Accept => 'application/json'
        expect(response.status).to eq(201)
      end

      it 'creates a new Annotation' do
        expect { post :create, JSON.parse(@annoString) }.to change(Annotation, :count).by(1)
      end

      it 'creates an @id for the returned annotation' do
        post :create, JSON.parse(@annoString)
        expect(response.status).to eq(201)
        json = JSON.parse(response.body)
        expect(json['@id']).to be_truthy
      end

      it 'assigns the version' do
        post :create, JSON.parse(@annoString)
        @annotation = Annotation.last()
        expect(@annotation['version']).to eq (1)
      end

      it 'fails validation if motivation is nil' do
        annoJSON = JSON.parse(@annoString)
        annoJSON['motivation'] = nil
        post :create, annoJSON
        expect(response.status).to eq(422)
      end

      it 'does not fail validation if within is nil' do
        annoJSON = JSON.parse(@annoString)
        annoJSON['within'] = nil
        post :create, annoJSON
        expect(response.status).to eq(201)
      end

      it 'updates the map if within is not nil' do
        annoJSON = JSON.parse(@annoString)
        post :create, annoJSON
        json = JSON.parse(response.body)
        lists = ListAnnotationsMap.getListsForAnnotation json['@id']
        expect(lists).not_to eq(nil)
        expect(lists).to eq(annoJSON['within'])
      end
      after(:each) do
        sign_out @user
      end
    end
  end

  context 'when Get is called' do
    describe 'GET annotation json' do
      before(:each) do
        @annoString ='{"@type": "oa:annotation",
                      "motivation": "yale:transcribing",
                      "within":["http://localhost:5000/lists/list1"],
                      "resource":{"@type":"cnt:ContentAsText","chars":"transcription1 list 1 annotation 1 **","format":"text/plain"},
                      "annotatedBy":{"@id":"http://annotations.tenthousandrooms.yale.edu/user/5390bd85a42eedf8a4000001","@type":"prov:Agent","name":"Test User 8"},
                      "on":"http://dms-data.stanford.edu/Walters/zw200wd8767/canvas/canvas-359#xywh=47,191,1036,1140"}'
        sign_in @user
      end

      it 'returns a 200 response' do
        post :create, JSON.parse(@annoString)
        @annotation = Annotation.last()
        annoUID = @annotation.annotation_id.split('annotations/').last
        get :show, {format: :json, id: annoUID}
        expect(response.status).to eq(200)
      end

      it 'retrieves motivation correctly' do
        post :create, JSON.parse(@annoString)
        @annotation = Annotation.last()
        annoUID = @annotation.annotation_id.split('annotations/').last
        get :show, {format: :json, id: annoUID}
        responseJSON = JSON.parse(response.body)
        expect(responseJSON['motivation']).to eq("yale:transcribing")
      end

      it 'does not fail if within is nil' do
        annoJSON = JSON.parse(@annoString)
        annoJSON['within'] = nil
        post :create, annoJSON
        @annotation = Annotation.last()
        annoUID = @annotation.annotation_id.split('annotations/').last
        get :show, {format: :json, id: annoUID}
        expect(response.status).to eq(200)
      end
      after(:each) do
        sign_out @user
      end
    end
  end


  context 'when Put is called' do
    describe 'Put annotation json' do
      before(:each) do
        @annoString ='{"annotation_id":"http://localhost:5000/annotations/testAnnotation",
                      "annotation_type": "oa:annotation",
                      "motivation": "yale:transcribing",
                      "within":["http://localhost:5000/lists/list1","http://localhost:5000/lists/list2"],
                      "resource":{"@type":"cnt:ContentAsText","chars":"transcription1 list 1 annotation 1 **","format":"text/plain"},
                      "annotatedBy":{"@id":"http://annotations.tenthousandrooms.yale.edu/user/5390bd85a42eedf8a4000001","@type":"prov:Agent","name":"Test User 8"},
                      "on":"http://dms-data.stanford.edu/Walters/zw200wd8767/canvas/canvas-359#xywh=47,191,1036,1140"}'
        @annotation = Annotation.create(JSON.parse(@annoString))
        @annoJSON = JSON.parse(@annoString)
        sign_in @user
      end

      describe 'abilities' do
        #ability = Ability.new(@user)
        #ability.should be_able_to(:read, Annotation)
        #subject(:ability) { Ability.new(@user) }
        #it {is_expected.not_to_be_able_to :read, Annotation}
      end

      it 'does not change the record count' do
        @annoJSON['motivation'] = 'yale:transliterating'
        expect { put :update, @annoJSON }.to change(Annotation, :count).by(0)
      end

      it 'returns a 200 response' do
        @annoJSON['motivation'] = 'yale:transliterating'
        put :update, @annoJSON, :format => 'json'
        expect(response.status).to eq(200)
      end

      it 'updates the motivation field' do
        @annoJSON['motivation'] = 'yale:transliterating'
        put :update, @annoJSON, :format => 'json'
        responseJSON = JSON.parse(response.body)
        expect(responseJSON['motivation']).to eq("yale:transliterating")
      end

      it 'fails validation correctly' do
        @annoJSON['motivation'] = nil
        put :update, @annoJSON, :format => 'json'
        expect(response.status).to eq(422)
      end

      it 'does not fail if  if [within] is blank' do
        @annoJSON['within'] = nil
        put :update, @annoJSON, :format => 'json'
        expect(response.status).to eq(200)
      end

      it 'updates the list_annotations map correctly'  do
        @annoJSON['motivation'] = 'yale:transliterating'
        put :update, @annoJSON, :format => 'json'
        @lists = ListAnnotationsMap.getListsForAnnotation @annotation.annotation_id
        expect(@lists).to eq(@annoJSON['within'])
      end

      it 'creates a version correctly' do
        @annoJSON['motivation'] = 'yale:transliterating'
        put :update, @annoJSON, :format => 'json'
        @annotation = Annotation.last()
        @version = AnnoListLayerVersion.last()
        expect(@annotation.version).to eq(2)
        expect(@version.all_id).to eq(@annotation.annotation_id)
        expect(@version.all_type).to eq("oa:annotation")
        expect(@version.all_version).to eq(@annotation.version-1)
      end
      after(:each) do
        sign_out @user
      end
    end
  end

  context 'when Delete is called' do
    describe 'Delete annotation' do
      before(:each) do
        @annoString =#'{"annotation_id":"http://test.host/annotations/testAnnotation",
                      '{"@type": "oa:annotation",
                      "motivation": "yale:transcribing",
                      "within":["http://localhost:5000/lists/list1","http://localhost:5000/lists/list2"],
                      "resource":{"@type":"cnt:ContentAsText","chars":"transcription1 list 1 annotation 1 **","format":"text/plain"},
                      "annotatedBy":{"@id":"http://annotations.tenthousandrooms.yale.edu/user/5390bd85a42eedf8a4000001","@type":"prov:Agent","name":"Test User 8"},
                      "on":"http://dms-data.stanford.edu/Walters/zw200wd8767/canvas/canvas-359#xywh=47,191,1036,1140"}'

        sign_in @user
        post :create, JSON.parse(@annoString)
        @annotation = Annotation.last()
        @aclDelete ='{"resource_id":"' + @annotation.annotation_id + '", "acl_mode": "delete", "group_id": "http://localhost:5000/groups/testGroup"}'
        #p @aclDelete.to_s
        @webAclDel = Webacl.create(JSON.parse(@aclDelete))
      end

      it 'returns a 201 ("created") response' do
        annoUID = @annotation.annotation_id.split('annotations/').last
        delete :destroy, format: :json, id: annoUID
        expect(response.status).to eq(204)
      end

      it 'decreases the Annotation record count' do
        annoUID = @annotation.annotation_id.split('annotations/').last
        expect {delete :destroy, {format: :json, id: annoUID} }.to change(Annotation, :count).by(-1)
      end

      it 'deletes the Annotation record' do
        annoUID = @annotation.annotation_id.split('annotations/').last
        delete :destroy, format: :json, id: annoUID
        expect(@annotationDeleted = Annotation.where(annotation_id: @annotation.annotation_id).first).to eq(nil)
      end

      it 'deletes the list_annotations map correctly' do
        annoUID = @annotation.annotation_id.split('annotations/').last
        delete :destroy, format: :json, id: annoUID
        @lists = ListAnnotationsMap.getListsForAnnotation @annotation.annotation_id
        expect(@lists).to eq([])
      end

      it 'creates a version correctly' do
        annoUID = @annotation.annotation_id.split('annotations/').last
        delete :destroy, format: :json, id: annoUID
        @version = AnnoListLayerVersion.last()
        expect(@annotation.version).to eq(1)
        expect(@version.all_id).to eq(@annotation.annotation_id)
        expect(@version.all_type).to eq("oa:annotation")
        expect(@version.all_version).to eq(@annotation.version)
      end

      after(:each) do
        sign_out @user
      end
    end
  end

  after(:each) do
    p 'destroying webAcl1'
    @webAcl1.destroy
    p 'destroyed webAcl1'
    @webAcl2.destroy
    @webAcl3.destroy
    @webAcl4.destroy
    p 'destroying webAcl5'
    @webAcl5.destroy
    @group.destroy
    @annotation_list1.destroy
    @annotation_list2.destroy
    p 'destroying user'
    @user.destroy
  end

end