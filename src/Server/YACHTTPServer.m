//
//  YACHTTPServer.m
//
//  Copyright (c) 2013 Alexey Dodonov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "YACHTTPServer.h"
#import "RoutingHTTPServer.h"
#import "GRMustache.h"

@interface YACHTTPServer ()
@property (strong) RoutingHTTPServer *server;
@property (strong) NSArray *connectionLogs;
@end

@implementation YACHTTPServer

- (id)init
{
    self = [super init];
    if (self) {
        _server = [[RoutingHTTPServer alloc] init];
        _connectionLogs = [NSMutableArray array];
    }
    return self;
}

- (void)start
{
    [self setupRoutes];
	[self.server setPort:8088];

	NSError *error;
	if (![self.server start:&error]) {
		NSLog(@"Error starting HTTP server: %@", error);
	}
}

- (void)setupRoutes
{
	[self.server get:@"/" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:[self HTMLWithConnectionLogs]];
	}];
	[self.server get:@"/request-body/:UUID" withBlock:^(RouteRequest *request, RouteResponse *response) {
        YACConnectionLog *log = [self connectionLogWithUUID:[request param:@"UUID"]];
        if ([log.request valueForHTTPHeaderField:@"Content-Type"] != nil) {
            [response setHeader:@"Content-Type" value:[log.request valueForHTTPHeaderField:@"Content-Type"]];
        }
        [response respondWithData:[log.request HTTPBody]];
	}];
	[self.server get:@"/response-body/:UUID" withBlock:^(RouteRequest *request, RouteResponse *response) {
        YACConnectionLog *log = [self connectionLogWithUUID:[request param:@"UUID"]];
        [response setHeader:@"Content-Type" value:[log.response MIMEType]];
        [response respondWithData:[log responseBody]];
	}];
	[self.server get:@"/order-by-size" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:[self HTMLWithConnectionLogsOrderedByResponseBodySize]];
	}];
}

- (void)addConnectionLog:(YACConnectionLog *)connectionLog
{
    self.connectionLogs = [self.connectionLogs arrayByAddingObject:connectionLog];
}

#pragma mark - Response

- (NSString *)HTMLWithConnectionLogs
{
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromResource:@"connectionLogs"
                                                                     bundle:nil
                                                                      error:NULL];
    NSString *rendering = [template renderObject:self error:NULL];
    return rendering;
}

- (NSString *)HTMLWithConnectionLogsOrderedByResponseBodySize
{
    GRMustacheTemplate *template = [GRMustacheTemplate templateFromResource:@"connectionLogs"
                                                                     bundle:nil
                                                                      error:NULL];
    NSMutableArray *logs = [NSMutableArray arrayWithArray:self.connectionLogs];
    [logs sortUsingComparator:^NSComparisonResult(YACConnectionLog *log1, YACConnectionLog *log2) {
        return [@([log2.responseBody length]) compare:@([log1.responseBody length])];
    }];

    NSString *rendering = [template renderObject:@{@"connectionLogs": logs} error:NULL];
    return rendering;
}

- (YACConnectionLog *)connectionLogWithUUID:(NSString *)UUID
{
    NSArray *logs = self.connectionLogs;
    NSUInteger index = [logs indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        *stop = [UUID isEqualToString:[obj UUID]];
        return *stop;
    }];

    YACConnectionLog *result = nil;
    if (index != NSNotFound) {
        result = [logs objectAtIndex:index];
    }
    return result;
}

#pragma mark - Singleton

+ (YACHTTPServer *)sharedServer
{
    static YACHTTPServer *sharedServer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedServer = [[YACHTTPServer alloc] init];
        [sharedServer start];
    });
    return sharedServer;
}

@end
