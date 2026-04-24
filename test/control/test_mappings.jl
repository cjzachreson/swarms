using SoundSwarms

function test_map_features_to_parameters_maps_speed_and_noise()
     base_params = SwarmParameters(1.0, 4.0, 0.1, 10.0, 10.0)
     mapping = FeatureParameterMapping(0.5, 3.0, 0.1, 0.9)
     frame = AudioFeatureFrame(0.0, 0.5, 0.0, 0.0, 0.25, 0.0, 0.0)

     params = map_features_to_parameters(base_params, frame, mapping, 1.0)

     @test params.speed == 1.75
     @test params.alignment_radius == base_params.alignment_radius
     @test params.noise_strength ≈ 0.3
     @test params.domain_width == base_params.domain_width
     @test params.domain_height == base_params.domain_height
end

function test_map_features_to_parameters_bounds_speed_by_alignment_radius()
     base_params = SwarmParameters(1.0, 2.0, 0.1, 10.0, 10.0)
     mapping = FeatureParameterMapping(1.0, 10.0, 0.1, 0.9)
     frame = AudioFeatureFrame(0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0)

     params = map_features_to_parameters(base_params, frame, mapping, 0.5)

     @test params.speed == 4.0
     @test params.speed * 0.5 <= base_params.alignment_radius
end

function test_feature_parameter_mapping_validation()
     @test_throws ArgumentError FeatureParameterMapping(-0.1, 1.0, 0.0, 1.0)
     @test_throws ArgumentError FeatureParameterMapping(1.0, 0.5, 0.0, 1.0)
     @test_throws ArgumentError FeatureParameterMapping(0.0, 1.0, -0.1, 1.0)
     @test_throws ArgumentError FeatureParameterMapping(0.0, 1.0, 1.0, 0.5)
     @test_throws ArgumentError FeatureParameterMapping(0.0, 1.0, 0.0, 1.0; speed_feature = :not_a_feature)
end

function test_map_features_to_parameters_validates_dt()
     base_params = SwarmParameters(1.0, 4.0, 0.1, 10.0, 10.0)
     mapping = FeatureParameterMapping(0.5, 3.0, 0.1, 0.9)
     frame = AudioFeatureFrame(0.0, 0.5, 0.0, 0.0, 0.25, 0.0, 0.0)

     @test_throws ArgumentError map_features_to_parameters(base_params, frame, mapping, 0.0)
end

@testset "Feature parameter mapping" begin
     test_map_features_to_parameters_maps_speed_and_noise()
     test_map_features_to_parameters_bounds_speed_by_alignment_radius()
     test_feature_parameter_mapping_validation()
     test_map_features_to_parameters_validates_dt()
end
