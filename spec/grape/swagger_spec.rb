require 'spec_helper'
require 'grape_entity'
require 'grape/swagger_v2'

describe Grape::SwaggerV2 do

  expected_swagger_doc = <<-JSON
    {
      "swagger": "2.0",
      "info": {
        "title": "TestApi",
        "description": "This is an auto-generated documentation for the TestApi grape API.",
        "version": "v1"
      },
      "schemes": [
        "http"
      ],
      "consumes": [
        "application/json"
      ],
      "produces": [
        "application/json"
      ],
      "paths": {
        "/v1/pet":{
          "post":{
            "summary":"Add a new pet to the store",
            "parameters":[
              {
                "name":"pet_name",
                "in":"body",
                "description":"The pets name",
                "required":true,
                "type":"string",
                "default":"Touffi"
              },
              {
                "name":"pet_race",
                "in":"body",
                "description":"Pet race",
                "required":true,
                "type":"string",
                "enum":[
                  "dog",
                  "cat",
                  "turtle"
                ]
              },
              {
                "name":"owner_id",
                "in":"body",
                "description":"Owner ID",
                "required":true,
                "type":"integer",
                "format":"int64"
              }
            ],
            "responses":{
              "200":{
                "description":"successful operation",
                "schema":{
                  "$ref":"#/definitions/Pet"
                }
              }
            }
          }
        },
        "/v1/pet/{pet_id}":{
          "get":{
            "summary":"Find pet by ID",
            "parameters":[
              {
                "name":"pet_id",
                "in":"path",
                "description":"ID of pet to return",
                "required":true,
                "type":"integer",
                "format":"int64"
              }
            ],
            "responses":{
              "200":{
                "description":"successful operation",
                "schema":{
                  "$ref":"#/definitions/Pet"
                }
              }
            }
          }
        },
        "/v1/pets":{
          "get":{
            "summary":"Search for pets",
            "parameters":[
              {
                "name":"owner_id",
                "in":"query",
                "description":"The owners id",
                "required":false,
                "type":"integer",
                "format":"int64"
              },
              {
                "name":"only_available",
                "in":"query",
                "description":"Filter out adopted animals",
                "required":false,
                "type":"boolean"
              }
            ],
            "responses":{
              "200":{
                "description":"successful operation",
                "schema":{
                  "type":"array",
                  "items":{
                    "$ref":"#/definitions/Pet"
                  }
                }
              }
            }
          }
        }
      },
      "definitions": {
        "Pet":{
          "properties":{
            "id":{
              "type":"integer",
              "description":"Pet ID",
              "format":"int64"
            },
            "pet_name":{
              "type":"string",
              "description":"Pet name"
            },
            "pet_race":{
              "type":"string",
              "description":"The pets race"
            },
            "owner_id":{
              "type":"integer",
              "description":"Owner ID",
              "format":"int64"
            }
          }
        }
      }
    }
  JSON

  class Pet < Grape::Entity
    expose :id, documentation: { type: 'Integer', desc: 'Pet ID' }
    expose :pet_name, documentation: { type: 'String', desc: 'Pet name' }
    expose :pet_race, documentation: { type: 'String', desc: 'The pets race' }
    expose :owner_id, documentation: { type: 'Integer', desc: 'Owner ID' }
  end

  class TestApi < Grape::API

    extend Grape::SwaggerV2

    version 'v1'

    desc "Add a new pet to the store" do
     success Pet
    end
    params do
      requires :pet_name, type: String, desc: 'The pets name', default: 'Touffi'
      requires :pet_race, type: Symbol, desc: 'Pet race', values: [:dog, :cat, :turtle]
      requires :owner_id, type: Integer, desc: 'Owner ID'
    end
    post '/pet' do
      # ...
    end


    desc "Find pet by ID" do
      success Pet
    end
    params do
      requires :pet_id, type: Integer, desc: 'ID of pet to return'
    end
    get '/pet/:pet_id' do
      # ...
    end


    desc "Search for pets" do
      success [Pet]
    end
    params do
      optional :owner_id, type: Integer, desc: 'The owners id'
      optional :only_available, type: Boolean, desc: 'Filter out adopted animals', default: false
    end
    get '/pets' do
      # ...
    end

  end


  let(:expected) { JSON.parse(expected_swagger_doc) }
  let(:actual) { JSON.parse(TestApi.swagger_doc.to_json) }


  it 'should have the same paths' do
    actual['paths'].keys.should == expected['paths'].keys

    actual['paths'].each do |key, path|
      path.should == expected['paths'][key]
    end
  end


  it 'should have the samedocumentation' do
    actual.should == expected
  end

end
