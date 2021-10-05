import json

from google_semantic_location_history.get_faker_schema import get_json_schema, get_faker_schema


GSLH_JSON_SCHEMA = {
	'$schema': 'http://json-schema.org/schema#',
	'type': 'object',
	'properties': {
		'timelineObjects': {
			'type': 'array',
			'items': {
				'type': 'object',
				'properties': {
					'activitySegment': {
						'type': 'object',
						'properties': {
							'startLocation': {
								'type': 'object',
								'properties': {
									'latitudeE7': {
										'type': 'integer'
									},
									'longitudeE7': {
										'type': 'integer'
									}
								},
								'required': ['latitudeE7', 'longitudeE7']
							},
							'endLocation': {
								'type': 'object',
								'properties': {
									'latitudeE7': {
										'type': 'integer'
									},
									'longitudeE7': {
										'type': 'integer'
									}
								},
								'required': ['latitudeE7', 'longitudeE7']
							},
							'duration': {
								'type': 'object',
								'properties': {
									'startTimestampMs': {
										'type': 'string'
									},
									'endTimestampMs': {
										'type': 'string'
									},
									'activityType': {
										'type': 'string'
									}
								},
								'required': ['activityType', 'endTimestampMs', 'startTimestampMs']
							},
							'distance': {
								'type': 'integer'
							},
							'activityType': {
								'type': 'string'
							},
							'confidence': {
								'type': 'string'
							},
							'activities': {
								'type': 'array',
								'items': {
									'type': 'object',
									'properties': {
										'activityType': {
											'type': 'string'
										},
										'probability': {
											'type': 'number'
										}
									},
									'required': ['activityType', 'probability']
								}
							},
							'waypointPath': {
								'type': 'object',
								'properties': {
									'waypoints': {
										'type': 'array',
										'items': {
											'type': 'object',
											'properties': {
												'latE7': {
													'type': 'integer'
												},
												'lngE7': {
													'type': 'integer'
												}
											},
											'required': ['latE7', 'lngE7']
										}
									}
								},
								'required': ['waypoints']
							},
							'simplifiedRawPath': {
								'type': 'object',
								'properties': {
									'points': {
										'type': 'array',
										'items': {
											'type': 'object',
											'properties': {
												'latE7': {
													'type': 'integer'
												},
												'lngE7': {
													'type': 'integer'
												},
												'timestampMs': {
													'type': 'string'
												},
												'accuracyMeters': {
													'type': 'integer'
												}
											},
											'required': ['accuracyMeters', 'latE7', 'lngE7', 'timestampMs']
										}
									}
								},
								'required': ['points']
							},
							'transitPath': {
								'type': 'object',
								'properties': {
									'transitStops': {
										'type': 'array',
										'items': {
											'type': 'object',
											'properties': {
												'latitudeE7': {
													'type': 'integer'
												},
												'longitudeE7': {
													'type': 'integer'
												},
												'placeId': {
													'type': 'string'
												},
												'name': {
													'type': 'string'
												}
											},
											'required': ['latitudeE7', 'longitudeE7', 'name', 'placeId']
										}
									},
									'name': {
										'type': 'string'
									},
									'hexRgbColor': {
										'type': 'string'
									}
								},
								'required': ['hexRgbColor', 'name', 'transitStops']
							}
						},
						'required': ['activities', 'activityType', 'confidence', 'distance', 'duration', 'endLocation', 'simplifiedRawPath', 'startLocation', 'transitPath', 'waypointPath']
					},
					'placeVisit': {
						'type': 'object',
						'properties': {
							'location': {
								'type': 'object',
								'properties': {
									'latitudeE7': {
										'type': 'integer'
									},
									'longitudeE7': {
										'type': 'integer'
									},
									'placeId': {
										'type': 'string'
									},
									'address': {
										'type': 'string'
									},
									'name': {
										'type': 'string'
									},
									'sourceInfo': {
										'type': 'object',
										'properties': {
											'deviceTag': {
												'type': 'integer'
											}
										},
										'required': ['deviceTag']
									},
									'locationConfidence': {
										'type': 'number'
									},
									'semanticType': {
										'type': 'string'
									}
								},
								'required': ['address', 'latitudeE7', 'locationConfidence', 'longitudeE7', 'name', 'placeId', 'semanticType', 'sourceInfo']
							},
							'duration': {
								'type': 'object',
								'properties': {
									'startTimestampMs': {
										'type': 'string'
									},
									'endTimestampMs': {
										'type': 'string'
									}
								},
								'required': ['endTimestampMs', 'startTimestampMs']
							},
							'placeConfidence': {
								'type': 'string'
							},
							'centerLatE7': {
								'type': 'integer'
							},
							'centerLngE7': {
								'type': 'integer'
							},
							'visitConfidence': {
								'type': 'integer'
							},
							'otherCandidateLocations': {
								'type': 'array',
								'items': {
									'type': 'object',
									'properties': {
										'latitudeE7': {
											'type': 'integer'
										},
										'longitudeE7': {
											'type': 'integer'
										},
										'placeId': {
											'type': 'string'
										},
										'locationConfidence': {
											'type': 'number'
										},
										'semanticType': {
											'type': 'string'
										}
									},
									'required': ['latitudeE7', 'locationConfidence', 'longitudeE7', 'placeId', 'semanticType']
								}
							},
							'editConfirmationStatus': {
								'type': 'string'
							},
							'childVisits': {
								'type': 'array',
								'items': {
									'type': 'object',
									'properties': {
										'location': {
											'type': 'object',
											'properties': {
												'latitudeE7': {
													'type': 'integer'
												},
												'longitudeE7': {
													'type': 'integer'
												},
												'placeId': {
													'type': 'string'
												},
												'address': {
													'type': 'string'
												},
												'name': {
													'type': 'string'
												},
												'sourceInfo': {
													'type': 'object',
													'properties': {
														'deviceTag': {
															'type': 'integer'
														}
													},
													'required': ['deviceTag']
												},
												'locationConfidence': {
													'type': 'number'
												}
											},
											'required': ['address', 'latitudeE7', 'locationConfidence', 'longitudeE7', 'name', 'placeId', 'sourceInfo']
										},
										'duration': {
											'type': 'object',
											'properties': {
												'startTimestampMs': {
													'type': 'string'
												},
												'endTimestampMs': {
													'type': 'string'
												}
											},
											'required': ['endTimestampMs', 'startTimestampMs']
										},
										'placeConfidence': {
											'type': 'string'
										},
										'centerLatE7': {
											'type': 'integer'
										},
										'centerLngE7': {
											'type': 'integer'
										},
										'visitConfidence': {
											'type': 'integer'
										},
										'otherCandidateLocations': {
											'type': 'array',
											'items': {
												'type': 'object',
												'properties': {
													'latitudeE7': {
														'type': 'integer'
													},
													'longitudeE7': {
														'type': 'integer'
													},
													'placeId': {
														'type': 'string'
													},
													'locationConfidence': {
														'type': 'number'
													}
												},
												'required': ['latitudeE7', 'locationConfidence', 'longitudeE7', 'placeId']
											}
										},
										'editConfirmationStatus': {
											'type': 'string'
										}
									},
									'required': ['centerLatE7', 'centerLngE7', 'duration', 'editConfirmationStatus', 'location', 'otherCandidateLocations', 'placeConfidence', 'visitConfidence']
								}
							},
							'simplifiedRawPath': {
								'type': 'object',
								'properties': {
									'points': {
										'type': 'array',
										'items': {
											'type': 'object',
											'properties': {
												'latE7': {
													'type': 'integer'
												},
												'lngE7': {
													'type': 'integer'
												},
												'timestampMs': {
													'type': 'string'
												},
												'accuracyMeters': {
													'type': 'integer'
												}
											},
											'required': ['accuracyMeters', 'latE7', 'lngE7', 'timestampMs']
										}
									}
								},
								'required': ['points']
							}
						},
						'required': ['centerLatE7', 'centerLngE7', 'childVisits', 'duration', 'editConfirmationStatus', 'location', 'otherCandidateLocations', 'placeConfidence', 'simplifiedRawPath', 'visitConfidence']
					}
				},
				'required': ['activitySegment', 'placeVisit']
			}
		}
	},
	'required': ['timelineObjects']
}

GSLH_FAKER_SCHEMA = {
	'timelineObjects': [{
		'activitySegment': {
			'startLocation': {
				'latitudeE7': 'pyint',
				'longitudeE7': 'pyint'
			},
			'endLocation': {
				'latitudeE7': 'pyint',
				'longitudeE7': 'pyint'
			},
			'duration': {
				'startTimestampMs': 'pystr',
				'endTimestampMs': 'pystr',
				'activityType': 'pystr'
			},
			'distance': 'pyint',
			'activityType': 'pystr',
			'confidence': 'pystr',
			'activities': [{
				'activityType': 'pystr',
				'probability': 'pyfloat'
			}],
			'waypointPath': {
				'waypoints': [{
					'latE7': 'pyint',
					'lngE7': 'pyint'
				}]
			},
			'simplifiedRawPath': {
				'points': [{
					'latE7': 'pyint',
					'lngE7': 'pyint',
					'timestampMs': 'pystr',
					'accuracyMeters': 'pyint'
				}]
			},
			'transitPath': {
				'transitStops': [{
					'latitudeE7': 'pyint',
					'longitudeE7': 'pyint',
					'placeId': 'pystr',
					'name': 'pystr'
				}],
				'name': 'pystr',
				'hexRgbColor': 'pystr'
			}
		},
		'placeVisit': {
			'location': {
				'latitudeE7': 'pyint',
				'longitudeE7': 'pyint',
				'placeId': 'pystr',
				'address': 'pystr',
				'name': 'pystr',
				'sourceInfo': {
					'deviceTag': 'pyint'
				},
				'locationConfidence': 'pyfloat',
				'semanticType': 'pystr'
			},
			'duration': {
				'startTimestampMs': 'pystr',
				'endTimestampMs': 'pystr'
			},
			'placeConfidence': 'pystr',
			'centerLatE7': 'pyint',
			'centerLngE7': 'pyint',
			'visitConfidence': 'pyint',
			'otherCandidateLocations': [{
				'latitudeE7': 'pyint',
				'longitudeE7': 'pyint',
				'placeId': 'pystr',
				'locationConfidence': 'pyfloat',
				'semanticType': 'pystr'
			}],
			'editConfirmationStatus': 'pystr',
			'childVisits': [{
				'location': {
					'latitudeE7': 'pyint',
					'longitudeE7': 'pyint',
					'placeId': 'pystr',
					'address': 'pystr',
					'name': 'pystr',
					'sourceInfo': {
						'deviceTag': 'pyint'
					},
					'locationConfidence': 'pyfloat'
				},
				'duration': {
					'startTimestampMs': 'pystr',
					'endTimestampMs': 'pystr'
				},
				'placeConfidence': 'pystr',
				'centerLatE7': 'pyint',
				'centerLngE7': 'pyint',
				'visitConfidence': 'pyint',
				'otherCandidateLocations': [{
					'latitudeE7': 'pyint',
					'longitudeE7': 'pyint',
					'placeId': 'pystr',
					'locationConfidence': 'pyfloat'
				}],
				'editConfirmationStatus': 'pystr'
			}],
			'simplifiedRawPath': {
				'points': [{
					'latE7': 'pyint',
					'lngE7': 'pyint',
					'timestampMs': 'pystr',
					'accuracyMeters': 'pyint'
				}]
			}
		}
	}]
}


def test_get_json_schema():
    json_file = "tests/data/2021_JANUARY.json"
    with open(json_file) as file_object:
        json_data = json.load(file_object)
        json_schema = get_json_schema(json_data)
    assert json_schema == GSLH_JSON_SCHEMA


def test_get_faker_schema():
    schema = get_faker_schema(GSLH_JSON_SCHEMA["properties"])
    assert schema == GSLH_FAKER_SCHEMA