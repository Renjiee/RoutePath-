# RoutePath-
## (高德地图)根据定位点绘制路线+轨迹纠偏
轨迹纠偏的作用就是去掉绘制路线时候两个定位点之间产生的毛刺和尖角，使路线看起来更加的圆滑，正常
![效果图][image-1]
	- (void) DrawLine{
	
	CLLocationCoordinate2D coordinate;
	
	CLLocation *location;
	
	NSMutableArray * array = [NSMutableArray array];
	
	for (int i = 0; i < self.locations.count; i++) {
	
	coordinate.latitude = [self.latitudes[i] floatValue];
	
	coordinate.longitude = [self.longitudes[i] floatValue];
	
	location = [[CLLocation alloc]initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
	
	[self.tempTraceLocations addObject:location];
	
	[array addObject:location];
	
	}
	
	}
	
	-  (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay
	
	{
	
	 if ([overlay isKindOfClass:[MAPolyline class]])
	
	{
	
	 MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
	
	 polylineRenderer.lineWidth    = 4.0f;
	
	 polylineRenderer.strokeColor  = KMainColor;
	
	 polylineRenderer.lineJoinType = kMALineJoinRound;
	
	 polylineRenderer.lineCapType  = kMALineCapRound;
	
	 return polylineRenderer;
	
	}
	
	 return nil;
	}

[image-1]:	https://ooo.0o0.ooo/2017/06/21/594a33c7e4f8f.png