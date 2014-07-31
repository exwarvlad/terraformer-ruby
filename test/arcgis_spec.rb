require_relative './helper'

describe Terraformer::ArcGIS do

  describe 'geometry decompressor' do

    it 'decompresses geometries' do
      compressed = "+1m91-6fl6e+202gc+0+0"
      decompressed_points = [
        [-122.41946568318791, 37.775011244040655],
        [-122.41946568318791, 37.775011244040655]
      ]
      Terraformer::ArcGIS.decompress_geometry(compressed).must_equal decompressed_points
    end

  end

  describe 'close_ring' do

    let(:closed_ring) {[
        [-107.5341796875,46.195042108660154],
        [-105.84228515625,46.58906908309182],
        [-104.7216796875,45.85941212790755],
        [-104.52392578125,44.213709909702054],
        [-106.083984375,43.46886761482923],
        [-107.8857421875,43.77109381775648],
        [-109.2919921875,44.99588261816546],
        [-107.5341796875,46.195042108660154]
      ]
    }
    let(:open_ring) {[
        [-107.5341796875,46.195042108660154],
        [-105.84228515625,46.58906908309182],
        [-104.7216796875,45.85941212790755],
        [-104.52392578125,44.213709909702054],
        [-106.083984375,43.46886761482923],
        [-107.8857421875,43.77109381775648],
        [-109.2919921875,44.99588261816546]
      ]
    }

    it 'closes open rings' do
      r = Terraformer::ArcGIS.close_ring open_ring
      r.must_equal closed_ring
    end

    it 'does nothing with closed rings' do
      r = Terraformer::ArcGIS.close_ring closed_ring
      r.must_equal closed_ring
    end

  end

  describe 'clockwise_ring?' do

    let(:cw_ring) {[
        [-107.5341796875,46.195042108660154],
        [-105.84228515625,46.58906908309182],
        [-104.7216796875,45.85941212790755],
        [-104.52392578125,44.213709909702054],
        [-106.083984375,43.46886761482923],
        [-107.8857421875,43.77109381775648],
        [-109.2919921875,44.99588261816546],
        [-107.5341796875,46.195042108660154]
      ]
    }
    let(:ccw_ring) {[
        [-107.5341796875,46.195042108660154],
        [-109.2919921875,44.99588261816546],
        [-107.8857421875,43.77109381775648],
        [-106.083984375,43.46886761482923],
        [-104.52392578125,44.213709909702054],
        [-104.7216796875,45.85941212790755],
        [-105.84228515625,46.58906908309182],
        [-107.5341796875,46.195042108660154]
      ]
    }

    it 'is true for rings that are clockwise' do
      assert Terraformer::ArcGIS.clockwise?(cw_ring)
    end

    it 'is false for rings that are counter-clockwise' do
      assert !Terraformer::ArcGIS.clockwise?(ccw_ring)
    end

  end

  describe 'parse' do

    def must_parse json, expected_class, *expected_init_data
      if block_given?
        output = if Hash === expected_init_data[0]
          Terraformer::ArcGIS.parse json, expected_init_data[0]
        else
          Terraformer::ArcGIS.parse json
        end
        output.must_be_instance_of expected_class
        output.must_equal yield(output)
      else
        output = Terraformer::ArcGIS.parse json
        output.must_be_instance_of expected_class
        output.must_equal expected_class.new *expected_init_data
      end
    end

    it 'parses arcgis points' do
      must_parse '{
        "x": -66.796875,
        "y": 20.0390625,
        "spatialReference": {
          "wkid": 4326
        }
      }', Terraformer::Point, -66.796875, 20.0390625
    end

    it 'parses arcgis points with Z' do
      must_parse '{
        "x": -66.796875,
        "y": 20.0390625,
        "z": 100,
        "spatialReference": {
          "wkid": 4326
        }
      }', Terraformer::Point, -66.796875, 20.0390625, 100
    end

    it 'parses null island arcgis' do
      must_parse '{
        "x": 0,
        "y": 0,
        "spatialReference": {
          "wkid": 4326
        }
      }', Terraformer::Point, 0, 0
    end

    it 'parses arcgis polyline into linestring' do
      must_parse '{
        "paths": [
          [ [6.6796875,47.8125],[-65.390625,52.3828125],[-52.3828125,42.5390625] ]
        ],
        "spatialReference": {
          "wkid": 4326
        }
      }', Terraformer::LineString, [
        [6.6796875,47.8125],[-65.390625,52.3828125],[-52.3828125,42.5390625]
      ]
    end

    it 'parses arcgis polygon' do
      must_parse '{
        "rings": [
          [ [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625] ]
        ],
        "spatialReference": {
          "wkid": 4326
        }
      }', Terraformer::Polygon, [
        [[41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625]]
      ]
    end

    it 'closes rings when parsing arcgis polygon' do
      must_parse '{
        "rings": [
          [ [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625] ]
        ],
        "spatialReference": {
          "wkid": 4326
        }
      }', Terraformer::Polygon, [
        [[41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625]]
      ]
    end

    it 'parses arcgis multipoint' do
      must_parse '{
        "points": [ [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625] ],
        "spatialReference": {
          "wkid": 4326
        }
      }', Terraformer::MultiPoint, [
        [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625]
      ]
    end

    it 'parses arcgis polyline into multilinestring' do
      must_parse '{
        "paths": [
          [ [41.8359375,71.015625],[56.953125,33.75] ],
          [ [21.796875,36.5625],[41.8359375,71.015625] ]
        ],
        "spatialReference": {
          "wkid": 4326
        }
      }', Terraformer::MultiLineString, [
        [[41.8359375,71.015625],[56.953125,33.75] ],
        [[21.796875,36.5625],[41.8359375,71.015625]]
      ]
    end

    it 'parses arcgis polygon into multipolygon' do
      must_parse '{
        "rings":[
          [[-122.63,45.52],[-122.57,45.53],[-122.52,45.50],[-122.49,45.48],[-122.64,45.49],[-122.63,45.52],[-122.63,45.52]],
          [[-83,35],[-74,35],[-74,41],[-83,41],[-83,35]]
        ],
        "spatialReference": {
          "wkid":4326
        }
      }', Terraformer::MultiPolygon,[
        [[[-122.63,45.52],[-122.57,45.53],[-122.52,45.5],[-122.49,45.48],[-122.64,45.49],[-122.63,45.52],[-122.63,45.52]]],
        [[[-83,35],[-83,41],[-74,41],[-74,35],[-83,35]]]
      ]
    end

    it 'strips invalid rings when parsing arcgis polygon' do
      must_parse '{
        "rings":[
          [[-122.63,45.52],[-122.57,45.53],[-122.52,45.50],[-122.49,45.48],[-122.64,45.49],
          [-122.63,45.52],[-122.63,45.52]],
          [[-83,35],[-74,35],[-83,35]] // closed but too small
        ],
        "spatialReference": {
          "wkid":4326
        }
      }', Terraformer::Polygon, [[[-122.63,45.52],[-122.57,45.53],[-122.52,45.5],[-122.49,45.48],[-122.64,45.49],[-122.63,45.52],[-122.63,45.52]]]
    end

    it 'closes rings when parsing arcgis polygon' do
      must_parse '{
        "rings":[
          [[-122.63,45.52],[-122.57,45.53],[-122.52,45.50],[-122.49,45.48],[-122.64,45.49]],
          [[-83,35],[-74,35],[-74,41],[-83,41]]
        ],
        "spatialReference": {
          "wkid":4326
        }
      }', Terraformer::MultiPolygon, [
        [
          [[-122.63,45.52],[-122.57,45.53],[-122.52,45.5],[-122.49,45.48],[-122.64,45.49],[-122.63,45.52]]
        ],
        [
          [[-83,35],[-83,41],[-74,41],[-74,35],[-83,35]]
        ]
      ]
    end

    it 'parses arcgis multipolygon with holes' do
      must_parse '{
        "type":"polygon",
        "rings":[
          [
            [-100.74462180954974,39.95017165502381],
            [-94.50439384003792,39.91647453608879],
            [-94.41650267263967,34.89313438177965],
            [-100.78856739324887,34.85708140996771],
            [-100.74462180954974,39.95017165502381]
          ],
          [
            [-99.68993678392353,39.341088433448896],
            [-99.68993678392353,38.24507658785885],
            [-98.67919734199646,37.86444431771113],
            [-98.06395917020868,38.210554846669694],
            [-98.06395917020868,39.341088433448896],
            [-99.68993678392353,39.341088433448896]
          ],
          [
            [-96.83349180978595,37.23732027507514],
            [-97.31689323047635,35.967330282988534],
            [-96.5698183075912,35.57512048069255],
            [-95.42724211456674,36.357601429255965],
            [-96.83349180978595,37.23732027507514]
          ],
          [
            [-101.4916967324349,38.24507658785885],
            [-101.44775114873578,36.073960493943744],
            [-103.95263145328033,36.03843312329154],
            [-103.68895795108557,38.03770050767439],
            [-101.4916967324349,38.24507658785885]
          ]
        ],
        "spatialReference":{
          "wkid":4326
        }
      }', Terraformer::MultiPolygon, [
        [
          [
            [-100.74462180954974, 39.95017165502381],
            [-94.50439384003792, 39.91647453608879],
            [-94.41650267263967, 34.89313438177965],
            [-100.78856739324887, 34.85708140996771],
            [-100.74462180954974, 39.95017165502381]
          ],
          [
            [-96.83349180978595, 37.23732027507514],
            [-97.31689323047635, 35.967330282988534],
            [-96.5698183075912, 35.57512048069255],
            [-95.42724211456674, 36.357601429255965],
            [-96.83349180978595, 37.23732027507514]
          ],
          [
            [-99.68993678392353, 39.341088433448896],
            [-99.68993678392353, 38.24507658785885],
            [-98.67919734199646, 37.86444431771113],
            [-98.06395917020868, 38.210554846669694],
            [-98.06395917020868, 39.341088433448896],
            [-99.68993678392353, 39.341088433448896]
          ]
        ],
        [
          [
            [-101.4916967324349, 38.24507658785885],
            [-101.44775114873578, 36.073960493943744],
            [-103.95263145328033, 36.03843312329154],
            [-103.68895795108557, 38.03770050767439],
            [-101.4916967324349, 38.24507658785885]
          ]
        ]
      ]
    end

    it 'parses arcgis features' do
      must_parse '{
        "geometry": {
          "rings": [
            [ [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625] ]
          ],
          "spatialReference": {
            "wkid": 4326
          }
        },
        "attributes": {
          "foo": "bar"
        }
      }', Terraformer::Feature do |output|
        p = Terraformer::Polygon.new [[
          [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625]
        ]]
        output.geometry.must_equal p
        f = p.to_feature
        f.properties['foo'] = 'bar'
        f.id = nil
        f
      end
    end

    it 'parses arcgis features with objectid' do
      must_parse '{
        "geometry": {
          "rings": [
            [ [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625] ]
          ],
          "spatialReference": {
            "wkid": 4326
          }
        },
        "attributes": {
          "OBJECTID": 123
        }
      }', Terraformer::Feature do |output|
        p = Terraformer::Polygon.new [[
          [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625]
        ]]
        output.geometry.must_equal p
        f = p.to_feature
        f.id = 123
        f
      end
    end

    it 'parses arcgis features with fid' do
      must_parse '{
        "geometry": {
          "rings": [
            [ [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625] ]
          ],
          "spatialReference": {
            "wkid": 4326
          }
        },
        "attributes": {
          "FID": 123
        }
      }', Terraformer::Feature do |output|
        p = Terraformer::Polygon.new [[
          [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625]
        ]]
        output.geometry.must_equal p
        f = p.to_feature
        f.id = 123
        f
      end
    end

    it 'parses arcgis features with custom id' do
      must_parse '{
        "geometry": {
          "rings": [
            [ [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625] ]
          ],
          "spatialReference": {
            "wkid": 4326
          }
        },
        "attributes": {
          "FooId": 123
        }
      }', Terraformer::Feature, {id_attribute: 'FooId'} do |output|
        p = Terraformer::Polygon.new [[
          [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625]
        ]]
        output.geometry.must_equal p
        f = p.to_feature
        f.id = 123
        f
      end
    end

    it 'parses arcgis features with empty attributes' do
      must_parse '{
        "geometry": {
          "rings": [
            [ [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625] ]
          ],
          "spatialReference": {
            "wkid": 4326
          }
        },
        "attributes": {}
      }', Terraformer::Feature do |output|
        p = Terraformer::Polygon.new [[
          [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625]
        ]]
        output.geometry.must_equal p
        f = p.to_feature
        f.id = nil
        f
      end
    end

    it 'parses arcgis features with no attributes' do
      must_parse '{
        "geometry": {
          "rings": [
            [ [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625] ]
          ],
          "spatialReference": {
            "wkid": 4326
          }
        }
      }', Terraformer::Feature do |output|
        p = Terraformer::Polygon.new [[
          [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625]
        ]]
        output.geometry.must_equal p
        f = p.to_feature
        f.id = nil
        f
      end
    end

    it 'parses arcgis features with no geometry' do
      must_parse '{
        "attributes": {
          "foo": "bar"
        }
      }', Terraformer::Feature do |output|
        f = Terraformer::Feature.new
        f.properties = {'foo' => 'bar'}
        f.id = nil
        f
      end
    end

    it 'parses arcgis geometry in web mercator' do
      must_parse '{
        "x": -13580977.876779145,
        "y": 5621521.486191948,
        "spatialReference": {
          "wkid": 102100
        }
      }', Terraformer::Point, [-121.999999999998, 44.99999999999942]
    end

    it 'does not modify arcgis data while parsing' do
      input = {
        "geometry" => {
          "rings" => [
            [ [41.8359375,71.015625],[56.953125,33.75],[21.796875,36.5625],[41.8359375,71.015625] ]
          ],
          "spatialReference" => {
            "wkid" => 4326
          }
        },
        "attributes" => {
          "foo" => "bar"
        }
      }
      original = input.clone
      Terraformer::ArcGIS.parse input
      original.must_equal input
    end

    it 'decompresses arcgis compressed geometry' do
      must_parse '{
        "compressedGeometry": "+1m91-66os4+1poms+1+91+3+3j"
      }', Terraformer::Feature do |output|
        ls = Terraformer::LineString.new [
          [-117.1816137447153, 34.057461545380946],[-117.18159575425025, 34.06266078978142], [-117.18154178285509, 34.06472969326257]
        ]
        output.geometry.must_equal ls
        f = ls.to_feature
        f
      end
    end

  end

end
