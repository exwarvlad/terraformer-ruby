module Terraformer

  class Feature < Primitive
    extend Forwardable

    attr_accessor :id, :geometry, :crs
    attr_writer :properties

    def_delegator :@geometry, :convex_hull

    def initialize *args
      unless args.empty?
        super *args do |arg|
          self.id = arg['id'] if arg.key? 'id'
          self.properties = arg['properties'] if arg.key? 'properties'
          self.geometry = Terraformer.parse arg['geometry'] if arg['geometry']
        end
      end
    end

    def properties
      @properties ||= {}
    end

    def to_hash *args
      h = {
        type: type,
        properties: properties,
      }
      h[:geometry] = geometry.to_hash(*args) if geometry
      h[:id] = id if id
      h
    end

    def great_circle_distance other
      other = other.geometry if Feature === other
      self.geometry.great_circle_distance other
    end

    def geojson_io
      Terraformer.geojson_io self
    end

    def == obj
      return false unless Feature === obj
      to_hash == obj.to_hash
    end

  end

  class FeatureCollection < Primitive

    attr_accessor :crs
    attr_writer :features

    def self.with_features *f
      raise ArgumentError unless f.all? {|e| Feature === e}
      fc = FeatureCollection.new
      fc.features = f
      fc
    end

    def initialize *args
      unless args.empty?
        super *args do |arg|
          self.features = arg['features'].map {|f| Terraformer.parse f unless Primitive === f}
        end
      end
    end

    def features
      @features ||= []
    end

    def << feature
      raise ArgumentError unless Feature === feature
      features << feature
    end

    def to_hash *args
      h = {
        type: type,
        features: features.map {|f| f.to_hash *args}
      }
      h[:crs] = crs if crs
      h
    end

    def == obj
      return false unless FeatureCollection === obj
      to_hash == obj.to_hash
    end

    def convex_hull
      ConvexHull.for features.map(&:geometry).map(&:coordinates)
    end

    def geojson_io
      Terraformer.geojson_io self
    end

  end

end
