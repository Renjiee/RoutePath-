//
//  ViewController.m
//  RoutePath
//
//  Created by ChangRJey on 2017/6/21.
//  Copyright © 2017年 RenJiee. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import "MANaviAnnotation.h"

static const NSString *RoutePlanningViewControllerStartTitle       = @"起点";
static const NSString *RoutePlanningViewControllerDestinationTitle = @"终点";

/** 屏幕的SIZE */
#define SCREEN_SIZE [[UIScreen mainScreen] bounds].size
/** define:屏幕的宽高比 */
#define CURRENT_SIZE(_size) _size / 375.0 * SCREEN_SIZE.width

@interface ViewController ()<MAMapViewDelegate>

@property (nonatomic, strong) MAMapView * mapView;

/** 轨迹纠偏 */
@property (nonatomic, strong) MATraceManager * traceManager;

//@property (nonatomic, strong) NSMutableArray * locations;///<定位坐标

@property (nonatomic, strong) NSArray * latitudes;///<纬度
@property (nonatomic, strong) NSArray * longitudes;///<经度

/* 起点经纬度. */
@property (nonatomic) CLLocationCoordinate2D                              startCoordinate;
/* 终点经纬度. */
@property (nonatomic) CLLocationCoordinate2D                              destinationCoordinate;

@property (nonatomic, strong) MAPointAnnotation                         * startAnnotation;
@property (nonatomic, strong) MAPointAnnotation                         * destinationAnnotation;

@property (nonatomic, strong) NSMutableArray *tempTraceLocations;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    /** 定位坐标 */
//    self.locations = [NSMutableArray array];
    self.tempTraceLocations = [NSMutableArray array];

    self.latitudes = @[@"22.6164686",@"22.6204230"];
    self.longitudes = @[@"114.0396880",@"114.0358410"];

    [self initMapView];
    [self DrawLine];

    [self queryTraceWithLocations:self.tempTraceLocations withSaving:NO];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/** 初始化地图 */
- (void) initMapView{
    ///初始化地图
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_SIZE.width, SCREEN_SIZE.height)];
    
    _mapView.delegate = self;
    
    ///缩放级别
    _mapView.zoomLevel = 15;
    
    ///是否支持旋转
    _mapView.rotateEnabled = NO;
    
    ///是否支持camera旋转
    _mapView.rotateCameraEnabled = NO;
    
    ///是否显示罗盘
    _mapView.showsCompass = NO;
    
    ///是否显示比例尺
    _mapView.showsScale = NO;
    
    ///如果您需要进入地图就显示定位小蓝点，则需要下面两行代码
    _mapView.showsUserLocation = NO;  //YES 为打开定位，NO为关闭定位
//    _mapView.userTrackingMode = MAUserTrackingModeFollow;
    
    ///把地图添加至view
    [self.view addSubview:_mapView];
    
    self.traceManager = [[MATraceManager alloc] init];
    
}

- (void) DrawLine{
    
    CLLocationCoordinate2D coordinate;
    CLLocation *location;
    NSMutableArray * array = [NSMutableArray array];
    for (int i = 0; i < self.latitudes.count; i++) {
        
        coordinate.latitude = [self.latitudes[i] floatValue];
        coordinate.longitude = [self.longitudes[i] floatValue];
        
        location = [[CLLocation alloc]initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        
        [self.tempTraceLocations addObject:location];
        
        
        [array addObject:location];
    }
    
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[MAPolyline class]])
    {
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        
        polylineRenderer.lineWidth    = 4.0f;
        polylineRenderer.strokeColor  = [UIColor orangeColor];
        polylineRenderer.lineJoinType = kMALineJoinRound;
        polylineRenderer.lineCapType  = kMALineCapRound;
        
        return polylineRenderer;
    }
    
    return nil;
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    
    if ([annotation isKindOfClass:[MAPointAnnotation class]]){
        static NSString *pointReuseIndetifier = @"driverReuseIndetifier";
        
        MAAnnotationView *annotationView = (MAAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
        
        if (annotationView == nil){
            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:pointReuseIndetifier];
        }
        if (![annotation isKindOfClass:[MANaviAnnotation class]])
        {
            /* 起点. */
            if ([[annotation title] isEqualToString:(NSString*)RoutePlanningViewControllerStartTitle])
            {
                annotationView.image = [UIImage imageNamed:@"起点icon"];
                //设置中心点偏移，使得标注底部中间点成为经纬度对应点
                annotationView.centerOffset = CGPointMake(0, -(CURRENT_SIZE(24)/2));
                
            }
            /* 终点. */
            else if([[annotation title] isEqualToString:(NSString*)RoutePlanningViewControllerDestinationTitle])
            {
                annotationView.image = [UIImage imageNamed:@"终点icon"];
                //设置中心点偏移，使得标注底部中间点成为经纬度对应点
                annotationView.centerOffset = CGPointMake(0, -(CURRENT_SIZE(24)/2));
                
            }
        }
        return annotationView;
    }
    
    
    return nil;
}

#pragma mark -------------------- 轨迹纠偏 --------------------
- (void)queryTraceWithLocations:(NSArray<CLLocation *> *)locations withSaving:(BOOL)saving
{
    NSMutableArray *mArr = [NSMutableArray array];
    for(CLLocation *loc in locations)
    {
        MATraceLocation *tLoc = [[MATraceLocation alloc] init];
        tLoc.loc = loc.coordinate;
        
        tLoc.speed = loc.speed * 3.6; //m/s  转 km/h
        tLoc.time = [loc.timestamp timeIntervalSince1970] * 1000;
        tLoc.angle = loc.course;
        [mArr addObject:tLoc];
    }
    
    __weak typeof(self) weakSelf = self;
    __unused NSOperation *op = [self.traceManager queryProcessedTraceWith:mArr type:-1 processingCallback:nil  finishCallback:^(NSArray<MATracePoint *> *points, double distance) {
        
        NSLog(@"trace query done!");
        [weakSelf addFullTrace:points];
        
        
    } failedCallback:^(int errorCode, NSString *errorDesc) {
        
        NSLog(@"Error: %@", errorDesc);
        //        weakSelf.queryOperation = nil;
    }];
    
}

- (void)addFullTrace:(NSArray<MATracePoint*> *)tracePoints
{
    MAPolyline *polyline = [self makePolylineWith:tracePoints];
    if(!polyline)
    {
        return;
    }
    
    [_mapView setVisibleMapRect:[polyline boundingMapRect]];
    [_mapView addOverlay:polyline];
    [self addDefaultAnnotations];
}

- (MAPolyline *)makePolylineWith:(NSArray<MATracePoint*> *)tracePoints
{
    if(tracePoints.count < 2)
    {
        return nil;
    }
    
    CLLocationCoordinate2D *pCoords = malloc(sizeof(CLLocationCoordinate2D) * tracePoints.count);
    if(!pCoords) {
        return nil;
    }
    
    for(int i = 0; i < tracePoints.count; ++i) {
        MATracePoint *p = [tracePoints objectAtIndex:i];
        CLLocationCoordinate2D *pCur = pCoords + i;
        pCur->latitude = p.latitude;
        pCur->longitude = p.longitude;
        
        if(i==0){
            self.startCoordinate = *(pCur);
        }
        if(i == tracePoints.count-1){
            self.destinationCoordinate = *(pCur);
        }
    }
    
    MAPolyline *polyline = [MAPolyline polylineWithCoordinates:pCoords count:tracePoints.count];
    
    if(pCoords)
    {
        free(pCoords);
    }
    
    return polyline;
}

- (void) addDefaultAnnotations
{
    MAPointAnnotation *startAnnotation = [[MAPointAnnotation alloc] init];
    startAnnotation.coordinate = self.startCoordinate;
    startAnnotation.title      = (NSString*)RoutePlanningViewControllerStartTitle;
    startAnnotation.subtitle   = [NSString stringWithFormat:@"{%f, %f}", self.startCoordinate.latitude, self.startCoordinate.longitude];
    self.startAnnotation = startAnnotation;
    
    MAPointAnnotation *destinationAnnotation = [[MAPointAnnotation alloc] init];
    destinationAnnotation.coordinate = self.destinationCoordinate;
    destinationAnnotation.title      = (NSString*)RoutePlanningViewControllerDestinationTitle;
    destinationAnnotation.subtitle   = [NSString stringWithFormat:@"{%f, %f}", self.destinationCoordinate.latitude, self.destinationCoordinate.longitude];
    self.destinationAnnotation = destinationAnnotation;
    
    [_mapView addAnnotation:startAnnotation];
    [_mapView addAnnotation:destinationAnnotation];
}

@end
