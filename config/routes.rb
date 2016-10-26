#TenThousandRooms::Application.routes.draw do
MiradorAnnotationsServer::Application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks"}

  #get "welcome/index"
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  root 'annotation_layers#index'
  resources :annotation_layers, path: 'layers',defaults: {format: :json}
  resources :annotation_lists, path: 'lists',defaults: {format: :json}
  get '/lists/*url' => 'annotation_lists#show', :format => false
  resources :annotation_lists, path: 'lists', :format => false
  #get '/annotations/*url' => 'annotation_lists#show', :format => false
  resources :annotations, path: 'annotations',defaults: {format: :json}, :except => [:update]
  put '/annotations', to: 'annotations#update'

  #get '/getAll', to: 'services#getAllCanvasesLayersLists'
  get '/getCanvasData', to: 'services#getLayersListsForCanvas'
  get '/getAnnotations', to: 'annotations#getAnnotationsForCanvas'
  get '/getAnnotationsViaList', to: 'annotations#getAnnotationsForCanvasViaLists'
  get '/resequenceList', to: 'annotation_lists#resequence_list'
  put '/resequenceList', to: 'annotation_lists#resequence_list'
  get '/getSvg', to: 'annotations#getSvg', defaults: {format: :json}
  put '/updateSvg', to: 'annotations#updateSvg', defaults: {format: :json}
  get '/getCanvasForAnno', to: 'annotations#getTargetingAnnosCanvasFromID', defaults: {format: :json}
  get '/getLayersForAnnotation', to: 'annotations#getLayersForAnnotation', defaults: {format: :json}

  get '/getSolrFeed', to: 'annotations#getAnnotationsForSolrFeed',  defaults: {format: :json}
  get '/feedAllAnnoIds', to: 'annotations#feedAllAnnoIds', defaults: {format: :text}
  get '/feedAllLayers', to: 'annotations#feedAllLayers', defaults: {format: :text}
  get '/feedAnnosNoResource', to: 'annotations#feedAnnosNoResource', defaults: {format: :text}
  get '/feedAnnosResourceOnly', to: 'annotations#feedAnnosResourceOnly', defaults: {format: :text}

  get 'getAccessToken', to: "application#get_access_token", defaults: {format: :json}
  #get 'loginToServer', to: "application#login"
  get 'loginToServer', to: "authn#userLogin"
  #put 'loginToServer', to: "authn#userLogin"

  match '/' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'getAccessToken' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'getAnnotations' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'getAnnotations' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'annotations' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'annotations/*all' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'lists' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'layers' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'getAnnotationsViaList' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
  match 'resequenceList' => 'application#CORS_preflight', via: [:options], defaults: {format: :json}
end
